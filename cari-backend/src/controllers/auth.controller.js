const jwt = require('jsonwebtoken');
const { z } = require('zod');
const User = require('../models/User.model');

const strongPassword = z
  .string()
  .min(8, 'Password must be at least 8 characters')
  .regex(/[A-Z]/, 'Password must contain an uppercase letter')
  .regex(/[a-z]/, 'Password must contain a lowercase letter')
  .regex(/\d/, 'Password must contain a digit')
  .regex(/[^A-Za-z0-9]/, 'Password must contain a special character');

const registerSchema = z.object({
  email: z.string().email().transform((value) => value.toLowerCase().trim()),
  password: strongPassword,
});

const loginSchema = z.object({
  email: z.string().email().transform((value) => value.toLowerCase().trim()),
  password: z.string().min(1),
});

/**
 * @type {import('express').RequestHandler}
 */
async function register(req, res, next) {
  try {
    const { email, password } = req.body;

    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(409).json({
        success: false,
        message: 'Email already registered',
      });
    }

    await User.create({ email, password });

    return res.status(201).json({
      success: true,
      message: 'User registered successfully',
    });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({
        success: false,
        message: 'Email already registered',
      });
    }
    return next(err);
  }
}

/**
 * @type {import('express').RequestHandler}
 */
async function login(req, res, next) {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user || !(await user.matchPassword(password))) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    const accessSecret = process.env.JWT_SECRET;
    const refreshSecret = process.env.JWT_REFRESH_SECRET;

    if (!accessSecret || !refreshSecret) {
      return next(new Error('JWT secrets are not configured'));
    }

    const userId = user._id.toString();

    const accessToken = jwt.sign({ userId }, accessSecret, { expiresIn: '1h' });
    const refreshToken = jwt.sign({ userId }, refreshSecret, {
      expiresIn: '7d',
    });

    return res.json({
      success: true,
      accessToken,
      refreshToken,
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * @type {import('express').RequestHandler}
 */
async function refresh(req, res) {
  try {
    const refreshToken = req.body?.refreshToken;

    if (!refreshToken || typeof refreshToken !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'refreshToken is required',
      });
    }

    const refreshSecret = process.env.JWT_REFRESH_SECRET;
    const accessSecret = process.env.JWT_SECRET;

    if (!refreshSecret || !accessSecret) {
      return res.status(500).json({
        success: false,
        message: 'Server configuration error',
      });
    }

    const payload = jwt.verify(refreshToken, refreshSecret);
    const userId = payload.userId;

    if (!userId || typeof userId !== 'string') {
      return res.status(401).json({
        success: false,
        message: 'Invalid refresh token',
      });
    }

    const accessToken = jwt.sign({ userId }, accessSecret, { expiresIn: '1h' });

    return res.json({
      success: true,
      accessToken,
    });
  } catch {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired refresh token',
    });
  }
}

module.exports = {
  registerSchema,
  loginSchema,
  register,
  login,
  refresh,
};
