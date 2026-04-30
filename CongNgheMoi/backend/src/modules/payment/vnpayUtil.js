/**
 * vnpayUtil.js
 * Các hàm tiện ích cho VNPay: tạo chữ ký HMAC-SHA512, sắp xếp params, format ngày giờ.
 */

const crypto = require('crypto');
const querystring = require('qs');

/**
 * Tạo chữ ký HMAC-SHA512 theo chuẩn VNPay
 * @param {Object} params - Object chứa các tham số
 * @param {string} secretKey - Secret key từ VNPay merchant
 * @returns {string} - Chuỗi chữ ký hex
 */
function createSignature(params, secretKey) {
    // Sắp xếp params theo alphabet key
    const sortedKeys = Object.keys(params).sort();
    const signData = sortedKeys
        .filter(key => params[key] !== '' && params[key] !== undefined && params[key] !== null)
        .map(key => `${key}=${encodeURIComponent(params[key]).replace(/%20/g, "+")}`)
        .join('&');

    const hmac = crypto.createHmac('sha512', secretKey);
    return hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');
}

/**
 * Xác minh chữ ký từ VNPay IPN/Return
 * @param {Object} params - Toàn bộ query params từ VNPay callback
 * @param {string} secretKey
 * @returns {boolean}
 */
function verifySignature(params, secretKey) {
    const vnpSecureHash = params['vnp_SecureHash'];
    const cleanParams = { ...params };
    delete cleanParams['vnp_SecureHash'];
    delete cleanParams['vnp_SecureHashType'];

    const expectedHash = createSignature(cleanParams, secretKey);
    return vnpSecureHash === expectedHash;
}

/**
 * Format date thành chuỗi YYYYMMDDHHmmss theo múi giờ UTC+7
 * @param {Date} date
 * @returns {string}
 */
function formatDate(date) {
    const pad = (n) => String(n).padStart(2, '0');
    const d = new Date(date.getTime() + 7 * 60 * 60 * 1000); // convert to UTC+7
    return `${d.getUTCFullYear()}${pad(d.getUTCMonth() + 1)}${pad(d.getUTCDate())}${pad(d.getUTCHours())}${pad(d.getUTCMinutes())}${pad(d.getUTCSeconds())}`;
}

/**
 * Tạo mã giao dịch ngẫu nhiên (txnRef) dựa trên orderId + timestamp
 * @param {number|string} orderId
 * @returns {string}
 */
function createTxnRef(orderId) {
    const ts = Date.now().toString().slice(-6);
    return `${orderId}_${ts}`;
}

/**
 * Map mã lỗi VNPay sang message tiếng Việt
 * @param {string} responseCode
 * @returns {string}
 */
function getResponseMessage(responseCode) {
    const messages = {
        '00': 'Giao dịch thành công',
        '07': 'Trừ tiền thành công. Giao dịch bị nghi ngờ (liên quan tới lừa đảo, giao dịch bất thường)',
        '09': 'Thẻ/Tài khoản của khách hàng chưa đăng ký dịch vụ InternetBanking tại ngân hàng',
        '10': 'Khách hàng xác thực thông tin thẻ/tài khoản không đúng quá 3 lần',
        '11': 'Đã hết hạn chờ thanh toán. Xin quý khách vui lòng thực hiện lại giao dịch',
        '12': 'Thẻ/Tài khoản của khách hàng bị khóa',
        '13': 'Quý khách nhập sai mật khẩu xác thực giao dịch (OTP). Xin quý khách vui lòng thực hiện lại giao dịch',
        '24': 'Khách hàng hủy giao dịch',
        '51': 'Tài khoản của quý khách không đủ số dư để thực hiện giao dịch',
        '65': 'Tài khoản của Quý khách đã vượt quá hạn mức giao dịch trong ngày',
        '75': 'Ngân hàng thanh toán đang bảo trì',
        '79': 'KH nhập sai mật khẩu thanh toán quá số lần quy định',
        '99': 'Các lỗi khác',
    };
    return messages[responseCode] || 'Lỗi không xác định';
}

module.exports = {
    createSignature,
    verifySignature,
    formatDate,
    createTxnRef,
    getResponseMessage,
};
