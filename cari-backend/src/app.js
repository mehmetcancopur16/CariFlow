require('dotenv').config({ quiet: true });

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const hpp = require('hpp');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
const swaggerUi = require('swagger-ui-express');

const { connectDB } = require('./config/db');
const swaggerSpec = require('./config/swagger');
const errorMiddleware = require('./middlewares/error.middleware');
const authRoutes = require('./routes/auth.routes');
const clientRoutes = require('./routes/client.routes');
const transactionRoutes = require('./routes/transaction.routes');
const userRoutes = require('./routes/user.routes');
const logger = require('./utils/logger');

// Fail fast if critical secrets are missing in production.
const isProduction = process.env.NODE_ENV === 'production';
if (!process.env.JWT_SECRET || !process.env.JWT_REFRESH_SECRET) {
  const message = 'JWT_SECRET and JWT_REFRESH_SECRET must be set';
  if (isProduction) {
    logger.error(message);
    process.exit(1);
  } else {
    logger.warn(`${message} (development fallback may be unsafe)`);
  }
}

const app = express();

app.disable('x-powered-by');
app.set('trust proxy', 1);

const corsOrigins = (process.env.CORS_ORIGIN || '*')
  .split(',')
  .map((value) => value.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: corsOrigins.includes('*') ? true : corsOrigins,
    credentials: false,
  })
);
app.use(helmet());

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many requests, please try again later.',
  },
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many authentication attempts, please try again later.',
  },
});

app.use('/api', apiLimiter);
app.use(hpp());
app.use(compression());
app.use(
  morgan(':method :url :status - :response-time ms', {
    stream: {
      write: (message) => logger.info(message.trim()),
    },
    skip: (req) => req.path === '/health',
  })
);
app.use(express.json({ limit: '100kb' }));

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.get('/swagger', (req, res) => res.redirect('/api-docs'));
app.get('/swagger/', (req, res) => res.redirect('/api-docs/'));

app.get('/health', (req, res) => {
  res.json({ status: 'OK' });
});

app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/clients', clientRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/users', userRoutes);

app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Not found' });
});

app.use(errorMiddleware);

const PORT = Number(process.env.PORT) || 3000;

async function start() {
  try {
    await connectDB();
    app.listen(PORT, () => {
      logger.info(`Server running on port ${PORT}`);
    });
  } catch (err) {
    logger.error(`Failed to start server: ${err.message}`);
    process.exit(1);
  }
}

start();

module.exports = app;
