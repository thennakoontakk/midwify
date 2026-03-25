import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'offline_maternal_model_service.dart';

/// Result of a maternal health prediction.
class MaternalHealthResult {
  final int predictionScore; // 1=Low, 3=Mid, 6=High
  final String label;
  final double confidence;
  final List<Map<String, dynamic>> xaiReasons;
  final bool isOffline;

  MaternalHealthResult({
    required this.predictionScore,
    required this.label,
    required this.confidence,
    required this.xaiReasons,
    required this.isOffline,
  });

  /// Color indication: green/amber/red.
  String get riskColor {
    if (predictionScore >= 6) return 'red';
    if (predictionScore >= 3) return 'amber';
    return 'green';
  }

  Map<String, dynamic> toMap() {
    return {
      'predictionScore': predictionScore,
      'label': label,
      'confidence': confidence,
      'xaiReasons': xaiReasons,
      'isOffline': isOffline,
    };
  }

  factory MaternalHealthResult.fromMap(Map<String, dynamic> map) {
    return MaternalHealthResult(
      predictionScore: (map['predictionScore'] ?? 1).toInt(),
      label: map['label'] ?? 'Low Risk',
      confidence: (map['confidence'] ?? 0).toDouble(),
      xaiReasons: List<Map<String, dynamic>>.from(map['xaiReasons'] ?? []),
      isOffline: map['isOffline'] ?? false,
    );
  }
}

/// Data model for a maternal health assessment record.
class MaternalHealthAssessment {
  final String? id;
  final String patientId;
  final String patientName;
  final String midwifeId;
  final List<double> vitals; // [Age, SystolicBP, DiastolicBP, BS, BodyTemp, HeartRate]
  final MaternalHealthResult result;
  final Timestamp? createdAt;

  MaternalHealthAssessment({
    this.id,
    required this.patientId,
    required this.patientName,
    required this.midwifeId,
    required this.vitals,
    required this.result,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'midwifeId': midwifeId,
      'vitals': vitals,
      'result': result.toMap(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory MaternalHealthAssessment.fromMap(String id, Map<String, dynamic> map) {
    return MaternalHealthAssessment(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      midwifeId: map['midwifeId'] ?? '',
      vitals: List<double>.from((map['vitals'] as List<dynamic>? ?? []).map((e) => (e as num).toDouble())),
      result: MaternalHealthResult.fromMap(map['result'] ?? {}),
      createdAt: map['createdAt'] as Timestamp?,
    );
  }
}

/// High-level maternal health prediction service.
class MaternalHealthService {
  static const String _baseUrl = 'http://192.168.8.176:5000';
  static final _collection = FirebaseFirestore.instance.collection('maternal_assessments');

  static String get _midwifeId => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Predict maternal risk: tries server first, then offline.
  static Future<MaternalHealthResult> predict(List<double> features) async {
    try {
      final result = await _predictOnline(features).timeout(const Duration(seconds: 4));
      return result;
    } catch (_) {
      return _predictOffline(features);
    }
  }

  static Future<MaternalHealthResult> _predictOnline(List<double> features) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/predict-maternal'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'features': features}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return MaternalHealthResult(
        predictionScore: data['prediction'] as int,
        label: data['label'] as String,
        confidence: (data['confidence'] as num).toDouble(),
        xaiReasons: List<Map<String, dynamic>>.from(data['xai_reasons']),
        isOffline: false,
      );
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  static Future<MaternalHealthResult> _predictOffline(List<double> features) async {
    if (!OfflineMaternalModelService.isLoaded) {
      await OfflineMaternalModelService.loadModel();
    }
    final result = OfflineMaternalModelService.predict(features);
    return MaternalHealthResult(
      predictionScore: result['prediction'] as int,
      label: result['label'] as String,
      confidence: (result['confidence'] as num).toDouble(),
      xaiReasons: List<Map<String, dynamic>>.from(result['xai_reasons']),
      isOffline: true,
    );
  }

  /// Save assessment to Firestore
  static Future<void> saveAssessment(MaternalHealthAssessment assessment) async {
    await _collection.add(assessment.toMap());
  }

  /// Get assessments for a patient
  static Future<List<MaternalHealthAssessment>> getAssessmentsForPatient(String patientId) async {
    final snapshot = await _collection
        .where('patientId', isEqualTo: patientId)
        .where('midwifeId', isEqualTo: _midwifeId)
        .get();

    final assessments = snapshot.docs
        .map((doc) => MaternalHealthAssessment.fromMap(doc.id, doc.data()))
        .toList();

    assessments.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return assessments;
  }
}
