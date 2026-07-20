import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/payment_repository.dart';
import '../../../../domain/entities/vip_package.dart';

class AdminVipPackageScreen extends StatefulWidget {
  const AdminVipPackageScreen({super.key});

  @override
  State<AdminVipPackageScreen> createState() => _AdminVipPackageScreenState();
}

class _AdminVipPackageScreenState extends State<AdminVipPackageScreen>
    with SingleTickerProviderStateMixin {
  final _payment = PaymentRepository.instance;
  bool _loading = true;
  String? _error;
  List<VipPackage> _packages = [];
  String _filter = 'all'; // 'all' | 'active' | 'inactive'

  late final AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadData();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pkgs = await _payment.getAdminPackages();
      if (mounted) {
        setState(() {
          _packages = pkgs;
          _loading = false;
        });
        _fabAnimController.forward();
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

  List<VipPackage> get _filteredPackages {
    if (_filter == 'active') return _packages.where((p) => p.isActive).toList();
    if (_filter == 'inactive')
      return _packages.where((p) => !p.isActive).toList();
    return _packages;
  }

  Future<void> _toggleActive(VipPackage pkg) async {
    try {
      await _payment.updatePackage(pkg.id, {'isActive': !pkg.isActive});
      await _loadData();
      if (mounted) {
        _snack(
          pkg.isActive
              ? 'Đã ẩn gói "${pkg.name}"'
              : 'Đã kích hoạt gói "${pkg.name}"',
          pkg.isActive ? Colors.orange : AppColors.online,
        );
      }
    } catch (e) {
      if (mounted) _snack('Lỗi: $e', AppColors.danger);
    }
  }

  Future<void> _deletePkg(VipPackage pkg) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Ionicons.warning_outline, color: AppColors.danger, size: 22),
            SizedBox(width: 8),
            Text(
              'Xác nhận xóa',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Bạn có chắc muốn xóa gói '),
              TextSpan(
                text: '"${pkg.name}"',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: '?\n\nHành động này không thể hoàn tác.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSubtle),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _payment.deletePackage(pkg.id);
      await _loadData();
      if (mounted) _snack('Đã xóa gói "${pkg.name}"', AppColors.danger);
    } catch (e) {
      if (mounted) _snack('Lỗi: $e', AppColors.danger);
    }
  }

  void _showPackageDialog([VipPackage? pkg]) {
    final isEdit = pkg != null;
    final nameCtrl = TextEditingController(text: pkg?.name ?? '');
    final durationCtrl = TextEditingController(
      text: pkg?.durationDays.toString() ?? '',
    );
    final priceCtrl = TextEditingController(
      text: pkg?.priceCoins.toString() ?? '',
    );
    final descCtrl = TextEditingController(text: pkg?.description ?? '');
    bool isActive = pkg?.isActive ?? true;
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E2D45), Color(0xFF162236)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.15),
                        AppColors.goldDeep.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: const Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.gold, AppColors.goldDeep],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEdit ? Ionicons.pencil : Ionicons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Chỉnh sửa gói VIP' : 'Thêm gói VIP mới',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        _buildFormField(
                          controller: nameCtrl,
                          label: 'Tên gói',
                          hint: 'VD: VIP 1 Tháng',
                          icon: Ionicons.diamond_outline,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Vui lòng nhập tên gói'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: durationCtrl,
                                label: 'Số ngày',
                                hint: 'VD: 30',
                                icon: Ionicons.calendar_outline,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) {
                                  final n = int.tryParse(v ?? '');
                                  if (n == null || n <= 0)
                                    return 'Số ngày phải > 0';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFormField(
                                controller: priceCtrl,
                                label: 'Giá (xu)',
                                hint: 'VD: 150',
                                icon: Ionicons.cash_outline,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) {
                                  final n = int.tryParse(v ?? '');
                                  if (n == null || n < 0) return 'Giá phải ≥ 0';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildFormField(
                          controller: descCtrl,
                          label: 'Mô tả',
                          hint: 'Mô tả chi tiết quyền lợi gói...',
                          icon: Ionicons.document_text_outline,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        // Active toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isActive
                                    ? Ionicons.checkmark_circle
                                    : Ionicons.close_circle_outline,
                                color: isActive
                                    ? AppColors.online
                                    : AppColors.textDim,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Trạng thái',
                                      style: TextStyle(
                                        color: AppColors.textSubtle,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      isActive ? 'Đang kích hoạt' : 'Đã ẩn',
                                      style: TextStyle(
                                        color: isActive
                                            ? AppColors.online
                                            : AppColors.textDim,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isActive,
                                onChanged: (val) =>
                                    setStateSB(() => isActive = val),
                                activeColor: AppColors.online,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: saving ? null : () => Navigator.pop(ctx),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(color: AppColors.textSubtle),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setStateSB(() => saving = true);
                                  try {
                                    final body = {
                                      'name': nameCtrl.text.trim(),
                                      'durationDays': int.parse(
                                        durationCtrl.text,
                                      ),
                                      'priceCoins': int.parse(priceCtrl.text),
                                      'description': descCtrl.text.trim(),
                                      'isActive': isActive,
                                    };
                                    if (isEdit) {
                                      await _payment.updatePackage(
                                        pkg.id,
                                        body,
                                      );
                                    } else {
                                      await _payment.createPackage(body);
                                    }
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    await _loadData();
                                    if (mounted) {
                                      _snack(
                                        isEdit
                                            ? 'Cập nhật thành công!'
                                            : 'Thêm gói thành công!',
                                        AppColors.online,
                                      );
                                    }
                                  } catch (e) {
                                    setStateSB(() => saving = false);
                                    if (mounted)
                                      _snack('Lỗi: $e', AppColors.danger);
                                  }
                                },
                          child: saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isEdit ? 'Cập nhật' : 'Thêm gói',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppColors.danger
                  ? Ionicons.close_circle
                  : Ionicons.checkmark_circle,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quản lý Gói VIP',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          onPressed: () => _showPackageDialog(),
          icon: const Icon(Ionicons.add),
          label: const Text(
            'Thêm gói',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStatsBar(),
          _buildFilterTabs(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final total = _packages.length;
    final active = _packages.where((p) => p.isActive).length;
    final inactive = total - active;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _buildStatChip(
            total.toString(),
            'Tổng cộng',
            AppColors.primary,
            Ionicons.layers_outline,
          ),
          const SizedBox(width: 10),
          _buildStatChip(
            active.toString(),
            'Đang bán',
            AppColors.online,
            Ionicons.checkmark_circle_outline,
          ),
          const SizedBox(width: 10),
          _buildStatChip(
            inactive.toString(),
            'Đã ẩn',
            AppColors.textDim,
            Ionicons.eye_off_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    String count,
    String label,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSubtle,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      ('all', 'Tất cả'),
      ('active', 'Đang bán'),
      ('inactive', 'Đã ẩn'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: filters.map((f) {
          final isSelected = _filter == f.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filter = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppColors.gold, AppColors.goldDeep],
                        )
                      : null,
                  color: isSelected ? null : AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  f.$2,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSubtle,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Ionicons.warning_outline,
              color: AppColors.danger,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Lỗi tải dữ liệu',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.textSubtle, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Ionicons.refresh),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredPackages;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Ionicons.diamond_outline,
                color: AppColors.gold,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không có gói VIP nào',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Nhấn nút "+" để thêm gói mới',
              style: TextStyle(color: AppColors.textSubtle, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: filtered.length,
      itemBuilder: (context, index) =>
          _buildPackageCard(filtered[index], index),
    );
  }

  Widget _buildPackageCard(VipPackage pkg, int index) {
    final colors = _packageGradient(pkg.durationDays.toInt());
    final isActive = pkg.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.card, AppColors.card.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? colors.first.withValues(alpha: 0.35)
              : AppColors.border.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? colors.first.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isActive
                          ? colors
                          : [AppColors.textFaint, AppColors.textDim],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: colors.first.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _packageIcon(pkg.durationDays.toInt()),
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pkg.name,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _buildStatusBadge(isActive),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildInfoChip(
                            Ionicons.calendar_outline,
                            '${pkg.durationDays} ngày',
                            isActive ? AppColors.primary : AppColors.textDim,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Ionicons.cash_outline,
                            '${pkg.priceCoins} xu',
                            isActive ? AppColors.gold : AppColors.textDim,
                          ),
                        ],
                      ),
                      if (pkg.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          pkg.description,
                          style: const TextStyle(
                            color: AppColors.textSubtle,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: AppColors.border.withValues(alpha: 0.5),
          ),

          // Actions row
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  icon: Ionicons.create_outline,
                  label: 'Sửa',
                  color: AppColors.primary,
                  onTap: () => _showPackageDialog(pkg),
                ),
              ),
              Container(
                width: 1,
                height: 22,
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              Expanded(
                child: _buildActionBtn(
                  icon: isActive
                      ? Ionicons.eye_off_outline
                      : Ionicons.eye_outline,
                  label: isActive ? 'Ẩn gói' : 'Hiện',
                  color: isActive ? Colors.orange : AppColors.online,
                  onTap: () => _toggleActive(pkg),
                ),
              ),
              Container(
                width: 1,
                height: 22,
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              Expanded(
                child: _buildActionBtn(
                  icon: Ionicons.trash_outline,
                  label: 'Xóa',
                  color: AppColors.danger,
                  onTap: () => _deletePkg(pkg),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.online.withValues(alpha: 0.15)
            : AppColors.textFaint.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive
              ? AppColors.online.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Text(
        isActive ? 'Đang bán' : 'Đã ẩn',
        style: TextStyle(
          color: isActive ? AppColors.online : AppColors.textDim,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 13),
        hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.gold, size: 18),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  List<Color> _packageGradient(int days) {
    if (days <= 7) return [const Color(0xFF22C55E), const Color(0xFF16A34A)];
    if (days <= 30) return [AppColors.primary, AppColors.primaryDark];
    if (days <= 90) return [const Color(0xFFA855F7), const Color(0xFF9333EA)];
    return [AppColors.gold, AppColors.goldDeep];
  }

  IconData _packageIcon(int days) {
    if (days <= 7) return Ionicons.flash;
    if (days <= 30) return Ionicons.star;
    if (days <= 90) return Ionicons.diamond;
    return Ionicons.trophy;
  }
}
