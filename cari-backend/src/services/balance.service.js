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

module.exports = { processTransaction };
