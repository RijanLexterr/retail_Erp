import 'dotenv/config'
import mysql from 'mysql2/promise'

const requiredEnv = ['MYSQL_HOST', 'MYSQL_USER', 'MYSQL_DATABASE']
const missingEnv = requiredEnv.filter((key) => !process.env[key])

if (missingEnv.length > 0) {
  throw new Error(`Missing required database environment variables: ${missingEnv.join(', ')}`)
}

export const pool = mysql.createPool({
  host: process.env.MYSQL_HOST,
  port: Number(process.env.MYSQL_PORT ?? 3306),
  user: process.env.MYSQL_USER,
  password: process.env.MYSQL_PASSWORD ?? '',
  database: process.env.MYSQL_DATABASE,
  waitForConnections: true,
  connectionLimit: Number(process.env.MYSQL_CONNECTION_LIMIT ?? 10),
  queueLimit: 0,
  decimalNumbers: false,
  dateStrings: true,
})
