/**
 * vnpayService.js
 * Logic nghiệp vụ VNPay: tạo URL thanh toán, xác minh IPN.
 */

const { createSignature, verifySignature, formatDate, createTxnRef, getResponseMessage } = require('./vnpayUtil');

// ── Cấu hình VNPay (nên để vào .env) ───────────────────────────────────────
const VNPAY_CONFIG = {
    tmnCode:       process.env.VNPAY_TMN_CODE    || 'DEMOTMN',
    secretKey:     process.env.VNPAY_HASH_KEY    || 'DEMOSECRETKEY',
    vnpUrl:        process.env.VNPAY_URL         || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
    returnUrl:     process.env.VNPAY_RETURN_URL  || 'http://10.0.2.2:3001/api/payment/vnpay-return',
    ipnUrl:        process.env.VNPAY_IPN_URL     || 'http://10.0.2.2:3001/api/payment/vnpay-ipn',
    locale:        'vn',
    currCode:      'VND',
    version:       '2.1.0',
    command:       'pay',
    orderType:     'other',
};

/**
 * Tạo URL thanh toán VNPay
 * @param {Object} opts
 * @param {number} opts.orderId        - maDonHang trong DB
 * @param {number} opts.amount         - Số tiền (VND, không có phần thập phân)
 * @param {string} opts.orderInfo      - Mô tả đơn hàng
 * @param {string} opts.clientIp       - IP người dùng
 * @param {string} [opts.bankCode]     - Mã ngân hàng nếu chọn trực tiếp
 * @returns {{ payUrl: string, txnRef: string }}
 */
function createPaymentUrl({ orderId, amount, orderInfo, clientIp, bankCode = '' }) {
    const txnRef   = createTxnRef(orderId);
    const createDate = formatDate(new Date());

    const vnpParams = {
        vnp_Version:     VNPAY_CONFIG.version,
        vnp_Command:     VNPAY_CONFIG.command,
        vnp_TmnCode:     VNPAY_CONFIG.tmnCode,
        vnp_Locale:      VNPAY_CONFIG.locale,
        vnp_CurrCode:    VNPAY_CONFIG.currCode,
        vnp_TxnRef:      txnRef,
        vnp_OrderInfo:   orderInfo || `Thanh toan don hang #${orderId}`,
        vnp_OrderType:   VNPAY_CONFIG.orderType,
        vnp_Amount:      amount * 100,   // VNPay tính theo đơn vị nhỏ nhất (x100)
        vnp_ReturnUrl:   VNPAY_CONFIG.returnUrl,
        vnp_IpAddr:      clientIp || '127.0.0.1',
        vnp_CreateDate:  createDate,
    };

    if (bankCode) {
        vnpParams.vnp_BankCode = bankCode;
    }

    // Ký chữ ký
    const secureHash = createSignature(vnpParams, VNPAY_CONFIG.secretKey);
    vnpParams.vnp_SecureHash = secureHash;

    // Build URL
    const sortedKeys = Object.keys(vnpParams).sort();
    const queryStr = sortedKeys
        .map(k => `${encodeURIComponent(k)}=${encodeURIComponent(vnpParams[k]).replace(/%20/g, "+")}`)
        .join('&');

    return {
        payUrl: `${VNPAY_CONFIG.vnpUrl}?${queryStr}`,
        txnRef,
    };
}

/**
 * Xác minh callback từ VNPay (Return URL hoặc IPN)
 * @param {Object} query - req.query từ VNPay callback
 * @returns {{ isValid: boolean, responseCode: string, txnRef: string, orderId: string, message: string }}
 */
function verifyCallback(query) {
    const isValid = verifySignature(query, VNPAY_CONFIG.secretKey);
    const responseCode = query['vnp_ResponseCode'] || '';
    const txnRef = query['vnp_TxnRef'] || '';
    const orderId = txnRef.split('_')[0]; // vì txnRef = `${orderId}_${ts}`

    return {
        isValid,
        responseCode,
        txnRef,
        orderId,
        amount: parseInt(query['vnp_Amount'] || '0') / 100,
        message: getResponseMessage(responseCode),
        success: isValid && responseCode === '00',
    };
}

module.exports = { createPaymentUrl, verifyCallback, VNPAY_CONFIG };
