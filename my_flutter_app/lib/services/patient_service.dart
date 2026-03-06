import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Data model for a patient (pregnant mother).
class PatientData {
  final String? id;
  final String fullName;
  final int age;
  final String nic;
  final String address;
  final String phone;
  final String emergencyContact;
  final String bloodGroup;
  final double height;
  final double weight;
  final double bmi;
  final int gravidity;
  final int parity;
  final int gestationalWeeks;
  final String edd;
  final String lmp;
  final String riskLevel;
  final String bloodPressure;
  final double hemoglobin;
  final String diabetesStatus;
  final String allergies;
  final String medicalHistory;
  final String notes;
  final String status;
  final String midwifeId;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  PatientData({
    this.id,
    required this.fullName,
    required this.age,
    this.nic = '',
    this.address = '',
    this.phone = '',
    this.emergencyContact = '',
    this.bloodGroup = '',
    this.height = 0,
    this.weight = 0,
    this.bmi = 0,
    this.gravidity = 0,
    this.parity = 0,
    this.gestationalWeeks = 0,
    this.edd = '',
    this.lmp = '',
    this.riskLevel = 'low',
    this.bloodPressure = '',
    this.hemoglobin = 0,
    this.diabetesStatus = 'none',
    this.allergies = '',
    this.medicalHistory = '',
    this.notes = '',
    this.status = 'active',
    this.midwifeId = '',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'age': age,
      'nic': nic,
      'address': address,
      'phone': phone,
      'emergencyContact': emergencyContact,
      'bloodGroup': bloodGroup,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'gravidity': gravidity,
      'parity': parity,
      'gestationalWeeks': gestationalWeeks,
      'edd': edd,
      'lmp': lmp,
      'riskLevel': riskLevel,
      'bloodPressure': bloodPressure,
      'hemoglobin': hemoglobin,
      'diabetesStatus': diabetesStatus,
      'allergies': allergies,
      'medicalHistory': medicalHistory,
      'notes': notes,
      'status': status,
      'midwifeId': midwifeId,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory PatientData.fromMap(String id, Map<String, dynamic> map) {
    return PatientData(
      id: id,
      fullName: map['fullName'] ?? '',
      age: (map['age'] ?? 0).toInt(),
      nic: map['nic'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      emergencyContact: map['emergencyContact'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      height: (map['height'] ?? 0).toDouble(),
      weight: (map['weight'] ?? 0).toDouble(),
      bmi: (map['bmi'] ?? 0).toDouble(),
      gravidity: (map['gravidity'] ?? 0).toInt(),
      parity: (map['parity'] ?? 0).toInt(),
      gestationalWeeks: (map['gestationalWeeks'] ?? 0).toInt(),
      edd: map['edd'] ?? '',
      lmp: map['lmp'] ?? '',
      riskLevel: map['riskLevel'] ?? 'low',
      bloodPressure: map['bloodPressure'] ?? '',
      hemoglobin: (map['hemoglobin'] ?? 0).toDouble(),
      diabetesStatus: map['diabetesStatus'] ?? 'none',
      allergies: map['allergies'] ?? '',
      medicalHistory: map['medicalHistory'] ?? '',
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'active',
      midwifeId: map['midwifeId'] ?? '',
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  /// Returns initials from the full name (e.g. "Sarah Johnson" → "SJ").
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

/// Firestore CRUD service for patient records.
class PatientService {
  static final _collection =
      FirebaseFirestore.instance.collection('patients');

  /// Get current midwife's UID.
  static String get _midwifeId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Add a new patient.
  static Future<String> addPatient(PatientData patient) async {
    final doc = await _collection.add(
      PatientData(
        fullName: patient.fullName,
        age: patient.age,
        nic: patient.nic,
        address: patient.address,
        phone: patient.phone,
        emergencyContact: patient.emergencyContact,
        bloodGroup: patient.bloodGroup,
        height: patient.height,
        weight: patient.weight,
        bmi: patient.bmi,
        gravidity: patient.gravidity,
        parity: patient.parity,
        gestationalWeeks: patient.gestationalWeeks,
        edd: patient.edd,
        lmp: patient.lmp,
        riskLevel: patient.riskLevel,
        bloodPressure: patient.bloodPressure,
        hemoglobin: patient.hemoglobin,
        diabetesStatus: patient.diabetesStatus,
        allergies: patient.allergies,
        medicalHistory: patient.medicalHistory,
        notes: patient.notes,
        status: patient.status,
        midwifeId: _midwifeId,
      ).toMap(),
    );
    return doc.id;
  }

  /// Get all patients for the current midwife.
  static Future<List<PatientData>> getPatients() async {
    final snapshot = await _collection
        .where('midwifeId', isEqualTo: _midwifeId)
        .get();

    final patients = snapshot.docs
        .map((doc) => PatientData.fromMap(doc.id, doc.data()))
        .toList();

    // Sort in-memory (newest first) to avoid needing a composite index
    patients.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return patients;
  }

  /// Get a single patient by ID.
  static Future<PatientData?> getPatient(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return PatientData.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// Update an existing patient.
  static Future<void> updatePatient(String id, PatientData patient) async {
    await _collection.doc(id).update(patient.toMap());
  }

  /// Delete a patient.
  static Future<void> deletePatient(String id) async {
    await _collection.doc(id).delete();
  }
}
