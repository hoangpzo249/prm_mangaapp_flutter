import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../../app/routers/app_router.dart';

class AdminUsersListScreen extends StatefulWidget {
  const AdminUsersListScreen({super.key});

  @override
  State<AdminUsersListScreen> createState() => _AdminUsersListScreenState();
}

class _AdminUsersListScreenState extends State<AdminUsersListScreen> {
  final _adminRepo = AdminRepository.instance;
  List<AppUser> _allUsers = [];
  List<AppUser> _filteredUsers = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _adminRepo.fetchUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          final usernameMatch = user.username.toLowerCase().contains(query);
          final fullNameMatch = (user.fullName ?? '').toLowerCase().contains(
            query,
          );
          final emailMatch = (user.email ?? '').toLowerCase().contains(query);
          return usernameMatch || fullNameMatch || emailMatch;
        }).toList();
      }
    });
  }

  Future<void> _toggleBan(AppUser user) async {
    final newBanState = !user.isBanned;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          newBanState ? 'Ban User' : 'Unban User',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          newBanState
              ? 'Bạn có chắc chắn muốn cấm người dùng "${user.username}"?'
              : 'Bạn có chắc chắn muốn bỏ cấm người dùng "${user.username}"?',
          style: const TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSubtle),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              newBanState ? 'Cấm' : 'Kích hoạt',
              style: TextStyle(
                color: newBanState ? AppColors.danger : AppColors.online,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminRepo.updateUser(user.id!, {'isBanned': newBanState});
      _loadUsers();
      _snack(newBanState ? 'Đã cấm người dùng' : 'Đã mở cấm người dùng');
    } catch (e) {
      _snack(
        'Thao tác thất bại: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Quản lý người dùng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh, color: Colors.white),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lỗi: $_error',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          child: const Text('Tải lại'),
                        ),
                      ],
                    ),
                  )
                : _filteredUsers.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy người dùng nào',
                      style: TextStyle(color: AppColors.textSubtle),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, idx) {
                      final user = _filteredUsers[idx];
                      return _buildUserItem(user);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final res = await Navigator.pushNamed(
            context,
            AppRoutes.adminUserForm,
          );
          if (res == true) _loadUsers();
        },
        child: const Icon(Ionicons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.surface,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.card,
          hintText: 'Tìm kiếm username, tên, email...',
          hintStyle: const TextStyle(color: AppColors.textSubtle),
          prefixIcon: const Icon(Ionicons.search, color: AppColors.textSubtle),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Ionicons.close_circle,
                    color: AppColors.textSubtle,
                  ),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildUserItem(AppUser user) {
    final isBanned = user.isBanned;
    final isAdmin = user.role == 'admin';
    final displayName = user.fullName?.isNotEmpty == true
        ? user.fullName!
        : user.username;
    final vipUntil = user.vipUntil;
    final borderColor = isBanned
        ? AppColors.danger.withValues(alpha: 0.4)
        : isAdmin
        ? AppColors.primary.withValues(alpha: 0.35)
        : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.card, AppColors.card.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(displayName, isBanned, user.isVip),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                height: 1.25,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            _buildAdminBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          color: AppColors.textSubtle,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Ionicons.mail_outline,
                            size: 12,
                            color: AppColors.textSubtle,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.email ?? 'Chưa có email',
                              style: const TextStyle(
                                color: AppColors.textSubtle,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (isBanned || (user.isVip && vipUntil != null)) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (isBanned) _buildBannedChip(),
                            if (user.isVip && vipUntil != null)
                              _buildVipChip(vipUntil),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.border.withValues(alpha: 0.5),
          ),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Ionicons.create_outline,
                  label: 'Sửa',
                  color: AppColors.primary,
                  onTap: () async {
                    final res = await Navigator.pushNamed(
                      context,
                      AppRoutes.adminUserForm,
                      arguments: user,
                    );
                    if (res == true) _loadUsers();
                  },
                ),
              ),
              Container(
                width: 1,
                height: 22,
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              Expanded(
                child: _buildActionButton(
                  icon: isBanned
                      ? Ionicons.lock_open_outline
                      : Ionicons.ban_outline,
                  label: isBanned ? 'Mở cấm' : 'Cấm',
                  color: isBanned ? AppColors.online : AppColors.danger,
                  onTap: () => _toggleBan(user),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String displayName, bool isBanned, bool isVip) {
    final baseColor = isBanned ? AppColors.textFaint : AppColors.primary;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor.withValues(alpha: 0.28),
                baseColor.withValues(alpha: 0.12),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: baseColor.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            displayName[0].toUpperCase(),
            style: TextStyle(
              color: isBanned ? AppColors.textSubtle : AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        if (isVip)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gold, AppColors.goldDeep],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.card, width: 2),
              ),
              child: const Icon(Ionicons.star, color: Colors.white, size: 10),
            ),
          ),
      ],
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Ionicons.shield_checkmark, size: 10, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannedChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Ionicons.ban_outline, size: 11, color: AppColors.danger),
          SizedBox(width: 4),
          Text(
            'Đã bị cấm',
            style: TextStyle(
              color: AppColors.danger,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVipChip(DateTime vipUntil) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Ionicons.star, size: 11, color: AppColors.gold),
          const SizedBox(width: 4),
          Text(
            'VIP đến ${DateFormat('dd/MM/yyyy').format(vipUntil)}',
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
