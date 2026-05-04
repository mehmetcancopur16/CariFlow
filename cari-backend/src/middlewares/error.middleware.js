const logger = require('../utils/logger');

/**
 * Global error handler — must be registered after all routes.
 * @type {import('express').ErrorRequestHandler}
 */
function errorMiddleware(err, req, res, next) {
  logger.error(err);

  const statusCode =
    err.statusCode && Number.isInteger(err.statusCode) ? err.statusCode : 500;

  res.status(statusCode).json({
    success: false,
    message: err.message || 'Server Error',
  });
}

module.exports = errorMiddleware;
