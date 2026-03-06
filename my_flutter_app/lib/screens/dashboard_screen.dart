import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_colors.dart';

/// Dashboard screen for the Midwify app.
/// Displays dummy statistics cards, a risk distribution donut chart,
/// and a critical risk scores bar chart.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stat cards
            _StatCard(
              icon: Icons.warning_rounded,
              iconColor: AppColors.danger,
              iconBgColor: AppColors.dangerLight,
              title: 'High Risk Cases',
              value: '1',
            ),
            const SizedBox(height: 12),
            _StatCard(
              icon: Icons.groups_rounded,
              iconColor: AppColors.info,
              iconBgColor: AppColors.infoLight,
              title: 'Total Patients',
              value: '2',
            ),
            const SizedBox(height: 12),
            _StatCard(
              icon: Icons.check_circle_rounded,
              iconColor: AppColors.success,
              iconBgColor: AppColors.successLight,
              title: 'Stable Cases',
              value: '1',
            ),

            const SizedBox(height: 24),

            // Risk Distribution Card
            Container(
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
                  const Text(
                    'Risk Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: CustomPaint(
                        painter: _DonutChartPainter(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendItem(color: AppColors.danger, label: 'High (1)'),
                      const SizedBox(width: 16),
                      _LegendItem(color: AppColors.success, label: 'Low (1)'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: _LegendItem(
                        color: AppColors.warning, label: 'Medium (0)'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Critical Risk Scores Card
            Container(
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
                  // Legend dots row
                  Row(
                    children: [
                      _DotLegend(color: AppColors.success, label: 'Low'),
                      const SizedBox(width: 12),
                      _DotLegend(color: AppColors.warning, label: 'Medium'),
                      const SizedBox(width: 12),
                      _DotLegend(color: AppColors.danger, label: 'High'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Critical Risk Scores',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: CustomPaint(
                      size: const Size(double.infinity, 200),
                      painter: _BarChartPainter(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

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
              // MENU header
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

              // Menu items
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
                onTap: () => Navigator.pop(context),
              ),
              _DrawerItem(
                icon: Icons.monitor_heart_outlined,
                label: 'Fetal Health Scan',
                onTap: () => Navigator.pop(context),
              ),

              const SizedBox(height: 16),

              _DrawerItem(
                icon: Icons.camera_alt_outlined,
                label: 'AR Photo Capture',
                onTap: () => Navigator.pop(context),
              ),

              const Spacer(),

              // Settings at the bottom with pink highlight
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

/// A single drawer menu item.
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

/// A single stat card with an icon, title, and value.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rectangle-color legend item for the donut chart.
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Dot legend item for the bar chart.
class _DotLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _DotLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
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

/// Custom painter for the Risk Distribution donut chart.
/// Draws a donut with High (red) and Low (green) segments.
class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 35.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // High Risk segment (50% of circle — red)
    final highPaint = Paint()
      ..color = AppColors.danger
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Low Risk segment (50% of circle — green)
    final lowPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Draw segments: starting from top (-90 degrees)
    // High: 50% = pi radians
    canvas.drawArc(rect, -pi / 2, pi, false, highPaint);
    // Low: 50% = pi radians
    canvas.drawArc(rect, pi / 2, pi, false, lowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the Critical Risk Scores bar chart.
/// Shows dummy bar data matching the screenshot.
class _BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final chartLeft = 40.0;
    final chartBottom = size.height - 20;
    final chartTop = 10.0;
    final chartRight = size.width - 20;
    final chartHeight = chartBottom - chartTop;

    // Axis paint
    final axisPaint = Paint()
      ..color = AppColors.grey200
      ..strokeWidth = 1;

    // Draw horizontal grid lines and Y-axis labels
    final yLabels = ['100', '75', '50', '25', '0'];
    for (int i = 0; i < yLabels.length; i++) {
      final y = chartTop + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(chartRight, y),
        axisPaint,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: yLabels[i],
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chartLeft - tp.width - 6, y - tp.height / 2));
    }

    // Dummy bar data (matching screenshot — one pink/magenta bar)
    final barData = [
      {'value': 85.0, 'color': AppColors.primary},
    ];

    final barWidth = 30.0;
    final startX = chartLeft + (chartRight - chartLeft) / 2 - barWidth / 2;

    for (final bar in barData) {
      final value = bar['value'] as double;
      final color = bar['color'] as Color;
      final barHeight = (value / 100) * chartHeight;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          startX,
          chartBottom - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(4),
      );

      canvas.drawRRect(barRect, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
