import { Router } from 'express'
import { requirePermission } from '../middleware/requirePermission.js'
import { postGoodsReceipt } from '../services/goodsReceipt.service.js'

export function createGoodsReceiptRouter(pool) {
  const router = Router()

  router.post('/:receiptId/post', requirePermission(pool, 'goods_receipts.post'), async (req, res, next) => {
    if (!/^[1-9]\d{0,19}$/.test(req.params.receiptId)) {
      return res.status(400).json({ error: 'Invalid goods receipt id' })
    }

    try {
      const result = await postGoodsReceipt(pool, {
        receiptId: req.params.receiptId,
        userId: req.user.id,
        ipAddress: req.ip,
        userAgent: req.get('user-agent'),
      })
      return res.status(200).json({ data: result })
    } catch (error) {
      return next(error)
    }
  })

  return router
}
