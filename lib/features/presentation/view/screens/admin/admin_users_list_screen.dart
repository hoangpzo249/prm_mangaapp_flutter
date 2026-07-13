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
    final displayName = user.fullName?.isNotEmpty == true
        ? user.fullName!
        : user.username;
    final vipUntil = user.vipUntil;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBanned
              ? AppColors.danger.withValues(alpha: 0.3)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isBanned
                  ? AppColors.textFaint
                  : AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              displayName[0].toUpperCase(),
              style: TextStyle(
                color: isBanned ? AppColors.textSubtle : AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.role == 'admin') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (user.isVip) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Ionicons.star,
                        color: AppColors.star,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username} • ${user.email ?? "No email"}',
                  style: const TextStyle(
                    color: AppColors.textSubtle,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.isVip && vipUntil != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'VIP đến: ${DateFormat('dd/MM/yyyy').format(vipUntil)}',
                    style: const TextStyle(
                      color: AppColors.star,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                icon: const Icon(
                  Ionicons.create_outline,
                  color: AppColors.primary,
                ),
                onPressed: () async {
                  final res = await Navigator.pushNamed(
                    context,
                    AppRoutes.adminUserForm,
                    arguments: user,
                  );
                  if (res == true) _loadUsers();
                },
              ),
              IconButton(
                icon: Icon(
                  isBanned ? Ionicons.lock_open_outline : Ionicons.ban_outline,
                  color: isBanned ? AppColors.online : AppColors.danger,
                  size: 20,
                ),
                onPressed: () => _toggleBan(user),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
