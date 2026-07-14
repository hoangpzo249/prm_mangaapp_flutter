import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/admin_repository.dart';

class AdminReportManagementScreen extends StatefulWidget {
  const AdminReportManagementScreen({super.key});

  @override
  State<AdminReportManagementScreen> createState() =>
      _AdminReportManagementScreenState();
}

class _AdminReportManagementScreenState
    extends State<AdminReportManagementScreen> {
  final AdminRepository _adminRepository = AdminRepository.instance;

  final List<String> _statuses = const [
    'all',
    'pending',
    'resolved',
    'rejected',
  ];

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  String _selectedStatus = 'all';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalReports = 0;
  final int _limit = 20;

  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports({int page = 1, bool append = false}) async {
    if (append) {
      if (_loadingMore || page > _totalPages) return;
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await _adminRepository.fetchReports(
        status: _selectedStatus,
        page: page,
        limit: _limit,
      );

      final parsedReports = _extractReports(response);
      final pagination = _extractPagination(response);

      if (!mounted) return;

      setState(() {
        if (append) {
          _reports.addAll(parsedReports);
        } else {
          _reports = parsedReports;
        }

        _currentPage = pagination.currentPage;
        _totalPages = pagination.totalPages;
        _totalReports = pagination.totalReports;
        _loading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = _errorMessage(error);
      });
    }
  }

  List<Map<String, dynamic>> _extractReports(Map<String, dynamic> response) {
    final dynamic raw =
        response['reports'] ?? response['data'] ?? response['items'] ?? [];

    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  _ReportPagination _extractPagination(Map<String, dynamic> response) {
    final paginationRaw = response['pagination'];
    final pagination = paginationRaw is Map
        ? Map<String, dynamic>.from(paginationRaw)
        : <String, dynamic>{};

    final currentPage = _toInt(
      pagination['currentPage'] ??
          pagination['page'] ??
          response['currentPage'] ??
          response['page'],
      fallback: 1,
    );

    final totalPages = _toInt(
      pagination['totalPages'] ?? response['totalPages'],
      fallback: 1,
    );

    final totalReports = _toInt(
      pagination['total'] ??
          pagination['totalReports'] ??
          response['total'] ??
          response['totalReports'],
      fallback: _reports.length,
    );

    return _ReportPagination(
      currentPage: currentPage,
      totalPages: totalPages < 1 ? 1 : totalPages,
      totalReports: totalReports,
    );
  }

  int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _errorMessage(Object error) {
    final message = error.toString().replaceFirst(
      RegExp(r'^Exception:\s*'),
      '',
    );

    return message.trim().isEmpty ? 'Không thể tải danh sách báo cáo' : message;
  }

  Future<void> _changeStatus(String status) async {
    if (_selectedStatus == status) return;

    setState(() {
      _selectedStatus = status;
      _currentPage = 1;
      _reports = [];
    });

    await _loadReports();
  }

  Future<void> _openReportDetail(Map<String, dynamic> report) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportDetailSheet(
        report: report,
        onResolve: (action, note) async {
          final id = _value(report, ['_id', 'id']);

          if (id.isEmpty) {
            throw Exception('Không tìm thấy ID report');
          }

          await _adminRepository.resolveReport(id, action, adminNote: note);

          if (!mounted) return;

          Navigator.pop(context);
          _showSnack('Đã xử lý báo cáo thành công');
          await _loadReports();
        },
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _value(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'resolved':
        return 'Đã xử lý';
      case 'rejected':
        return 'Từ chối';
      default:
        return 'Tất cả';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orangeAccent;
      case 'resolved':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Quản lý báo cáo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loading ? null : _loadReports,
            icon: const Icon(Ionicons.refresh_outline, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildStatusFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Ionicons.flag_outline, color: Colors.redAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Báo cáo vi phạm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tổng cộng $_totalReports báo cáo',
                  style: const TextStyle(
                    color: AppColors.textSubtle,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = _statuses[index];
          final selected = status == _selectedStatus;
          final color = _statusColor(status);

          return ChoiceChip(
            selected: selected,
            onSelected: (_) => _changeStatus(status),
            label: Text(_statusLabel(status)),
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: color.withValues(alpha: 0.85),
            backgroundColor: AppColors.card,
            side: BorderSide(color: selected ? color : AppColors.border),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadReports);
    }

    if (_reports.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadReports,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: _reports.length + (_currentPage < _totalPages ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == _reports.length) {
            return _buildLoadMoreButton();
          }

          final report = _reports[index];
          return _ReportCard(
            report: report,
            onTap: () => _openReportDetail(report),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: OutlinedButton(
        onPressed: _loadingMore
            ? null
            : () => _loadReports(page: _currentPage + 1, append: true),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _loadingMore
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Text('Tải thêm (${_currentPage + 1}/$_totalPages)'),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  String _value(List<String> keys, {String fallback = 'Không có dữ liệu'}) {
    for (final key in keys) {
      final value = report[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String _nestedValue(
    String parent,
    List<String> keys, {
    String fallback = 'Không xác định',
  }) {
    final raw = report[parent];
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final key in keys) {
        final value = map[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }
    return fallback;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'resolved':
        return 'Đã xử lý';
      case 'rejected':
        return 'Từ chối';
      default:
        return 'Chờ xử lý';
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetType = _value(['targetType'], fallback: 'unknown');
    final reason = _value(['reason']);
    final status = _value(['status'], fallback: 'pending');
    final reporter = _nestedValue('reporterId', [
      'fullName',
      'username',
      'email',
    ]);

    final typeColor = targetType == 'comment'
        ? Colors.blueAccent
        : AppColors.gold;
    final typeIcon = targetType == 'comment'
        ? Ionicons.chatbubble_outline
        : Ionicons.book_outline;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor, size: 21),
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
                            targetType == 'comment'
                                ? 'Báo cáo bình luận'
                                : 'Báo cáo truyện',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StatusBadge(
                          label: _statusLabel(status),
                          color: _statusColor(status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Ionicons.person_outline,
                          color: AppColors.textSubtle,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            reporter,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSubtle,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Icon(
                          Ionicons.chevron_forward,
                          color: AppColors.textSubtle,
                          size: 17,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportDetailSheet extends StatefulWidget {
  final Map<String, dynamic> report;
  final Future<void> Function(String action, String note) onResolve;

  const _ReportDetailSheet({required this.report, required this.onResolve});

  @override
  State<_ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<_ReportDetailSheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _value(List<String> keys, {String fallback = 'Không có dữ liệu'}) {
    for (final key in keys) {
      final value = widget.report[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String _nestedValue(
    String parent,
    List<String> keys, {
    String fallback = 'Không xác định',
  }) {
    final raw = widget.report[parent];

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);

      for (final key in keys) {
        final value = map[key];

        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }

    return fallback;
  }

  Future<void> _submit(String action) async {
    if (_submitting) return;

    setState(() => _submitting = true);

    try {
      await widget.onResolve(action, _noteController.text.trim());
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst(
        RegExp(r'^Exception:\s*'),
        '',
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              message.trim().isEmpty ? 'Không thể xử lý báo cáo' : message,
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _value(['status'], fallback: 'pending');
    final targetType = _value(['targetType'], fallback: 'unknown');

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chi tiết báo cáo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _DetailRow(
                title: 'Loại đối tượng',
                value: targetType == 'comment' ? 'Bình luận' : 'Truyện',
              ),
              _DetailRow(
                title: 'Người báo cáo',
                value: _nestedValue('reporterId', [
                  'fullName',
                  'username',
                  'email',
                ]),
              ),
              _DetailRow(title: 'Lý do', value: _value(['reason'])),
              _DetailRow(title: 'ID đối tượng', value: _value(['targetId'])),
              _DetailRow(title: 'Trạng thái', value: status),
              if (status == 'pending') ...[
                const SizedBox(height: 18),
                TextField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  enabled: !_submitting,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Ghi chú của admin',
                    labelStyle: const TextStyle(color: AppColors.textSubtle),
                    hintText: 'Nhập ghi chú xử lý nếu cần...',
                    hintStyle: const TextStyle(color: AppColors.textSubtle),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : () => _submit('reject'),
                        icon: const Icon(Ionicons.close_circle_outline),
                        label: const Text('Từ chối'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => _submit('resolve'),
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Ionicons.checkmark_circle_outline),
                        label: const Text('Xử lý'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;

  const _DetailRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
          ),
          const SizedBox(height: 5),
          SelectableText(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Ionicons.alert_circle_outline,
              size: 56,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Ionicons.checkmark_done_circle_outline,
              size: 64,
              color: Colors.greenAccent,
            ),
            SizedBox(height: 14),
            Text(
              'Không có báo cáo phù hợp',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Các báo cáo mới sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSubtle),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportPagination {
  final int currentPage;
  final int totalPages;
  final int totalReports;

  const _ReportPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalReports,
  });
}
