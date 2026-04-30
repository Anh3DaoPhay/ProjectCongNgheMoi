import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/service_call.dart';
import 'chat_service.dart';
import 'group_budget_tab.dart';
import 'group_chat_tab.dart';
import 'group_members_sheet.dart';
import 'group_model.dart';
import 'group_requests_tab.dart';
import 'group_service.dart';
import 'group_wallet_view.dart';

class GroupDetailView extends StatefulWidget {
  final GroupModel group;
  const GroupDetailView({super.key, required this.group});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView>
    with SingleTickerProviderStateMixin {
  late GroupModel _group;
  late TabController _tabCtrl;
  final List<GroupMessage> _messages = [];
  bool _isLoadingChat = true;

  // Lưu sẵn khi initState — không dùng getter tự tính vì có thể thay đổi giữa các await
  String _myId = '';
  String _myName = 'Bạn';

  static String _resolveId(Map<String, dynamic> p) =>
      p['maTaiKhoan']?.toString() ??
      p['id']?.toString() ??
      p['_id']?.toString() ?? '';

  static String _resolveName(Map<String, dynamic> p) =>
      p['hoTen']?.toString() ??
      p['name']?.toString() ??
      p['fullName']?.toString() ?? 'Bạn';

  // Chủ nhóm
  bool get _isAdmin {
    if (_group.ownerId == _myId) return true;
    if (_group.members.isEmpty) return false;
    return _group.members.any((m) => m.userId == _myId && m.isAdmin);
  }

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _tabCtrl = TabController(length: 2, vsync: this);
    // Lưu ID/tên ngay khi init — tránh thay đổi giữa các async gaps
    final p = Map<String, dynamic>.from(ServiceCall.userPayload);
    _myId = _resolveId(p);
    _myName = _resolveName(p);
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    var saved = await ChatService.instance.loadMessages(_group.id);

    // Migration: tin nhắn cũ có senderId = '' (vì _myId lúc đó chưa đúng)
    // → gán lại đúng myId để hiển thị đúng bên phải
    if (saved.any((m) => m.senderId.isEmpty) && _myId.isNotEmpty) {
      saved = saved.map((m) {
        if (m.senderId.isEmpty) {
          return GroupMessage(
            id: m.id,
            senderId: _myId,
            senderName: _myName,
            text: m.text,
            imageUrl: m.imageUrl,
            timestamp: m.timestamp,
            seenBy: List<String>.from(m.seenBy),
          );
        }
        return m;
      }).toList();
      // Lưu lại đã fix
      await ChatService.instance.saveMessages(_group.id, saved);
    }

    // Đánh dấu toàn bộ là đã đọc
    saved = await ChatService.instance.markSeen(_group.id, _myId, saved);
    if (mounted) {
      setState(() {
        _messages.addAll(saved);
        _isLoadingChat = false;
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Send message ──────────────────────────────────────────────────────────
  Future<void> _sendText(String text) async {
    final msg = GroupMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _myId, senderName: _myName,
      text: text, timestamp: DateTime.now(),
      seenBy: [_myId], // mình tự cà đã thấy
    );
    setState(() => _messages.add(msg));
    await ChatService.instance.appendMessage(_group.id, msg);
  }

  // ── Invite member ─────────────────────────────────────────────────────────
  Future<void> _inviteMember() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mời thành viên', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Mã nhóm: ${_group.referralCode}',
              style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w800,
                  fontSize: 20, letterSpacing: 3)),
          const SizedBox(height: 16),
          TextField(controller: ctrl,
            decoration: InputDecoration(hintText: 'Email hoặc số điện thoại...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: TColor.primary, width: 1.5)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppNotification.show(context,
                  message: 'Đã gửi lời mời đến ${ctrl.text}', type: NotifType.success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: TColor.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Gửi mời', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Edit group name ───────────────────────────────────────────────────────
  Future<void> _editGroupName() async {
    final ctrl = TextEditingController(text: _group.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đổi tên nhóm', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(controller: ctrl, autofocus: true,
          decoration: InputDecoration(hintText: 'Tên nhóm...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: TColor.primary, width: 1.5)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: TColor.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _group = _group.copyWith(name: result));
      await GroupService.instance.updateGroup(_group);
    }
  }

  // ── Leave group ───────────────────────────────────────────────────────────
  Future<void> _leaveGroup() async {
    final ok = await AppNotification.confirm(context,
        title: 'Rời khỏi nhóm',
        message: 'Bạn có chắc muốn rời khỏi nhóm "${_group.name}"?',
        confirmText: 'Rời nhóm', cancelText: 'Huỷ');
    if (ok == true && mounted) {
      await GroupService.instance.deleteGroup(_group.id);
      AppNotification.show(context,
          message: 'Đã rời khỏi nhóm "${_group.name}"', type: NotifType.info);
      Navigator.pop(context);
    }
  }

  // ── Withdraw ──────────────────────────────────────────────────────────────
  Future<void> _withdrawMoney() async {
    final balance = _group.wallet?.balance ?? 0;
    if (balance <= 0) {
      AppNotification.show(context,
          message: 'Ví nhóm không có số dư để rút.', type: NotifType.warning);
      return;
    }
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rút tiền từ ví nhóm', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Số dư: ${balance.toStringAsFixed(0)} đ',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(controller: ctrl, keyboardType: TextInputType.number, autofocus: true,
            decoration: InputDecoration(hintText: 'Số tiền muốn rút...', suffixText: 'đ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: TColor.primary, width: 1.5)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(ctrl.text.replaceAll(',', '')) ?? 0;
              Navigator.pop(ctx);
              if (amt <= 0 || amt > balance) {
                AppNotification.show(context,
                    message: amt <= 0 ? 'Số tiền không hợp lệ' : 'Vượt quá số dư!',
                    type: NotifType.error);
                return;
              }
              AppNotification.show(context,
                  title: 'Yêu cầu đã gửi!',
                  message: 'Rút ${amt.toStringAsFixed(0)} đ thành công.',
                  type: NotifType.success);
              // TODO: gọi API
            },
            style: ElevatedButton.styleFrom(backgroundColor: TColor.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: GestureDetector(
          onTap: _editGroupName,
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: TColor.primary.withValues(alpha: 0.12),
              backgroundImage: _group.avatarUrl != null ? NetworkImage(_group.avatarUrl!) : null,
              child: _group.avatarUrl == null
                  ? Text(_group.name[0].toUpperCase(),
                      style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w800, fontSize: 14))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_group.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  overflow: TextOverflow.ellipsis),
            Text('${_group.members.length + (_group.ownerId.isNotEmpty ? 1 : 0)} thành viên',
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ])),
          ]),
        ),
        actions: [
          // Nút xem thành viên
          IconButton(
            icon: const Icon(Icons.group_rounded),
            color: Colors.grey.shade600,
            tooltip: 'Thành viên',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => GroupMembersSheet(
                  group: _group, myId: _myId),
            ),
          ),
          // Nút yêu cầu tham gia (chỉ admin thấy khi có yêu cầu)
          if (_isAdmin && _group.pendingRequests.isNotEmpty)
            Stack(alignment: Alignment.topRight, children: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded),
                color: TColor.primary,
                tooltip: 'Yêu cầu tham gia',
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => GroupRequestsSheet(
                    group: _group,
                    onChanged: () => setState(() {
                      final updated = GroupService.instance.groups
                          .firstWhere((g) => g.id == _group.id,
                              orElse: () => _group);
                      _group = updated;
                    }),
                  ),
                ),
              ),
              Positioned(
                right: 8, top: 8,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '${_group.pendingRequests.length}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ]),
          IconButton(icon: Icon(Icons.person_add_rounded, color: TColor.primary),
              onPressed: _inviteMember, tooltip: 'Mời thành viên'),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (v) {
              if (v == 'wallet') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GroupWalletView(group: _group)));
              } else if (v == 'withdraw') {
                _withdrawMoney();
              } else if (v == 'leave') {
                _leaveGroup();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'wallet',
                  child: ListTile(leading: Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2ECC71)),
                      title: Text('Ví nhóm'), contentPadding: EdgeInsets.zero)),
              PopupMenuItem(value: 'withdraw',
                  child: ListTile(leading: Icon(Icons.arrow_circle_down_rounded, color: Color(0xFF6C63FF)),
                      title: Text('Rút tiền'), contentPadding: EdgeInsets.zero)),
              PopupMenuDivider(),
              PopupMenuItem(value: 'leave',
                  child: ListTile(leading: Icon(Icons.exit_to_app_rounded, color: Colors.red),
                      title: Text('Rời nhóm', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: TColor.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: TColor.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [Tab(text: '💬 Chat'), Tab(text: '💰 Ngân sách')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          GroupChatTab(
            messages: _messages,
            myId: _myId,
            isLoading: _isLoadingChat,
            members: _group.members,
            onSendText: _sendText,
            onSendImage: () async {},
          ),
          GroupBudgetTab(group: _group),
        ],
      ),
    );
  }
}
