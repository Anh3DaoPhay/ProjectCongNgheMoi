const express = require('express');
const router = express.Router();
const PaymentController = require('../modules/payment/paymentController');
const { verifyToken, authorizeRole } = require('../middleware/authMiddleware');

// Public (VNPay gọi về, không cần token)
router.get('/vnpay-return', PaymentController.returnUrl);
router.post('/vnpay-ipn',   PaymentController.ipnHandler);
router.get('/vnpay-ipn',    PaymentController.ipnHandler); // VNPay có thể dùng GET

// Protected (chỉ customer)
router.use(verifyToken);
router.post('/create',               authorizeRole([1]), PaymentController.createPayment);
router.post('/refund',               authorizeRole([1]), PaymentController.refundPayment);
router.get('/status/:maDonHang',     authorizeRole([1]), PaymentController.getStatus);

module.exports = router;
