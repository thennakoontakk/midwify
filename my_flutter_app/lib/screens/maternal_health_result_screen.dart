import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_colors.dart';
import '../services/maternal_health_service.dart';

class MaternalHealthResultScreen extends StatefulWidget {
  const MaternalHealthResultScreen({super.key});

  @override
  State<MaternalHealthResultScreen> createState() => _MaternalHealthResultScreenState();
}

class _MaternalHealthResultScreenState extends State<MaternalHealthResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;

  Future<void> _saveReport(Map<String, dynamic> args) async {
    setState(() => _isSaving = true);

    try {
      final midwifeId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final assessment = MaternalHealthAssessment(
        patientId: args['patientId'],
        patientName: args['patientName'],
        midwifeId: midwifeId,
        vitals: args['vitals'],
        result: args['result'],
      );

      await MaternalHealthService.saveAssessment(assessment);

      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save report: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get args from navigation
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      return const Scaffold(body: Center(child: Text('No data provided')));
    }

    final MaternalHealthResult result = args['result'];
    final bool isLowRisk = result.predictionScore < 3;

    Color headerColor;
    if (result.predictionScore >= 6) {
      headerColor = const Color(0xFFE63900); // Dark Orange/Red
    } else if (result.predictionScore >= 3) {
      headerColor = AppColors.warning;
    } else {
      headerColor = const Color(0xFF00C853); // Bright Green
    }

    Color bgColor = isLowRisk ? const Color(0xFFF0FFF0) : const Color(0xFFFFF0EC);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Midwify',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Card
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: headerColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: headerColor.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header colored area
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: headerColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'ASSESSMENT COMPLETE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              result.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Score: ${result.predictionScore}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content Area
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ANALYSIS',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          result.xaiReasons.isEmpty
                              ? 'Vitals within normal range.'
                              : 'Detected anomalies in: ${result.xaiReasons.map((r) => r['description']).join(', ')}.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'RECOMMENDATIONS',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        ..._buildRecommendations(result.predictionScore),

                        const SizedBox(height: 32),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (_isSaving || _isSaved) ? null : () => _saveReport(args),
                                icon: _isSaving 
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Icon(_isSaved ? Icons.check : Icons.save_alt),
                                label: Text(_isSaved ? 'Saved' : _isSaving ? 'Saving...' : 'Save Report'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              result.isOffline ? 'AI Model: Local ML Heuristic' : 'AI Model: Cloud ML Pipeline',
                              style: const TextStyle(
                                color: AppColors.grey500,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatTime(DateTime.now()),
                              style: const TextStyle(
                                color: AppColors.grey500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecommendations(int score) {
    List<String> rawRecs;
    if (score >= 6) {
      rawRecs = [
        'Immediate medical intervention required',
        'Schedule urgent OB/GYN consultation',
        'Continuous fetal and maternal monitoring'
      ];
    } else if (score >= 3) {
      rawRecs = [
        'Schedule follow-up within 48 hours',
        'Advise patient on rest and hydration',
        'Monitor blood pressure closely'
      ];
    } else {
      rawRecs = [
        'Maintain routine prenatal care',
        'Educate on warning signs',
        'Continue healthy lifestyle'
      ];
    }

    return rawRecs.map((rec) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.circle, size: 8, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                rec,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatTime(DateTime dt) {
    int hour = dt.hour;
    final int min = dt.minute;
    final int sec = dt.second;
    final String meridian = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    final String hStr = hour.toString();
    final String mStr = min.toString().padLeft(2, '0');
    final String sStr = sec.toString().padLeft(2, '0');
    
    return '$hStr:$mStr:$sStr $meridian';
  }
}
