import { createApp } from './app.js'
import { pool } from './config/db.js'

function requireAuthentication(req, res, next) {
  if (!req.user?.id) {
    return res.status(401).json({ error: 'Authentication middleware must set req.user.id' })
  }

  return next()
}

const port = Number(process.env.PORT ?? 3000)
const app = createApp({ pool, authenticate: requireAuthentication })

app.listen(port, () => {
  console.log(`Retail ERP API listening on port ${port}`)
})
