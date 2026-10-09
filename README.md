# Retail ERP

Lightweight retail ERP starter using React + Vite + Tailwind CSS on the frontend and Express + `mysql2` on the backend. The MySQL schema is in `sql/retail_erp_schema.sql`.

## Project structure

```text
.
├── backend/
│   ├── .env.example
│   ├── package.json
│   └── src/
│       ├── app.js
│       ├── config/db.js
│       ├── middleware/
│       │   ├── errorHandler.js
│       │   └── requirePermission.js
│       ├── routes/goodsReceipt.routes.js
│       ├── services/goodsReceipt.service.js
│       ├── utils/httpError.js
│       └── server.js
├── sql/retail_erp_schema.sql
└── src/                         # React/Vite frontend
    ├── App.jsx
    └── index.css
```

Keep HTTP concerns in routes, business rules and transactions in services, and database connection setup in `config/db.js`. Use parameterized SQL through `mysql2`; do not concatenate user input into SQL. The dashboard currently uses sample data to demonstrate a Tailwind sidebar, summary cards, and inventory table.

## Run locally

1. Create the MySQL database by running `sql/retail_erp_schema.sql` in a development database. **This starter schema drops and recreates its tables; do not run it against data you need to keep.**
2. Start the frontend from the project root:

   ```sh
   npm install
   npm run dev
   ```

3. Configure and start the API in another terminal:

   ```sh
   cd backend
   npm install
   cp .env.example .env
   # Set MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, and MYSQL_DATABASE in .env.
   npm run dev
   ```

   On Windows PowerShell, use `Copy-Item .env.example .env` instead of `cp`.

Vite proxies `/api` requests to `http://localhost:3000`. Use a dedicated least-privilege MySQL application user in real deployments; do not commit `.env`.

## Goods receipt posting example

`POST /api/goods-receipts/:receiptId/post` posts an existing **draft** receipt. The receipt and its item rows must already have been created. The service locks the receipt, purchase order, and PO items; verifies the PO is approved or partially received and that the receipt does not over-receive; then in one InnoDB transaction:

1. Adds quantities to `inventory_balances` for the PO warehouse.
2. Inserts `purchase_receipt` rows in `stock_movements`.
3. Increments `purchase_order_items.quantity_received` and sets the PO to `partially_received` or `received`.
4. Marks the goods receipt `posted` and writes an `audit_logs` record.

Any failure rolls back all of those changes. Quantities are handled as fixed-scale decimal strings rather than JavaScript floating-point values.

The endpoint requires the `goods_receipts.post` permission. The schema seeds this permission and grants all seeded permissions to the `admin` role. Grant it to another role with:

```sql
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.permission_code = 'goods_receipts.post'
WHERE r.role_name = 'inventory_staff';
```

The authorization middleware expects upstream authentication to set `req.user.id`. `backend/src/server.js` includes a small contract placeholder that returns 401 until a real session/JWT authentication middleware is installed; replace it before using protected endpoints. Permission membership is read from `users`, `user_roles`, `role_permissions`, and `permissions` on each request, so revocations take effect without a cache refresh.

## Styling

Tailwind CSS v4 is the styling system for new UI. It is loaded through `@import "tailwindcss";` in `src/index.css` and `@tailwindcss/vite` in `vite.config.js`. Use utility classes in React components; keep custom CSS for genuinely reusable styles that are awkward to express as utilities.
