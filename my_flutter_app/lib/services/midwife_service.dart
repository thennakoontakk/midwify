import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Data model for midwife profile information.
class MidwifeData {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String mohArea;
  final String employeeId;
  final Timestamp? createdAt;

  MidwifeData({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.mohArea = '',
    this.employeeId = '',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'mohArea': mohArea,
      'employeeId': employeeId,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory MidwifeData.fromMap(String id, Map<String, dynamic> map) {
    return MidwifeData(
      id: id,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      mohArea: map['mohArea'] ?? '',
      employeeId: map['employeeId'] ?? '',
      createdAt: map['createdAt'] as Timestamp?,
    );
  }
}

/// Service to handle midwife profile data operations.
class MidwifeService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get _currentUid => _auth.currentUser?.uid ?? '';

  /// Fetches the profile data for the currently logged-in midwife.
  static Future<MidwifeData?> getCurrentMidwife() async {
    final uid = _currentUid;
    if (uid.isEmpty) return null;

    final doc = await _db.collection('midwives').doc(uid).get();
    if (!doc.exists) return null;

    return MidwifeData.fromMap(doc.id, doc.data()!);
  }

  /// Updates the profile data for the currently logged-in midwife.
  static Future<void> updateMidwife(MidwifeData data) async {
    final uid = _currentUid;
    if (uid.isEmpty) throw Exception('No authenticated user found');

    await _db.collection('midwives').doc(uid).update(data.toMap());
  }
}
