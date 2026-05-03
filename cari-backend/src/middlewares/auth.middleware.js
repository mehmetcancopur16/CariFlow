const jwt = require('jsonwebtoken');

/**
 * Verifies `Authorization: Bearer <accessToken>` and sets `req.user.userId`.
 * @type {import('express').RequestHandler}
 */
function authMiddleware(req, res, next) {
  const header = req.headers.authorization;

  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized',
    });
  }

  const token = header.slice('Bearer '.length).trim();

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized',
    });
  }

  try {
    const secret = process.env.JWT_SECRET;
    if (!secret) {
      return res.status(500).json({
        success: false,
        message: 'Server configuration error',
      });
    }

    const payload = jwt.verify(token, secret);
    const userId = payload.userId;

    if (!userId || typeof userId !== 'string') {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized',
      });
    }

    req.user = { userId };
    return next();
  } catch {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized',
    });
  }
}

module.exports = authMiddleware;
