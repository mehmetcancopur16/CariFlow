const mongoose = require('mongoose');
const { z } = require('zod');
const Client = require('../models/Client.model');
const { processTransaction } = require('../services/balance.service');

const createTransactionSchema = z.object({
  clientId: z
    .string()
    .min(1)
    .refine((id) => mongoose.Types.ObjectId.isValid(id), {
      message: 'Invalid clientId',
    }),
  type: z.enum(['debt', 'payment']),
  amount: z.number().min(0.01),
  description: z.string().optional(),
});

/**
 * @type {import('express').RequestHandler}
 */
async function createTransaction(req, res, next) {
  try {
    const { clientId, type, amount, description } = req.body;

    const client = await Client.findOne({
      _id: clientId,
      owner: req.user.userId,
    }).select('_id isActive');

    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Client not found',
      });
    }

    if (!client.isActive) {
      return res.status(400).json({
        success: false,
        message: 'Cannot post transactions for an inactive client',
      });
    }

    const transaction = await processTransaction(
      clientId,
      req.user.userId,
      type,
      amount,
      description
    );

    return res.status(201).json({
      success: true,
      data: transaction,
    });
  } catch (err) {
    if (err.message === 'Client not found') {
      return res.status(404).json({
        success: false,
        message: 'Client not found',
      });
    }
    return next(err);
  }
}

/**
 * @type {import('express').RequestHandler}
 */
async function getDashboardSummary(req, res, next) {
  try {
    const ownerId = req.user.userId;

    if (!mongoose.Types.ObjectId.isValid(ownerId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user context',
      });
    }

    const [receivableAgg, payableAgg] = await Promise.all([
      Client.aggregate([
        {
          $match: {
            owner: new mongoose.Types.ObjectId(ownerId),
            isActive: true,
            currentBalance: { $gt: 0 },
          },
        },
        { $group: { _id: null, total: { $sum: '$currentBalance' } } },
      ]),
      Client.aggregate([
        {
          $match: {
            owner: new mongoose.Types.ObjectId(ownerId),
            isActive: true,
            currentBalance: { $lt: 0 },
          },
        },
        {
          $group: {
            _id: null,
            total: { $sum: { $abs: '$currentBalance' } },
          },
        },
      ]),
    ]);

    const totalReceivable = receivableAgg[0]?.total ?? 0;
    const totalPayable = payableAgg[0]?.total ?? 0;

    return res.json({
      success: true,
      data: {
        totalReceivable,
        totalPayable,
      },
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  createTransactionSchema,
  createTransaction,
  getDashboardSummary,
};
