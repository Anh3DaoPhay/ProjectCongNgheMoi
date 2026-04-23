require('dotenv').config();
const db = require('./src/config/db.js');
async function run() {
    try {
        await db.query("ALTER TABLE chitietdonhang ADD COLUMN trangThaiMon VARCHAR(20) DEFAULT 'pending'");
        console.log("Success");
        process.exit(0);
    } catch(e) {
        if (e.code === 'ER_DUP_FIELDNAME') {
            console.log("Column already exists");
            process.exit(0);
        } else {
            console.error(e);
            process.exit(1);
        }
    }
}
run();
