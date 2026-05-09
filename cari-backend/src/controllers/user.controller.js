const { z } = require('zod');
const User = require('../models/User.model');

const updateProfileSchema = z.object({
  companyName: z.string().optional(),
  taxOffice: z.string().optional(),
  taxId: z.string().optional(),
  companyPhone: z.string().optional(),
  companyAddress: z.string().optional(),
});

const changePasswordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(6),
});

function toPublicUser(user) {
  if (!user) return null;
  return {
    id: user._id.toString(),
    email: user.email,
    companyName: user.companyName || '',
    taxOffice: user.taxOffice || '',
    taxId: user.taxId || '',
    companyPhone: user.companyPhone || '',
    companyAddress: user.companyAddress || '',
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

/**
 * @type {import('express').RequestHandler}
 */
async function getMe(req, res, next) {
  try {
    const user = await User.findById(req.user.userId).select(
      '-password'
    );
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    return res.json({ success: true, data: toPublicUser(user) });
  } catch (err) {
    return next(err);
  }
}

/**
 * @type {import('express').RequestHandler}
 */
async function updateMe(req, res, next) {
  try {
    const body = req.body || {};
    const allowed = [
      'companyName',
      'taxOffice',
      'taxId',
      'companyPhone',
      'companyAddress',
    ];
    const patch = {};
    for (const key of allowed) {
      if (body[key] !== undefined && body[key] !== null) {
        patch[key] = String(body[key]).trim();
      }
    }
    const user = await User.findByIdAndUpdate(
      req.user.userId,
      { $set: patch },
      { new: true, runValidators: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    return res.json({ success: true, data: toPublicUser(user) });
  } catch (err) {
    return next(err);
  }
}

/**
 * @type {import('express').RequestHandler}
 */
async function changePassword(req, res, next) {
  try {
    const { currentPassword, newPassword } = req.body;
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    const ok = await user.matchPassword(currentPassword);
    if (!ok) {
      return res.status(400).json({
        success: false,
        message: 'Current password is incorrect',
      });
    }
    user.password = newPassword;
    await user.save();
    return res.json({ success: true, message: 'Password updated' });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  updateProfileSchema,
  changePasswordSchema,
  getMe,
  updateMe,
  changePassword,
  toPublicUser,
};
