const express = require('express');
const authMiddleware = require('../middlewares/auth.middleware');
const validateBody = require('../middlewares/validate.middleware');
const {
  createTransactionSchema,
  createTransaction,
  getDashboardSummary,
} = require('../controllers/transaction.controller');

const router = express.Router();

router.use(authMiddleware);

/**
 * @openapi
 * /api/transactions/dashboard/summary:
 *   get:
 *     tags: [Transactions]
 *     summary: Dashboard summary
 *     description: Totals for active clients — receivables (balance &gt; 0) and payables (balance &lt; 0, absolute sum).
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200:
 *         description: Summary totals
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     totalReceivable:
 *                       type: number
 *                     totalPayable:
 *                       type: number
 *       401:
 *         description: Unauthorized
 */
router.get('/dashboard/summary', getDashboardSummary);

/**
 * @openapi
 * /api/transactions:
 *   post:
 *     tags: [Transactions]
 *     summary: Create transaction
 *     description: Atomically updates client balance and records a debt or payment.
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [clientId, type, amount]
 *             properties:
 *               clientId:
 *                 type: string
 *               type:
 *                 type: string
 *                 enum: [debt, payment]
 *               amount:
 *                 type: number
 *                 minimum: 0.01
 *               description:
 *                 type: string
 *     responses:
 *       201:
 *         description: Transaction created
 *       400:
 *         description: Validation or business error
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Client not found
 */
router.post('/', validateBody(createTransactionSchema), createTransaction);

module.exports = router;
