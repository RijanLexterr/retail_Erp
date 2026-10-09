import { httpError } from '../utils/httpError.js'

const QUANTITY_SCALE = 10_000n
const MAX_DECIMAL_14_4 = 99_999_999_999_999n

function toQuantityUnits(value, { allowZero = false } = {}) {
  const text = String(value)
  const match = /^(\d{1,10})(?:\.(\d{1,4}))?$/.exec(text)
  if (!match) {
    throw httpError(422, 'Receipt quantities must be positive values with at most 4 decimal places')
  }

  const fraction = (match[2] ?? '').padEnd(4, '0')
  const units = BigInt(match[1]) * QUANTITY_SCALE + BigInt(fraction || '0')
  if ((!allowZero && units <= 0n) || units > MAX_DECIMAL_14_4) {
    throw httpError(422, 'Receipt quantities are outside the supported range')
  }

  return units
}

function fromQuantityUnits(units) {
  const whole = units / QUANTITY_SCALE
  const fraction = String(units % QUANTITY_SCALE).padStart(4, '0')
  return `${whole}.${fraction}`
}

export async function postGoodsReceipt(pool, { receiptId, userId, ipAddress, userAgent }) {
  const connection = await pool.getConnection()
  let transactionStarted = false

  try {
    await connection.beginTransaction()
    transactionStarted = true

    const [receiptRows] = await connection.execute(
      `SELECT id, receipt_number, purchase_order_id, received_date, status
       FROM goods_receipts
       WHERE id = ?
       FOR UPDATE`,
      [receiptId],
    )
    const receipt = receiptRows[0]
    if (!receipt) {
      throw httpError(404, 'Goods receipt not found')
    }
    if (receipt.status !== 'draft') {
      throw httpError(409, 'Only draft goods receipts can be posted')
    }

    const [orderRows] = await connection.execute(
      `SELECT id, warehouse_id, status
       FROM purchase_orders
       WHERE id = ?
       FOR UPDATE`,
      [receipt.purchase_order_id],
    )
    const purchaseOrder = orderRows[0]
    if (!purchaseOrder || !['approved', 'partially_received'].includes(purchaseOrder.status)) {
      throw httpError(409, 'The purchase order must be approved and not fully received')
    }

    const [receiptItems] = await connection.execute(
      `SELECT id, purchase_order_item_id, product_id, quantity_received, unit_cost
       FROM goods_receipt_items
       WHERE goods_receipt_id = ?
       ORDER BY purchase_order_item_id, id
       FOR UPDATE`,
      [receipt.id],
    )
    if (receiptItems.length === 0) {
      throw httpError(422, 'A goods receipt must contain at least one item')
    }

    const [orderItems] = await connection.execute(
      `SELECT id, product_id, quantity_ordered, quantity_received
       FROM purchase_order_items
       WHERE purchase_order_id = ?
       ORDER BY id
       FOR UPDATE`,
      [purchaseOrder.id],
    )
    const orderItemsById = new Map(orderItems.map((item) => [String(item.id), item]))
    const totalsByOrderItem = new Map()
    const costsByReceiptItem = new Map()

    for (const item of receiptItems) {
      const orderItem = orderItemsById.get(String(item.purchase_order_item_id))
      if (!orderItem || String(orderItem.product_id) !== String(item.product_id)) {
        throw httpError(422, 'A receipt item does not match an item on its purchase order')
      }

      const quantity = toQuantityUnits(item.quantity_received)
      const unitCost = toQuantityUnits(item.unit_cost, { allowZero: true })
      const total = (totalsByOrderItem.get(String(orderItem.id)) ?? 0n) + quantity
      const ordered = toQuantityUnits(orderItem.quantity_ordered)
      const received = toQuantityUnits(orderItem.quantity_received, { allowZero: true })
      if (received + total > ordered) {
        throw httpError(409, `Receipt quantity exceeds the remaining quantity for purchase order item ${orderItem.id}`)
      }

      totalsByOrderItem.set(String(orderItem.id), total)
      costsByReceiptItem.set(String(item.id), fromQuantityUnits(unitCost))
    }

    for (const item of receiptItems) {
      const quantity = fromQuantityUnits(toQuantityUnits(item.quantity_received))
      await connection.execute(
        `INSERT INTO inventory_balances
           (product_id, warehouse_id, quantity_on_hand, quantity_reserved)
         VALUES (?, ?, ?, 0)
         AS incoming
         ON DUPLICATE KEY UPDATE
           quantity_on_hand = quantity_on_hand + incoming.quantity_on_hand`,
        [item.product_id, purchaseOrder.warehouse_id, quantity],
      )

      await connection.execute(
        `INSERT INTO stock_movements
           (product_id, warehouse_id, movement_type, quantity_change, unit_cost,
            reference_type, reference_id, movement_date, notes, created_by)
         VALUES (?, ?, 'purchase_receipt', ?, ?, 'goods_receipt', ?, ?, ?, ?)`,
        [
          item.product_id,
          purchaseOrder.warehouse_id,
          quantity,
          costsByReceiptItem.get(String(item.id)),
          receipt.id,
          receipt.received_date,
          `Receipt ${receipt.receipt_number}`,
          userId,
        ],
      )
    }

    for (const [purchaseOrderItemId, quantityUnits] of totalsByOrderItem) {
      await connection.execute(
        `UPDATE purchase_order_items
         SET quantity_received = quantity_received + ?
         WHERE id = ?`,
        [fromQuantityUnits(quantityUnits), purchaseOrderItemId],
      )
    }

    const [completionRows] = await connection.execute(
      `SELECT COUNT(*) AS line_count,
              SUM(quantity_received >= quantity_ordered) AS completed_count
       FROM purchase_order_items
       WHERE purchase_order_id = ?`,
      [purchaseOrder.id],
    )
    const { line_count: lineCount, completed_count: completedCount } = completionRows[0]
    const nextOrderStatus = Number(lineCount) > 0 && Number(completedCount) === Number(lineCount)
      ? 'received'
      : 'partially_received'

    await connection.execute(
      'UPDATE purchase_orders SET status = ? WHERE id = ?',
      [nextOrderStatus, purchaseOrder.id],
    )
    await connection.execute(
      `UPDATE goods_receipts
       SET status = 'posted'
       WHERE id = ?`,
      [receipt.id],
    )
    await connection.execute(
      `INSERT INTO audit_logs
         (user_id, action, entity_type, entity_id, new_values, ip_address, user_agent)
       VALUES (?, 'goods_receipt.posted', 'goods_receipts', ?, ?, ?, ?)`,
      [
        userId,
        receipt.id,
        JSON.stringify({
          receipt_number: receipt.receipt_number,
          purchase_order_id: purchaseOrder.id,
          purchase_order_status: nextOrderStatus,
        }),
        ipAddress ?? null,
        userAgent ?? null,
      ],
    )

    await connection.commit()
    return {
      id: receipt.id,
      receiptNumber: receipt.receipt_number,
      purchaseOrderId: purchaseOrder.id,
      purchaseOrderStatus: nextOrderStatus,
      status: 'posted',
    }
  } catch (error) {
    if (transactionStarted) {
      try {
        await connection.rollback()
      } catch (rollbackError) {
        console.error('Failed to roll back goods receipt transaction', rollbackError)
      }
    }
    throw error
  } finally {
    connection.release()
  }
}
