import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/ar_capture/ar_capture_models.dart';

class ChildReportData {
  final String? id;
  final String childName;
  final String childAge;
  final String mode; // 'head' or 'posture'
  final ARCaptureResult result;
  final String midwifeId;
  final Timestamp? createdAt;

  ChildReportData({
    this.id,
    required this.childName,
    required this.childAge,
    required this.mode,
    required this.result,
    required this.midwifeId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'childName': childName,
      'childAge': childAge,
      'mode': mode,
      'midwifeId': midwifeId,
      'result': result.toJson(),
      // Use Timestamp.now() instead of serverTimestamp so it can be arrayUnion'd
      'createdAt': createdAt ?? Timestamp.now(), 
    };
  }

  factory ChildReportData.fromMap(String id, Map<String, dynamic> map) {
    // Basic parsing of ARCaptureResult from JSON (simplified)
    final rMap = map['result'] as Map<String, dynamic>? ?? {};
    
    HeadScreeningMetrics? hMetrics;
    if (rMap['headMetrics'] != null) {
      final hm = rMap['headMetrics'];
      hMetrics = HeadScreeningMetrics(
        cranialIndex: (hm['cranialIndex'] ?? 0).toDouble(),
        cranialVaultAsymmetryIndex: (hm['cranialVaultAsymmetryIndex'] ?? 0).toDouble(),
        facialSymmetryOffsetPct: (hm['facialSymmetryOffsetPct'] ?? 0).toDouble(),
        cephalicProportionScore: (hm['cephalicProportionScore'] ?? 0).toDouble(),
        landmarkQuality: (hm['landmarkQuality'] ?? 0).toDouble(),
        topDownAngleDelta: (hm['topDownAngleDelta'] ?? 0).toDouble(),
        classifierAbnormalProbability: (hm['classifierAbnormalProbability'] ?? 0).toDouble(),
        classifierNormalProbability: (hm['classifierNormalProbability'] ?? 0).toDouble(),
        classifierDecision: hm['classifierDecision'] ?? 'Unavailable',
        aiRiskLevel: hm['aiRiskLevel'] ?? 'unknown',
        aiRiskScore: hm['aiRiskScore'] ?? 0,
        headShapeLabel: hm['headShapeLabel'] ?? 'unclassified',
        recommendation: hm['recommendation'] ?? '',
        visualObservations: hm['visualObservations'] ?? '',
      );
    }

    PostureScreeningMetrics? pMetrics;
    if (rMap['postureMetrics'] != null) {
      final pm = rMap['postureMetrics'];
      pMetrics = PostureScreeningMetrics(
        shoulderTiltDeg: (pm['shoulderTiltDeg'] ?? 0).toDouble(),
        hipTiltDeg: (pm['hipTiltDeg'] ?? 0).toDouble(),
        trunkTiltDeg: (pm['trunkTiltDeg'] ?? 0).toDouble(),
        headTiltDeg: (pm['headTiltDeg'] ?? 0).toDouble(),
        midlineOffsetRatio: (pm['midlineOffsetRatio'] ?? 0).toDouble(),
        visibilityQuality: (pm['visibilityQuality'] ?? 0).toDouble(),
        cameraRollDeg: (pm['cameraRollDeg'] ?? 0).toDouble(),
      );
    }

    final riskBandStr = rMap['riskBand'] ?? 'unavailable';
    RiskBand rBand = RiskBand.unavailable;
    if (riskBandStr == 'lowRisk') rBand = RiskBand.lowRisk;
    if (riskBandStr == 'review') rBand = RiskBand.review;
    if (riskBandStr == 'refer') rBand = RiskBand.refer;

    final resultObj = ARCaptureResult(
      isValidImage: rMap['isValidImage'] ?? false,
      supportedView: rMap['supportedView'] ?? false,
      qualityScore: rMap['qualityScore'] ?? 0,
      screeningScore: rMap['screeningScore'] ?? 0,
      riskBand: rBand,
      summary: rMap['summary'] ?? '',
      warnings: (rMap['warnings'] as List<dynamic>?)?.cast<String>() ?? [],
      headMetrics: hMetrics,
      postureMetrics: pMetrics,
    );

    return ChildReportData(
      id: map['id'] ?? id,
      childName: map['childName'] ?? '',
      childAge: map['childAge'] ?? '',
      mode: map['mode'] ?? 'unknown',
      midwifeId: map['midwifeId'] ?? '',
      createdAt: map['createdAt'] as Timestamp?,
      result: resultObj,
    );
  }
}

class ChildReportService {
  static String get _midwifeId => FirebaseAuth.instance.currentUser?.uid ?? '';

  static Future<String> addReport(ChildReportData report) async {
    final uid = _currentUid();
    if (uid.isEmpty) throw Exception('No authenticated user found');
    
    final docRef = FirebaseFirestore.instance.collection('midwives').doc(uid);
    
    final finalReport = ChildReportData(
      id: report.id,
      childName: report.childName,
      childAge: report.childAge,
      mode: report.mode,
      result: report.result,
      midwifeId: uid, 
      createdAt: report.createdAt,
    );

    // CRUCIAL: Use update() instead of set(merge: true) to strictly trigger update rules
    await docRef.update({
      'child_reports': FieldValue.arrayUnion([finalReport.toMap()])
    });

    return finalReport.toMap()['id'] ?? '';
  }

  static Future<List<ChildReportData>> getReports() async {
    final uid = _currentUid();
    if (uid.isEmpty) return [];

    final doc = await FirebaseFirestore.instance.collection('midwives').doc(uid).get();
    if (!doc.exists) return [];

    final data = doc.data();
    if (data == null || !data.containsKey('child_reports')) return [];

    final List<dynamic> rawList = data['child_reports'];
    final reports = rawList.map((e) => ChildReportData.fromMap('extracted_id', e as Map<String, dynamic>)).toList();

    reports.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return reports;
  }

  static String _currentUid() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }
}
