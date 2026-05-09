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

/**
 * Deterministic scenarios aligned with app semantics:
 * - debt: increases client currentBalance (receivable from them)
 * - payment: decreases currentBalance
 */
function buildScenario(serial, variant) {
  const bump = (serial % 7) * 25;

  switch (variant % 5) {
    case 0: // Strong receivable
      return [
        { type: 'debt', amount: 8000 + bump, description: 'Toplu mal siparisi', daysAgo: 60 },
        { type: 'payment', amount: 2000 + bump, description: 'Kapora', daysAgo: 52 },
        { type: 'debt', amount: 3200 + bump, description: 'Ek sevkiyat', daysAgo: 40 },
        { type: 'payment', amount: 1500 + bump, description: 'EFT tahsilat', daysAgo: 28 },
        { type: 'debt', amount: 900 + bump, description: 'Hizmet faturasi', daysAgo: 12 },
      ];
    case 1: // Payable (negative balance — overpayment / credit balance)
      return [
        { type: 'debt', amount: 2000 + bump, description: 'Acilis bakiyesi', daysAgo: 45 },
        { type: 'payment', amount: 4500 + bump, description: 'Fazla odeme (iade bekleniyor)', daysAgo: 30 },
        { type: 'debt', amount: 800 + bump, description: 'Duzeltme faturasi', daysAgo: 14 },
        { type: 'payment', amount: 500 + bump, description: 'Kismi mahsup', daysAgo: 5 },
      ];
    case 2: // Near zero
      return [
        { type: 'debt', amount: 5000 + bump, description: 'Satis faturasi', daysAgo: 20 },
        { type: 'payment', amount: 4800 + bump, description: 'Neredeyse tam odeme', daysAgo: 10 },
        { type: 'debt', amount: 300 + bump, description: 'Yuvarlama / ek masraf', daysAgo: 3 },
        { type: 'payment', amount: 500 + bump, description: 'Kapanis odemesi', daysAgo: 1 },
      ];
    case 3: // Single large debt, one partial payment
      return [
        { type: 'debt', amount: 15000 + bump, description: 'Proje bazli satis', daysAgo: 18 },
        { type: 'payment', amount: 4000 + bump, description: 'Donemsel odeme', daysAgo: 9 },
      ];
    default: // Mixed timeline (default rich history)
      return [
        { type: 'debt', amount: 1200 + bump, description: 'Vadeli satis', daysAgo: 35 },
        { type: 'payment', amount: 450 + bump, description: 'Kismi odeme', daysAgo: 24 },
        { type: 'debt', amount: 700 + bump, description: 'Ek siparis', daysAgo: 16 },
        { type: 'payment', amount: 500 + bump, description: 'Banka transferi', daysAgo: 8 },
        { type: 'debt', amount: 300 + bump, description: 'Hizmet bedeli', daysAgo: 3 },
        ...(serial % 3 === 0
          ? [
              {
                type: 'payment',
                amount: 1400 + bump,
                description: 'Toplu odeme',
                daysAgo: 1,
              },
            ]
          : []),
      ];
  }
}

const DEMO_USERS = [
  {
    email: 'demo1@cariflow.local',
    password: 'Demo12345!',
    company: {
      companyName: 'CariFlow Demo Ticaret A.S.',
      taxOffice: 'Kadikoy',
      taxId: '1234567890',
      companyPhone: '+90 216 555 0101',
      companyAddress: 'Istanbul, Turkiye — Genel mudurluk',
    },
  },
  {
    email: 'demo2@cariflow.local',
    password: 'Demo12345!',
    company: {
      companyName: 'Marmara Perakende Ltd. Sti.',
      taxOffice: 'Besiktas',
      taxId: '0987654321',
      companyPhone: '+90 212 555 0202',
      companyAddress: 'Istanbul, Sisli — Merkez sube',
    },
  },
  {
    email: 'demo3@cariflow.local',
    password: 'Demo12345!',
    company: {
      companyName: 'Ege Lojistik ve Dis Ticaret',
      taxOffice: 'Konak',
      taxId: '5555666677',
      companyPhone: '+90 232 555 0303',
      companyAddress: 'Izmir, Konak — Liman ofisi',
    },
  },
];

const CLIENT_NAMES = [
  'Yilmaz Gida Sanayi',
  'Ege Mobilya Ltd. Sti.',
  'Bosphorus Tekstil',
  'Anadolu Insaat Malzemeleri',
  'Marmara Lojistik',
  'Kapadokya Turizm',
  'Izmir Elektronik',
  'Karadeniz Balikcilik',
  'Antalya Oteller Grubu',
  'Trakya Tarim Urunleri',
];

async function ensureDemoUser(row) {
  let user = await User.findOne({ email: row.email });
  if (!user) {
    user = await User.create({
      email: row.email,
      password: row.password,
      ...row.company,
    });
    return { user, created: true };
  }

  await User.updateOne(
    { _id: user._id },
    {
      $set: {
        companyName: row.company.companyName,
        taxOffice: row.company.taxOffice,
        taxId: row.company.taxId,
        companyPhone: row.company.companyPhone,
        companyAddress: row.company.companyAddress,
      },
    }
  );
  user = await User.findById(user._id);
  return { user, created: false };
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
    console.log('Existing User, Client, Transaction collections cleared');
  }

  const users = [];
  for (const row of DEMO_USERS) {
    const { user, created } = await ensureDemoUser(row);
    users.push(user);
    console.log(
      `${created ? 'Created user' : 'Updated profile for'} ${user.email}`
    );
  }

  const clientsPerUser = 10;
  let createdClientCount = 0;
  let skippedExisting = 0;

  for (let userIndex = 0; userIndex < users.length; userIndex += 1) {
    const owner = users[userIndex];
    for (let i = 0; i < clientsPerUser; i += 1) {
      const serial = userIndex * clientsPerUser + i + 1;
      const nameBase = CLIENT_NAMES[i % CLIENT_NAMES.length];
      const name = `${nameBase} #${serial}`;

      const existingClient = await Client.findOne({ owner: owner._id, name });
      if (existingClient) {
        skippedExisting += 1;
        continue;
      }

      const isActive = serial % 11 !== 0;
      const client = await Client.create({
        owner: owner._id,
        name,
        phone: (() => {
          const n = String(1_000_000 + serial * 1_039).slice(-7);
          return `+90 555 ${n.slice(0, 3)} ${n.slice(3, 5)} ${n.slice(5, 7)}`;
        })(),
        email: `cari${serial}@seed.cariflow.local`,
        address: `${['Istanbul', 'Ankara', 'Izmir', 'Bursa', 'Antalya'][serial % 5]} — Bolge ${(serial % 8) + 1}`,
        notes:
          serial % 7 === 0
            ? 'Haftalik mutabakat onerilir.'
            : serial % 5 === 0
              ? 'Riskli: vade takibi siki'
              : 'Duzenli odeme profili',
        isActive,
      });

      if (client.isActive) {
        const scenario = buildScenario(serial, serial % 5);
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
  const activeClients = await Client.countDocuments({ isActive: true });

  console.log('Seed completed');
  console.log(
    JSON.stringify(
      {
        users: totalUsers,
        clients: totalClients,
        activeClients,
        transactions: totalTransactions,
        newlyCreatedClients: createdClientCount,
        skippedExistingClients: skippedExisting,
        demoLogins: DEMO_USERS.map((u) => u.email),
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
