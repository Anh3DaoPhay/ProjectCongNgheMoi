import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'group_model.dart';

class GroupService {
  GroupService._();
  static final GroupService instance = GroupService._();

  // Tất cả nhóm trên thiết bị (global registry)
  List<GroupModel> _allGroups = [];
  String _currentUserId = '';

  /// Chỉ hiển thị nhóm mà user hiện tại là thành viên HOẶC là chủ tạo ra
  List<GroupModel> get groups => _allGroups
      .where((g) =>
          g.ownerId == _currentUserId ||
          g.members.any((m) => m.userId == _currentUserId))
      .toList();

  // Key toàn cục — dùng chung cho mọi tài khoản trên thiết bị
  static const String _registryKey = 'group_registry_v1';

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> initForUser(String userId) async {
    _currentUserId = userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_registryKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _allGroups = list
            .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _allGroups = [];
      }
    } catch (_) {
      _allGroups = [];
    }
  }

  void clearSession() {
    _currentUserId = '';
    // Không xóa _allGroups khỏi memory —
    // chỉ reset userId, groups getter sẽ tự trả về rỗng
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _registryKey,
        jsonEncode(_allGroups.map((g) => g.toJson()).toList()));
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<GroupModel> createGroup(String name) async {
    final rng = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code =
        List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final group = GroupModel(
      id: id,
      name: name,
      ownerId: _currentUserId,
      members: [],
      referralCode: code,
      createdAt: DateTime.now(),
      wallet: GroupWallet(groupId: id, balance: 0, qrCode: 'GRPWALLET-$code'),
    );
    _allGroups.insert(0, group);
    await _persist();
    return group;
  }

  Future<void> updateGroup(GroupModel updated) async {
    final idx = _allGroups.indexWhere((g) => g.id == updated.id);
    if (idx != -1) {
      _allGroups[idx] = updated;
      await _persist();
    }
  }

  Future<void> deleteGroup(String id) async {
    _allGroups.removeWhere((g) => g.id == id);
    await _persist();
  }

  // ── Join Request Flow ──────────────────────────────────────────────────────

  /// Tìm nhóm theo mã (tìm trong toàn bộ registry)
  /// Trả về: 'ok' | 'not_found' | 'already_member' | 'already_requested'
  Future<String> requestToJoin({
    required String groupCode,
    required String userId,
    required String userName,
  }) async {
    final idx = _allGroups.indexWhere(
        (g) => g.referralCode.toUpperCase() == groupCode.toUpperCase());
    if (idx == -1) return 'not_found';

    final group = _allGroups[idx];
    if (group.ownerId == userId) return 'already_member';
    if (group.members.any((m) => m.userId == userId)) return 'already_member';
    if (group.pendingRequests.any((r) => r.userId == userId)) {
      return 'already_requested';
    }

    final updated = group.copyWith(
      pendingRequests: [
        ...group.pendingRequests,
        JoinRequest(
            userId: userId,
            userName: userName,
            requestedAt: DateTime.now()),
      ],
    );
    _allGroups[idx] = updated;
    await _persist();
    return 'ok';
  }

  /// Chủ nhóm chấp nhận yêu cầu tham gia
  Future<void> approveRequest(
      String groupId, String requestUserId, String requestUserName) async {
    final idx = _allGroups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;

    final group = _allGroups[idx];
    final newMembers = [
      ...group.members,
      GroupMember(userId: requestUserId, name: requestUserName),
    ];
    final newRequests =
        group.pendingRequests.where((r) => r.userId != requestUserId).toList();
    _allGroups[idx] =
        group.copyWith(members: newMembers, pendingRequests: newRequests);
    await _persist();
  }

  /// Chủ nhóm từ chối yêu cầu tham gia
  Future<void> rejectRequest(String groupId, String requestUserId) async {
    final idx = _allGroups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;

    final group = _allGroups[idx];
    final newRequests =
        group.pendingRequests.where((r) => r.userId != requestUserId).toList();
    _allGroups[idx] = group.copyWith(pendingRequests: newRequests);
    await _persist();
  }
}
