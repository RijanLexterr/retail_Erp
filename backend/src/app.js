import express from 'express'
import { errorHandler } from './middleware/errorHandler.js'
import { createGoodsReceiptRouter } from './routes/goodsReceipt.routes.js'

export function createApp({ pool, authenticate }) {
  const app = express()

  app.disable('x-powered-by')
  app.use(express.json({ limit: '1mb' }))
  app.get('/api/health', (req, res) => res.json({ status: 'ok' }))

  if (typeof authenticate !== 'function') {
    throw new TypeError('createApp requires an authentication middleware')
  }

  app.use('/api/goods-receipts', authenticate, createGoodsReceiptRouter(pool))
  app.use(errorHandler)
  return app
}
