require('dotenv').config();

const mongoose = require('mongoose');
const User = require('../src/models/User.model');
const Client = require('../src/models/Client.model');
const Transaction = require('../src/models/Transaction.model');

function getDateDaysAgo(daysAgo) {
  return new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);
}

function computeNextBalance(balance, type, amount) {
  if (type === 'debt') return balance + amount;
  if (type === 'payment') return balance - amount;
  throw new Error('Invalid transaction type in seed flow');
}

async function createTransactionsForClient({ ownerId, client, scenario }) {
  let balance = 0;
  const docs = [];

  for (const item of scenario) {
    const balanceBefore = balance;
    const balanceAfter = computeNextBalance(balanceBefore, item.type, item.amount);

    docs.push({
      owner: ownerId,
      client: client._id,
      type: item.type,
      amount: item.amount,
      description: item.description,
      date: getDateDaysAgo(item.daysAgo),
      balanceBefore,
      balanceAfter,
    });

    balance = balanceAfter;
  }

  if (docs.length > 0) {
    await Transaction.insertMany(docs);
  }

  client.currentBalance = balance;
  await client.save();
}

function buildScenario(seed) {
  const base = [
    { type: 'debt', amount: 1200 + seed * 35, description: 'Vadeli satis', daysAgo: 35 - seed },
    { type: 'payment', amount: 450 + seed * 20, description: 'Kismi odeme', daysAgo: 24 - seed },
    { type: 'debt', amount: 700 + seed * 15, description: 'Ek siparis', daysAgo: 16 - seed },
    { type: 'payment', amount: 500 + seed * 10, description: 'Banka transferi', daysAgo: 8 - seed },
    { type: 'debt', amount: 300 + seed * 12, description: 'Hizmet bedeli', daysAgo: 3 - seed },
  ];

  if (seed % 3 === 0) {
    base.push({
      type: 'payment',
      amount: 1400 + seed * 12,
      description: 'Toplu odeme',
      daysAgo: 1,
    });
  }

  return base;
}

async function main() {
  const uri = process.env.MONGO_URI;
  if (!uri) {
    throw new Error('MONGO_URI is required for seeding');
  }

  const shouldReset = process.argv.includes('--reset');

  await mongoose.connect(uri);
  console.log('Connected to MongoDB for seed');

  if (shouldReset) {
    await Promise.all([
      Transaction.deleteMany({}),
      Client.deleteMany({}),
      User.deleteMany({}),
    ]);
    console.log('Existing collections cleared');
  }

  const usersData = [
    { email: 'demo1@cariflow.local', password: 'Demo12345!' },
    { email: 'demo2@cariflow.local', password: 'Demo12345!' },
    { email: 'demo3@cariflow.local', password: 'Demo12345!' },
  ];

  const users = [];
  for (const userData of usersData) {
    const existing = await User.findOne({ email: userData.email });
    if (existing) {
      users.push(existing);
    } else {
      const created = await User.create(userData);
      users.push(created);
    }
  }

  const clientsToCreatePerUser = 8;
  let createdClientCount = 0;

  for (let userIndex = 0; userIndex < users.length; userIndex += 1) {
    const owner = users[userIndex];
    for (let i = 0; i < clientsToCreatePerUser; i += 1) {
      const serial = userIndex * clientsToCreatePerUser + i + 1;
      const name = `Demo Musteri ${serial}`;
      const existingClient = await Client.findOne({ owner: owner._id, name });
      if (existingClient) continue;

      const client = await Client.create({
        owner: owner._id,
        name,
        phone: `+90 555 01${String(serial).padStart(2, '0')}`,
        email: `musteri${serial}@ornek.com`,
        address: `Istanbul - Bolge ${serial}`,
        notes: serial % 5 === 0 ? 'Riskli cari' : 'Duzenli cari',
        isActive: serial % 11 !== 0,
      });

      if (client.isActive) {
        const scenario = buildScenario(serial);
        await createTransactionsForClient({
          ownerId: owner._id,
          client,
          scenario,
        });
      }

      createdClientCount += 1;
    }
  }

  const totalUsers = await User.countDocuments();
  const totalClients = await Client.countDocuments();
  const totalTransactions = await Transaction.countDocuments();

  console.log('Seed completed');
  console.log(
    JSON.stringify(
      {
        users: totalUsers,
        clients: totalClients,
        transactions: totalTransactions,
        newlyCreatedClients: createdClientCount,
      },
      null,
      2
    )
  );
}

main()
  .catch((error) => {
    console.error('Seed failed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.connection.close();
  });
