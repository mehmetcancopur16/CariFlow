/**
 * @param {import('zod').ZodType} schema
 * @returns {import('express').RequestHandler}
 */
function validateBody(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: result.error.flatten(),
      });
    }

    req.body = result.data;
    return next();
  };
}

module.exports = validateBody;
