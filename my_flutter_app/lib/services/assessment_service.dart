import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Data model for a fetal health assessment (CTG-based prediction).
class FetalHealthAssessment {
  final String? id;
  final String patientId;
  final String patientName;
  final String midwifeId;
  final Map<String, double> ctgParameters;
  final int prediction; // 1=Normal, 2=Suspect, 3=Pathological
  final String label;
  final double confidence;
  final List<Map<String, dynamic>> xaiReasons;
  final bool wasOffline;
  final Timestamp? createdAt;

  FetalHealthAssessment({
    this.id,
    required this.patientId,
    required this.patientName,
    required this.midwifeId,
    required this.ctgParameters,
    required this.prediction,
    required this.label,
    required this.confidence,
    required this.xaiReasons,
    this.wasOffline = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'midwifeId': midwifeId,
      'ctgParameters': ctgParameters,
      'prediction': prediction,
      'label': label,
      'confidence': confidence,
      'xaiReasons': xaiReasons,
      'wasOffline': wasOffline,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory FetalHealthAssessment.fromMap(
      String id, Map<String, dynamic> map) {
    return FetalHealthAssessment(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      midwifeId: map['midwifeId'] ?? '',
      ctgParameters: Map<String, double>.from(
        (map['ctgParameters'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
      prediction: (map['prediction'] ?? 1).toInt(),
      label: map['label'] ?? 'Normal',
      confidence: (map['confidence'] ?? 0).toDouble(),
      xaiReasons: List<Map<String, dynamic>>.from(
        (map['xaiReasons'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      ),
      wasOffline: map['wasOffline'] ?? false,
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  /// Risk color string.
  String get riskColor {
    switch (prediction) {
      case 3:
        return 'high';
      case 2:
        return 'medium';
      default:
        return 'low';
    }
  }
}

/// Firestore service for fetal health assessments.
class AssessmentService {
  static final _collection =
      FirebaseFirestore.instance.collection('fetal_assessments');

  static String get _midwifeId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Save a new assessment.
  static Future<String> saveAssessment(FetalHealthAssessment assessment) async {
    final doc = await _collection.add(
      FetalHealthAssessment(
        patientId: assessment.patientId,
        patientName: assessment.patientName,
        midwifeId: _midwifeId,
        ctgParameters: assessment.ctgParameters,
        prediction: assessment.prediction,
        label: assessment.label,
        confidence: assessment.confidence,
        xaiReasons: assessment.xaiReasons,
        wasOffline: assessment.wasOffline,
      ).toMap(),
    );
    return doc.id;
  }

  /// Get all assessments for a specific patient.
  static Future<List<FetalHealthAssessment>> getAssessmentsForPatient(
      String patientId) async {
    final snapshot = await _collection
        .where('patientId', isEqualTo: patientId)
        .where('midwifeId', isEqualTo: _midwifeId)
        .get();

    final assessments = snapshot.docs
        .map((doc) => FetalHealthAssessment.fromMap(doc.id, doc.data()))
        .toList();

    assessments.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return assessments;
  }

  /// Get all assessments for the current midwife (for dashboard).
  static Future<List<FetalHealthAssessment>> getAllAssessments() async {
    final snapshot = await _collection
        .where('midwifeId', isEqualTo: _midwifeId)
        .get();

    final assessments = snapshot.docs
        .map((doc) => FetalHealthAssessment.fromMap(doc.id, doc.data()))
        .toList();

    assessments.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return assessments;
  }

  /// Get aggregated stats for the dashboard.
  static Future<Map<String, int>> getAggregatedStats() async {
    final assessments = await getAllAssessments();
    int normal = 0, suspect = 0, pathological = 0;
    for (final a in assessments) {
      switch (a.prediction) {
        case 1:
          normal++;
          break;
        case 2:
          suspect++;
          break;
        case 3:
          pathological++;
          break;
      }
    }
    return {
      'total': assessments.length,
      'normal': normal,
      'suspect': suspect,
      'pathological': pathological,
    };
  }
}
