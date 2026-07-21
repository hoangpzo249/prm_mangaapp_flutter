import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../../app/routers/app_router.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _adminRepo = AdminRepository.instance;
  final _authRepo = AuthRepository.instance;

  bool _loading = true;
  String? _error;

  int _totalUsers = 0;
  int _totalStories = 0;
  int _totalViews = 0;
  num _totalRevenue = 0;

  List<Map<String, dynamic>> _userGrowthData = [];
  List<Map<String, dynamic>> _revenueData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final overview = await _adminRepo.fetchOverview();
      final userGrowth = await _adminRepo.fetchUserGrowthChart();
      final revenue = await _adminRepo.fetchRevenueChart();

      if (mounted) {
        setState(() {
          _totalUsers = overview['totalUsers'] as int? ?? 0;
          _totalStories = overview['totalStories'] as int? ?? 0;
          _totalViews = overview['totalViews'] as int? ?? 0;
          _totalRevenue = overview['totalRevenue'] as num? ?? 0;
          _userGrowthData = userGrowth;
          _revenueData = revenue;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Thống kê',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Ionicons.log_out_outline, color: AppColors.danger),
            onPressed: () async {
              await _authRepo.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (r) => false,
                );
              }
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu quản trị',
            color: AppColors.card,
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Ionicons.menu_outline, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'users':
                  Navigator.pushNamed(context, AppRoutes.adminUsers);
                  break;
                case 'stories':
                  Navigator.pushNamed(context, AppRoutes.adminStories);
                  break;
                case 'vip':
                  Navigator.pushNamed(context, '/admin/vip-packages');
                  break;
                case 'reports':
                  Navigator.pushNamed(context, AppRoutes.adminReports);
                  break;
                case 'genres':
                  Navigator.pushNamed(context, AppRoutes.adminGenres);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'users',
                child: Row(
                  children: [
                    Icon(Ionicons.people_outline, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text(
                      'Quản lý người dùng',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'stories',
                child: Row(
                  children: [
                    Icon(Ionicons.book_outline, color: AppColors.gold),
                    SizedBox(width: 12),
                    Text(
                      'Quản lý truyện',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'vip',
                child: Row(
                  children: [
                    Icon(Ionicons.diamond_outline, color: Color(0xFFA855F7)),
                    SizedBox(width: 12),
                    Text(
                      'Quản lý gói VIP',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'reports',
                child: Row(
                  children: [
                    Icon(Ionicons.flag_outline, color: AppColors.danger),
                    SizedBox(width: 12),
                    Text(
                      'Quản lý báo cáo',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'genres',
                child: Row(
                  children: [
                    Icon(Ionicons.pricetags_outline, color: AppColors.online),
                    SizedBox(width: 12),
                    Text(
                      'Quản lý thể loại',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng Quan Hệ Thống',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildKPIs(),
                  const SizedBox(height: 30),
                  _buildChartsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildKPIs() {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final countFormatter = NumberFormat('#,###');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildKPICard(
          title: 'Tổng Người Dùng',
          value: countFormatter.format(_totalUsers),
          icon: Ionicons.person_outline,
          color: Colors.blueAccent,
        ),
        _buildKPICard(
          title: 'Tổng Truyện',
          value: countFormatter.format(_totalStories),
          icon: Ionicons.book_outline,
          color: Colors.greenAccent,
        ),
        _buildKPICard(
          title: 'Tổng Lượt Xem',
          value: countFormatter.format(_totalViews),
          icon: Ionicons.eye_outline,
          color: Colors.orangeAccent,
        ),
        _buildKPICard(
          title: 'Tổng Doanh Thu',
          value: currencyFormatter.format(_totalRevenue),
          icon: Ionicons.cash_outline,
          color: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: 13,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống Kê 7 Ngày Qua',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildChartWrapper(
          title: 'Tăng Trưởng Người Dùng Mới',
          chart: _buildUserGrowthChart(),
        ),
        const SizedBox(height: 20),
        _buildChartWrapper(
          title: 'Doanh Thu Nạp Tiền (VND)',
          chart: _buildRevenueChart(),
        ),
      ],
    );
  }

  Widget _buildChartWrapper({required String title, required Widget chart}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    if (_userGrowthData.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu', style: TextStyle(color: Colors.white)),
      );
    }

    final spots = <FlSpot>[];
    double maxVal = 0;
    for (int i = 0; i < _userGrowthData.length; i++) {
      final val = (_userGrowthData[i]['count'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxVal) maxVal = val;
    }

    // Ensure the y-axis has a sensible top even when all values are 0
    final maxY = maxVal < 1 ? 1.0 : (maxVal.ceilToDouble());
    final interval = maxY <= 5 ? 1.0 : (maxY / 5).ceilToDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: AppColors.border, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                // Only draw whole numbers
                if (value != value.roundToDouble()) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppColors.textSubtle,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < _userGrowthData.length) {
                  final rawDate = _userGrowthData[idx]['date'].toString();
                  // Format: YYYY-MM-DD -> MM/DD
                  final parts = rawDate.split('-');
                  if (parts.length == 3) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${parts[1]}/${parts[2]}',
                        style: const TextStyle(
                          color: AppColors.textSubtle,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            barWidth: 3,
            color: AppColors.primary,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_revenueData.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu', style: TextStyle(color: Colors.white)),
      );
    }

    final spots = <FlSpot>[];
    double maxVal = 0;
    for (int i = 0; i < _revenueData.length; i++) {
      final val = (_revenueData[i]['revenue'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxVal) maxVal = val;
    }

    // Round the top of the axis up to a "nice" number so ticks stay whole
    final maxY = maxVal < 1000 ? 1000.0 : _niceCeil(maxVal);
    final interval = maxY / 4;

    String formatRevenue(double v) {
      if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(v % 1000000000 == 0 ? 0 : 1)}B';
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}M';
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}K';
      return v.toInt().toString();
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: AppColors.border, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    formatRevenue(value),
                    style: const TextStyle(
                      color: AppColors.textSubtle,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < _revenueData.length) {
                  final rawDate = _revenueData[idx]['date'].toString();
                  final parts = rawDate.split('-');
                  if (parts.length == 3) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${parts[1]}/${parts[2]}',
                        style: const TextStyle(
                          color: AppColors.textSubtle,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            barWidth: 3,
            color: AppColors.gold,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.gold.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  double _niceCeil(double value) {
    if (value <= 0) return 1;
    final exponent = (value.toString().length - 1).clamp(0, 12);
    final magnitude = _pow10(exponent);
    return (value / magnitude).ceilToDouble() * magnitude;
  }

  double _pow10(int n) {
    double r = 1;
    for (int i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }
}
