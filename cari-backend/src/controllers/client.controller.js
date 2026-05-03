const mongoose = require('mongoose');
const { z } = require('zod');
const Client = require('../models/Client.model');
const Transaction = require('../models/Transaction.model');

const createClientSchema = z.object({
  name: z.string().min(1),
  phone: z.string().optional(),
  email: z.string().optional(),
  address: z.string().optional(),
  notes: z.string().optional(),
});

const updateClientSchema = z
  .object({
    name: z.string().min(1).optional(),
    phone: z.string().optional(),
    email: z.string().optional(),
    address: z.string().optional(),
    notes: z.string().optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'At least one field is required',
  });

/**
 * @type {import('express').RequestHandler}
 */
async function createClient(req, res, next) {
  try {
    const client = await Client.create({
      ...req.body,
      owner: req.user.userId,
    });

    return res.status(201).json({
      success: true,
      data: client,
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * @type {import('express').RequestHandler}
 */
async function getClients(req, res, next) {
  try {
    const page = Math.max(1, parseInt(String(req.query.page || '1'), 10) || 1);
    const limit = Math.min(
      100,
      Math.max(1, parseInt(String(req.query.limit || '20'), 10) || 20)
    );
    const search = req.query.search
      ? String(req.query.search).trim()
      : '';

    const filter = {
      owner: req.user.userId,
      isActive: true,
    };

    if (search) {
      const escaped = search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      filter.$or = [
        { name: new RegExp(escaped, 'i') },
        { phone: new RegExp(escaped, 'i') },
      ];
    }

    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      Client.find(filter).sort({ name: 1 }).skip(skip).limit(limit).lean(),
      Client.countDocuments(filter),
    ]);

    return res.json({
      success: true,
      data: items,
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit) || 0,
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * @type {import('express').RequestHandler}
 */
async function getClientById(req, res, next) {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid client id',
      });
    }

    const client = await Client.findOne({
      _id: id,
      owner: req.user.userId,
    }).lean();

    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Client not found',
      });
    }

    return res.json({
      success: true,
      data: client,
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * @type {import('express').RequestHandler}
 */
async function updateClient(req, res, next) {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid client id',
      });
    }

    const client = await Client.findOneAndUpdate(
      { _id: id, owner: req.user.userId },
      req.body,
      { new: true, runValidators: true }
    ).lean();

    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Client not found',
      });
    }

    return res.json({
      success: true,
      data: client,
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * @type {import('express').RequestHandler}
 */
async function deleteClient(req, res, next) {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid client id',
      });
    }

    const client = await Client.findOneAndUpdate(
      { _id: id, owner: req.user.userId },
      { isActive: false },
      { new: true }
    ).lean();

    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Client not found',
      });
    }

    return res.json({
      success: true,
      message: 'Client deactivated',
      data: client,
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * @type {import('express').RequestHandler}
 */
async function getClientTransactions(req, res, next) {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid client id',
      });
    }

    const client = await Client.findOne({
      _id: id,
      owner: req.user.userId,
    }).select('_id');

    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Client not found',
      });
    }

    const transactions = await Transaction.find({
      client: client._id,
      owner: req.user.userId,
    })
      .sort({ date: -1 })
      .lean();

    return res.json({
      success: true,
      data: transactions,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  createClientSchema,
  updateClientSchema,
  createClient,
  getClients,
  getClientById,
  updateClient,
  deleteClient,
  getClientTransactions,
};
