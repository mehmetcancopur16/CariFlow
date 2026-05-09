const express = require('express');
const authMiddleware = require('../middlewares/auth.middleware');
const validateBody = require('../middlewares/validate.middleware');
const {
  updateProfileSchema,
  changePasswordSchema,
  getMe,
  updateMe,
  changePassword,
} = require('../controllers/user.controller');

const router = express.Router();

router.use(authMiddleware);

router.get('/me', getMe);
router.patch('/me', validateBody(updateProfileSchema), updateMe);
router.post('/change-password', validateBody(changePasswordSchema), changePassword);

module.exports = router;
