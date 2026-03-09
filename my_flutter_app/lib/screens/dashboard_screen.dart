import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/app_colors.dart';

/// Dashboard screen for the Midwify app.
/// Displays live statistics, charts, upcoming EDDs, and recent patients
/// for the currently logged-in midwife.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _patients = [];
  String _midwifeName = '';

  // Computed stats
  int _totalPatients = 0;
  int _highRisk = 0;
  int _mediumRisk = 0;
  int _lowRisk = 0;
  int _activePatients = 0;
  double _avgGestWeeks = 0;
  int _trimester1 = 0;
  int _trimester2 = 0;
  int _trimester3 = 0;
  List<Map<String, dynamic>> _upcomingEdds = [];
  List<Map<String, dynamic>> _recentPatients = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get midwife name
      final midwifeDoc = await FirebaseFirestore.instance
          .collection('midwives')
          .doc(user.uid)
          .get();
      if (midwifeDoc.exists) {
        _midwifeName = midwifeDoc.data()?['fullName'] ?? '';
      }

      // Get this midwife's patients
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('midwifeId', isEqualTo: user.uid)
          .get();

      final patients = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Compute stats
      int high = 0, medium = 0, low = 0, active = 0;
      int t1 = 0, t2 = 0, t3 = 0;
      double totalGW = 0;

      for (final p in patients) {
        final risk = p['riskLevel'] ?? 'low';
        if (risk == 'high') high++;
        else if (risk == 'medium') medium++;
        else low++;

        if (p['status'] == 'active') active++;

        final gw = (p['gestationalWeeks'] ?? 0).toInt();
        totalGW += gw;
        if (gw >= 1 && gw <= 12) t1++;
        else if (gw >= 13 && gw <= 26) t2++;
        else if (gw >= 27) t3++;
      }

      // Upcoming EDDs (within 30 days)
      final now = DateTime.now();
      final upcoming = patients.where((p) {
        final edd = p['edd'] as String?;
        if (edd == null || edd.isEmpty) return false;
        try {
          final eddDate = DateTime.parse(edd);
          final diff = eddDate.difference(now).inDays;
          return diff >= 0 && diff <= 30;
        } catch (_) {
          return false;
        }
      }).toList();
      upcoming.sort((a, b) {
        final da = DateTime.parse(a['edd']);
        final db = DateTime.parse(b['edd']);
        return da.compareTo(db);
      });

      // Recent patients (by createdAt timestamp)
      final sorted = [...patients];
      sorted.sort((a, b) {
        final tA = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final tB = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return tB.compareTo(tA);
      });

      setState(() {
        _patients = patients;
        _totalPatients = patients.length;
        _highRisk = high;
        _mediumRisk = medium;
        _lowRisk = low;
        _activePatients = active;
        _avgGestWeeks = patients.isEmpty ? 0 : totalGW / patients.length;
        _trimester1 = t1;
        _trimester2 = t2;
        _trimester3 = t3;
        _upcomingEdds = upcoming.take(5).toList();
        _recentPatients = sorted.take(5).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getFirstName() {
    if (_midwifeName.isEmpty) return 'Midwife';
    return _midwifeName.split(' ').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Midwify',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    _buildGreeting(),
                    const SizedBox(height: 20),

                    // Stat cards 2x2
                    _buildStatGrid(),
                    const SizedBox(height: 20),

                    // Risk Distribution Pie Chart
                    _buildRiskPieChart(),
                    const SizedBox(height: 20),

                    // Trimester Bar Chart
                    _buildTrimesterBarChart(),
                    const SizedBox(height: 20),

                    // Upcoming EDDs
                    if (_upcomingEdds.isNotEmpty) ...[
                      _buildUpcomingEdds(),
                      const SizedBox(height: 20),
                    ],

                    // Recent Patients
                    _buildRecentPatients(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Greeting Header ─────────────────────────────────────────────────
  Widget _buildGreeting() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E7B), Color(0xFFFF4081)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_getGreeting()},',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _getFirstName(),
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.white60),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.people_alt_rounded, size: 14, color: Colors.white60),
              const SizedBox(width: 6),
              Text(
                '$_totalPatients patients',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stat Cards Grid (2×2) ───────────────────────────────────────────
  Widget _buildStatGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                icon: Icons.groups_rounded,
                iconColor: AppColors.info,
                iconBg: AppColors.infoLight,
                label: 'Total Patients',
                value: '$_totalPatients',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStatCard(
                icon: Icons.warning_rounded,
                iconColor: AppColors.danger,
                iconBg: AppColors.dangerLight,
                label: 'High Risk',
                value: '$_highRisk',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.success,
                iconBg: AppColors.successLight,
                label: 'Active',
                value: '$_activePatients',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStatCard(
                icon: Icons.schedule_rounded,
                iconColor: AppColors.warning,
                iconBg: AppColors.warningLight,
                label: 'Avg. Gest. Weeks',
                value: _avgGestWeeks.toStringAsFixed(1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Risk Distribution Pie Chart ─────────────────────────────────────
  Widget _buildRiskPieChart() {
    final total = _lowRisk + _mediumRisk + _highRisk;

    return _ChartCard(
      title: 'Risk Distribution',
      child: total == 0
          ? const Center(
              child: Text('No patients yet',
                  style: TextStyle(color: AppColors.textMuted)))
          : Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: [
                        if (_lowRisk > 0)
                          PieChartSectionData(
                            value: _lowRisk.toDouble(),
                            color: AppColors.success,
                            title: '$_lowRisk',
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            radius: 50,
                          ),
                        if (_mediumRisk > 0)
                          PieChartSectionData(
                            value: _mediumRisk.toDouble(),
                            color: AppColors.warning,
                            title: '$_mediumRisk',
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            radius: 50,
                          ),
                        if (_highRisk > 0)
                          PieChartSectionData(
                            value: _highRisk.toDouble(),
                            color: AppColors.danger,
                            title: '$_highRisk',
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            radius: 50,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(color: AppColors.success, label: 'Low ($_lowRisk)'),
                    const SizedBox(width: 20),
                    _LegendDot(color: AppColors.warning, label: 'Medium ($_mediumRisk)'),
                    const SizedBox(width: 20),
                    _LegendDot(color: AppColors.danger, label: 'High ($_highRisk)'),
                  ],
                ),
              ],
            ),
    );
  }

  // ── Trimester Bar Chart ─────────────────────────────────────────────
  Widget _buildTrimesterBarChart() {
    final maxVal = [_trimester1, _trimester2, _trimester3]
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final maxY = maxVal < 1 ? 5.0 : (maxVal + 2).ceilToDouble();

    return _ChartCard(
      title: 'Patients by Trimester',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final labels = ['1st', '2nd', '3rd'];
                  return BarTooltipItem(
                    '${labels[groupIndex]}: ${rod.toY.toInt()}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const labels = ['1st', '2nd', '3rd'];
                    if (value.toInt() >= 0 && value.toInt() < 3) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[value.toInt()],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 5 ? (maxY / 5).ceilToDouble() : 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.grey200,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              _makeBarGroup(0, _trimester1.toDouble(), AppColors.info),
              _makeBarGroup(1, _trimester2.toDouble(), AppColors.primary),
              _makeBarGroup(2, _trimester3.toDouble(), AppColors.danger),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 32,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  // ── Upcoming EDDs ───────────────────────────────────────────────────
  Widget _buildUpcomingEdds() {
    return _ChartCard(
      title: 'Upcoming Due Dates',
      trailing: Icon(Icons.child_care_rounded, color: AppColors.primary, size: 20),
      child: Column(
        children: _upcomingEdds.map((p) {
          final edd = DateTime.parse(p['edd']);
          final daysLeft = edd.difference(DateTime.now()).inDays;
          final name = p['fullName'] ?? 'Unknown';
          final gw = p['gestationalWeeks'] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: daysLeft <= 7
                        ? AppColors.dangerLight
                        : daysLeft <= 14
                            ? AppColors.warningLight
                            : AppColors.infoLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$daysLeft',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: daysLeft <= 7
                            ? AppColors.danger
                            : daysLeft <= 14
                                ? AppColors.warning
                                : AppColors.info,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${gw}w • EDD: ${edd.day}/${edd.month}/${edd.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: daysLeft <= 7
                        ? AppColors.dangerLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysLeft <= 7 ? 'This week' : '${daysLeft}d left',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          daysLeft <= 7 ? AppColors.danger : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Recent Patients ─────────────────────────────────────────────────
  Widget _buildRecentPatients() {
    return _ChartCard(
      title: 'Recent Patients',
      trailing:
          Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
      child: _recentPatients.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No patients yet',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          : Column(
              children: _recentPatients.map((p) {
                final name = p['fullName'] ?? 'Unknown';
                final risk = p['riskLevel'] ?? 'low';
                final gw = p['gestationalWeeks'] ?? 0;
                final initials = name
                    .split(' ')
                    .map((w) => w.isNotEmpty ? w[0] : '')
                    .take(2)
                    .join()
                    .toUpperCase();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${gw}w gestation',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RiskBadge(riskLevel: risk),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ── Drawer (unchanged) ──────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 20),
                child: Text(
                  'MENU',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey500,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              _DrawerItem(
                icon: Icons.show_chart_rounded,
                label: 'Dashboard',
                isSelected: true,
                onTap: () => Navigator.pop(context),
              ),
              _DrawerItem(
                icon: Icons.groups_outlined,
                label: 'Patients',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/patients');
                },
              ),
              const SizedBox(height: 16),
              _DrawerItem(
                icon: Icons.warning_amber_rounded,
                label: 'New Risk Analysis',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/maternal-health');
                },
              ),
              _DrawerItem(
                icon: Icons.monitor_heart_outlined,
                label: 'Fetal Health Scan',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/fetal-health');
                },
              ),
              _DrawerItem(
                icon: Icons.dashboard_rounded,
                label: 'Fetal Dashboard',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/fetal-health-dashboard');
                },
              ),
              const SizedBox(height: 16),
              _DrawerItem(
                icon: Icons.camera_alt_outlined,
                label: 'AR Photo Capture',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/ar-capture');
                },
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  isHighlighted: true,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Reusable Widgets
// ══════════════════════════════════════════════════════════════════════

/// Card wrapper for chart sections
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _ChartCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Compact stat card for 2x2 grid
class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _MiniStatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Legend dot
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Risk level badge
class _RiskBadge extends StatelessWidget {
  final String riskLevel;

  const _RiskBadge({required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (riskLevel) {
      case 'high':
        bg = AppColors.dangerLight;
        fg = AppColors.danger;
        break;
      case 'medium':
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        break;
      default:
        bg = AppColors.successLight;
        fg = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        riskLevel[0].toUpperCase() + riskLevel.substring(1),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

/// Drawer menu item
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isHighlighted || isSelected
        ? AppColors.primary
        : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
