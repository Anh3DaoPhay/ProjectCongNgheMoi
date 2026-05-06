const db = require('../config/db');
const crypto = require('crypto');

const GroupModel = {
  createGroup: async (name, creatorId) => {
    const groupId = crypto.randomUUID();
    const referralCode = 'G' + Math.random().toString(36).substring(2, 8).toUpperCase();
    
    // Create group
    await db.query(
      `INSERT INTO groups (id, name, referral_code, creator_id) VALUES (?, ?, ?, ?)`,
      [groupId, name, referralCode, creatorId]
    );

    // Add creator as admin
    await db.query(
      `INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, 'admin')`,
      [groupId, creatorId]
    );

    // Create wallet
    await db.query(
      `INSERT INTO group_wallets (group_id, balance, qr_code) VALUES (?, 0, ?)`,
      [groupId, `QR-${referralCode}`]
    );

    return { 
      id: groupId, 
      name, 
      referralCode, 
      ownerId: creatorId,
      createdAt: new Date(),
      members: [{
        userId: creatorId,
        name: 'Admin', // Temporary, frontend will refresh
        isAdmin: true
      }],
      wallet: {
        groupId: groupId,
        balance: 0,
        qrCode: `QR-${referralCode}`
      }
    };
  },

  getGroupsByUserId: async (userId) => {
    const groups = await db.query(
      `SELECT g.id, g.name, g.avatar_url as avatarUrl, g.referral_code as referralCode, g.creator_id as ownerId, g.created_at as createdAt, w.balance, w.qr_code as qrCode
       FROM groups g
       JOIN group_members gm ON g.id = gm.group_id
       LEFT JOIN group_wallets w ON g.id = w.group_id
       WHERE gm.user_id = ? AND g.status = 1
       ORDER BY g.created_at DESC`,
      [userId]
    );

    // Fetch members for each group
    for (let group of groups) {
      const members = await db.query(
        `SELECT gm.user_id as userId, t.hoTen as name, t.anhDaiDien as avatarUrl, gm.role 
         FROM group_members gm
         JOIN taikhoan t ON gm.user_id = t.maTaiKhoan
         WHERE gm.group_id = ?`,
        [group.id]
      );
      group.members = members.map(m => ({
        userId: m.userId.toString(),
        name: m.name,
        avatarUrl: m.avatarUrl,
        isAdmin: m.role === 'admin'
      }));
      
      group.wallet = {
        groupId: group.id,
        balance: parseFloat(group.balance || 0),
        qrCode: group.qrCode || ''
      };

      // Đảm bảo ownerId cũng là string để đồng bộ frontend
      group.ownerId = group.ownerId.toString();
    }
    return groups;
  },

  joinGroup: async (groupId, userId) => {
    // Kiểm tra group tồn tại
    const groups = await db.query(
      `SELECT id, creator_id as ownerId FROM groups WHERE id = ? AND status = 1`,
      [groupId]
    );
    if (groups.length === 0) throw new Error('Nhóm không tồn tại');

    // Kiểm tra đã là thành viên chưa
    const existing = await db.query(
      `SELECT id FROM group_members WHERE group_id = ? AND user_id = ?`,
      [groupId, userId]
    );
    if (existing.length > 0) return { alreadyMember: true };

    // Thêm vào nhóm
    await db.query(
      `INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, 'member')`,
      [groupId, userId]
    );
    return { alreadyMember: false };
  },

  leaveGroup: async (groupId, userId) => {
    const groups = await db.query(
      `SELECT creator_id FROM groups WHERE id = ? AND status = 1`, [groupId]
    );
    if (groups.length === 0) throw new Error('Nhóm không tồn tại');
    if (groups[0].creator_id == userId) throw new Error('Nhóm trưởng không thể rời nhóm, hãy giải tán nhóm');
    await db.query(`DELETE FROM group_members WHERE group_id = ? AND user_id = ?`, [groupId, userId]);
    return { success: true };
  },

  removeMember: async (groupId, ownerId, targetUserId) => {
    const groups = await db.query(
      `SELECT creator_id FROM groups WHERE id = ? AND status = 1`, [groupId]
    );
    if (groups.length === 0) throw new Error('Nhóm không tồn tại');
    if (groups[0].creator_id != ownerId) throw new Error('Không có quyền xóa thành viên');
    if (targetUserId == ownerId) throw new Error('Không thể xóa chính mình');
    await db.query(`DELETE FROM group_members WHERE group_id = ? AND user_id = ?`, [groupId, targetUserId]);
    return { success: true };
  },

  disbandGroup: async (groupId, ownerId) => {
    const groups = await db.query(
      `SELECT creator_id FROM groups WHERE id = ? AND status = 1`, [groupId]
    );
    if (groups.length === 0) throw new Error('Nhóm không tồn tại');
    if (groups[0].creator_id != ownerId) throw new Error('Chỉ nhóm trưởng mới được giải tán nhóm');
    await db.query(`UPDATE groups SET status = 0 WHERE id = ?`, [groupId]);
    return { success: true };
  }
};

module.exports = GroupModel;
