const mongoose = require('mongoose');
const logger = require('../utils/logger');

/**
 * @returns {Promise<void>}
 */
async function connectDB() {
  const uri = process.env.MONGO_URI;

  if (!uri || String(uri).trim() === '') {
    throw new Error('MONGO_URI environment variable is not defined');
  }

  try {
    await mongoose.connect(uri);
    logger.info('MongoDB connection established successfully');
  } catch (err) {
    logger.error(`MongoDB connection failed: ${err.message}`);
    throw err;
  }
}

module.exports = { connectDB };
