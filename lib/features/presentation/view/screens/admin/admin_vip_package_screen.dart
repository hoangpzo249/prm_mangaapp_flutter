import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/payment_repository.dart';
import '../../../../domain/entities/vip_package.dart';

class AdminVipPackageScreen extends StatefulWidget {
  const AdminVipPackageScreen({super.key});

  @override
  State<AdminVipPackageScreen> createState() => _AdminVipPackageScreenState();
}

class _AdminVipPackageScreenState extends State<AdminVipPackageScreen> {
  final _payment = PaymentRepository.instance;
  bool _loading = true;
  List<VipPackage> _packages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final pkgs = await _payment.getAdminPackages();
      if (mounted) {
        setState(() {
          _packages = pkgs;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deletePkg(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: const Text('Bạn có chắc chắn muốn xóa gói VIP này?', style: TextStyle(color: AppColors.textLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await _payment.deletePackage(id);
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thành công!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPackageDialog([VipPackage? pkg]) {
    final isEdit = pkg != null;
    final nameCtrl = TextEditingController(text: pkg?.name ?? '');
    final durationCtrl = TextEditingController(text: pkg?.durationDays.toString() ?? '');
    final priceCtrl = TextEditingController(text: pkg?.priceCoins.toString() ?? '');
    final descCtrl = TextEditingController(text: pkg?.description ?? '');
    bool isActive = pkg?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              title: Text(isEdit ? 'Sửa gói VIP' : 'Thêm gói VIP', style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Tên gói (vd: Gói 1 Tháng)'),
                    ),
                    TextField(
                      controller: durationCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Số ngày (vd: 30)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: priceCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Giá xu (vd: 1000)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: descCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Mô tả chi tiết'),
                    ),
                    SwitchListTile(
                      title: const Text('Kích hoạt', style: TextStyle(color: Colors.white)),
                      value: isActive,
                      onChanged: (val) => setStateSB(() => isActive = val),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    setState(() => _loading = true);
                    try {
                      final body = {
                        'name': nameCtrl.text,
                        'durationDays': int.tryParse(durationCtrl.text) ?? 0,
                        'priceCoins': int.tryParse(priceCtrl.text) ?? 0,
                        'description': descCtrl.text,
                        'isActive': isActive,
                      };
                      if (isEdit) {
                        await _payment.updatePackage(pkg.id, body);
                      } else {
                        await _payment.createPackage(body);
                      }
                      await _loadData();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Cập nhật thành công!' : 'Thêm thành công!')));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      if (mounted) setState(() => _loading = false);
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quản lý Gói VIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.add, color: Colors.white),
            onPressed: () => _showPackageDialog(),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _packages.isEmpty
              ? const Center(child: Text('Chưa có gói VIP nào', style: TextStyle(color: AppColors.textDim)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _packages.length,
                  itemBuilder: (context, index) {
                    final pkg = _packages[index];
                    return Card(
                      color: AppColors.card,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(pkg.name, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        subtitle: Text('${pkg.durationDays} ngày - ${pkg.priceCoins} Xu\nTrạng thái: ${pkg.isActive ? "Đang bán" : "Đã ẩn"}', style: const TextStyle(color: AppColors.textLight)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Ionicons.pencil, color: Colors.blue),
                              onPressed: () => _showPackageDialog(pkg),
                            ),
                            IconButton(
                              icon: const Icon(Ionicons.trash, color: Colors.red),
                              onPressed: () => _deletePkg(pkg.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
