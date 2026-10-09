export function requirePermission(pool, permissionCode) {
  return async function permissionMiddleware(req, res, next) {
    if (!req.user?.id) {
      return res.status(401).json({ error: 'Authentication required' })
    }

    try {
      const [rows] = await pool.execute(
        `SELECT 1
         FROM users u
         JOIN user_roles ur ON ur.user_id = u.id
         JOIN role_permissions rp ON rp.role_id = ur.role_id
         JOIN permissions p ON p.id = rp.permission_id
         WHERE u.id = ?
           AND u.status = 'active'
           AND p.permission_code = ?
         LIMIT 1`,
        [req.user.id, permissionCode],
      )

      if (rows.length === 0) {
        return res.status(403).json({ error: 'Forbidden: permission required' })
      }

      return next()
    } catch (error) {
      return next(error)
    }
  }
}
