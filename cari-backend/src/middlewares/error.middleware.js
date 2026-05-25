const logger = require('../utils/logger');

/**
 * Global error handler — must be registered after all routes.
 * @type {import('express').ErrorRequestHandler}
 */
function errorMiddleware(err, req, res, next) {
  logger.error(err);

  const statusCode =
    err.statusCode && Number.isInteger(err.statusCode) ? err.statusCode : 500;

  const isProduction = process.env.NODE_ENV === 'production';
  const isServerError = statusCode >= 500;
  const safeMessage = err.message || 'Server Error';

  res.status(statusCode).json({
    success: false,
    message: isProduction && isServerError ? 'Server Error' : safeMessage,
  });
}

module.exports = errorMiddleware;
