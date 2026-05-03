const express = require('express');
const authMiddleware = require('../middlewares/auth.middleware');
const validateBody = require('../middlewares/validate.middleware');
const {
  createClientSchema,
  updateClientSchema,
  createClient,
  getClients,
  getClientById,
  updateClient,
  deleteClient,
  getClientTransactions,
} = require('../controllers/client.controller');

const router = express.Router();

router.use(authMiddleware);

/**
 * @openapi
 * /api/clients:
 *   get:
 *     tags: [Clients]
 *     summary: List active clients
 *     description: Returns the authenticated user's active clients with optional search and pagination.
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Filter by name or phone (case-insensitive)
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 20
 *     responses:
 *       200:
 *         description: Paginated client list
 *       401:
 *         description: Unauthorized
 */
router.get('/', getClients);

/**
 * @openapi
 * /api/clients:
 *   post:
 *     tags: [Clients]
 *     summary: Create client
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name]
 *             properties:
 *               name:
 *                 type: string
 *               phone:
 *                 type: string
 *               email:
 *                 type: string
 *               address:
 *                 type: string
 *               notes:
 *                 type: string
 *     responses:
 *       201:
 *         description: Created
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 */
router.post('/', validateBody(createClientSchema), createClient);

/**
 * @openapi
 * /api/clients/{id}/transactions:
 *   get:
 *     tags: [Clients]
 *     summary: List client transactions
 *     description: Transaction history for the client, newest first.
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: List of transactions
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Client not found
 */
router.get('/:id/transactions', getClientTransactions);

/**
 * @openapi
 * /api/clients/{id}:
 *   get:
 *     tags: [Clients]
 *     summary: Get client by id
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Client
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Client not found
 */
router.get('/:id', getClientById);

/**
 * @openapi
 * /api/clients/{id}:
 *   put:
 *     tags: [Clients]
 *     summary: Update client
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               phone:
 *                 type: string
 *               email:
 *                 type: string
 *               address:
 *                 type: string
 *               notes:
 *                 type: string
 *     responses:
 *       200:
 *         description: Updated client
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Client not found
 */
router.put('/:id', validateBody(updateClientSchema), updateClient);

/**
 * @openapi
 * /api/clients/{id}:
 *   delete:
 *     tags: [Clients]
 *     summary: Soft-delete client
 *     description: Sets isActive to false.
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Client deactivated
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Client not found
 */
router.delete('/:id', deleteClient);

module.exports = router;
