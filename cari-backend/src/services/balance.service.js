const mongoose = require('mongoose');
const Client = require('../models/Client.model');
const Transaction = require('../models/Transaction.model');

/**
 * Atomically updates client balance and persists a transaction record.
 * @param {import('mongoose').Types.ObjectId | string} clientId
 * @param {import('mongoose').Types.ObjectId | string} ownerId
 * @param {'debt' | 'payment'} type
 * @param {number} amount
 * @param {string} [description]
 */
async function processTransaction(clientId, ownerId, type, amount, description) {
  const session = await mongoose.startSession();

  try {
    const created = await session.withTransaction(async () => {
      const client = await Client.findOne({
        _id: clientId,
        owner: ownerId,
      }).session(session);

      if (!client) {
        throw new Error('Client not found');
      }

      const balanceBefore = client.currentBalance;

      // Domain rule:
      // - debt: client owes us more -> receivable increases
      // - payment: client pays us -> receivable decreases
      if (type === 'debt') {
        client.currentBalance += amount;
      } else if (type === 'payment') {
        client.currentBalance -= amount;
      } else {
        throw new Error('Invalid transaction type');
      }

      const balanceAfter = client.currentBalance;

      const [tx] = await Transaction.create(
        [
          {
            client: clientId,
            owner: ownerId,
            type,
            amount,
            description,
            balanceBefore,
            balanceAfter,
          },
        ],
        { session }
      );

      await client.save({ session });

      return tx;
    });

    return created;
  } finally {
    await session.endSession();
  }
}

/**
 * Reverses a transaction on the client balance and removes the record.
 * @param {string} transactionId
 * @param {string} ownerId
 */
async function deleteTransactionById(transactionId, ownerId) {
  const session = await mongoose.startSession();

  try {
    let removed;
    await session.withTransaction(async () => {
      const tx = await Transaction.findOne({
        _id: transactionId,
        owner: ownerId,
      }).session(session);

      if (!tx) {
        throw new Error('TRANSACTION_NOT_FOUND');
      }

      const client = await Client.findOne({
        _id: tx.client,
        owner: ownerId,
      }).session(session);

      if (!client) {
        throw new Error('CLIENT_NOT_FOUND');
      }

      if (tx.type === 'debt') {
        client.currentBalance -= tx.amount;
      } else if (tx.type === 'payment') {
        client.currentBalance += tx.amount;
      }

      await client.save({ session });
      await Transaction.deleteOne({ _id: tx._id }).session(session);
      removed = tx;
    });

    return removed;
  } finally {
    await session.endSession();
  }
}

/**
 * Reverses the existing movement and applies new type/amount (same client).
 * @param {string} transactionId
 * @param {string} ownerId
 * @param {{ type: 'debt' | 'payment', amount: number, description?: string }} next
 */
async function updateTransactionById(transactionId, ownerId, next) {
  const session = await mongoose.startSession();
  const { type, amount, description } = next;

  try {
    let updated;
    await session.withTransaction(async () => {
      const tx = await Transaction.findOne({
        _id: transactionId,
        owner: ownerId,
      }).session(session);

      if (!tx) {
        throw new Error('TRANSACTION_NOT_FOUND');
      }

      const client = await Client.findOne({
        _id: tx.client,
        owner: ownerId,
      }).session(session);

      if (!client) {
        throw new Error('CLIENT_NOT_FOUND');
      }

      if (!client.isActive) {
        throw new Error('CLIENT_INACTIVE');
      }

      if (tx.type === 'debt') {
        client.currentBalance -= tx.amount;
      } else if (tx.type === 'payment') {
        client.currentBalance += tx.amount;
      }

      const balanceBefore = client.currentBalance;

      if (type === 'debt') {
        client.currentBalance += amount;
      } else if (type === 'payment') {
        client.currentBalance -= amount;
      } else {
        throw new Error('Invalid transaction type');
      }

      const balanceAfter = client.currentBalance;

      tx.type = type;
      tx.amount = amount;
      tx.description = description;
      tx.balanceBefore = balanceBefore;
      tx.balanceAfter = balanceAfter;

      await client.save({ session });
      await tx.save({ session });
      updated = tx;
    });

    return updated;
  } finally {
    await session.endSession();
  }
}

module.exports = {
  processTransaction,
  deleteTransactionById,
  updateTransactionById,
};
