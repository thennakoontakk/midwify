import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:midwify/services/ar_capture/cranial_metrics.dart';

List<Landmark3D> _buildLandmarks({
  required double noseTipX,
  required double noseTipY,
  required double noseTipZ,
  required double glabellaX,
  required double glabellaY,
  required double glabellaZ,
  required double leftForeheadX,
  required double leftForeheadY,
  required double leftForeheadZ,
  required double rightTempleX,
  required double rightTempleY,
  required double rightTempleZ,
  required double rightForeheadX,
  required double rightForeheadY,
  required double rightForeheadZ,
  required double leftTempleX,
  required double leftTempleY,
  required double leftTempleZ,
}) {
  final list = List<Landmark3D>.filled(
    468,
    const Landmark3D(x: 0.5, y: 0.5, z: 0.0),
  );
  list[kLmNoseTip] = Landmark3D(x: noseTipX, y: noseTipY, z: noseTipZ);
  list[kLmGlabella] = Landmark3D(x: glabellaX, y: glabellaY, z: glabellaZ);
  list[kLmLeftForehead] =
      Landmark3D(x: leftForeheadX, y: leftForeheadY, z: leftForeheadZ);
  list[kLmRightTemple] =
      Landmark3D(x: rightTempleX, y: rightTempleY, z: rightTempleZ);
  list[kLmRightForehead] =
      Landmark3D(x: rightForeheadX, y: rightForeheadY, z: rightForeheadZ);
  list[kLmLeftTemple] =
      Landmark3D(x: leftTempleX, y: leftTempleY, z: leftTempleZ);
  return list;
}

List<Landmark3D> _buildBalancedLandmarks() {
  return _buildLandmarks(
    noseTipX: 0.50,
    noseTipY: 0.38,
    noseTipZ: 0.08,
    glabellaX: 0.50,
    glabellaY: 0.20,
    glabellaZ: 0.00,
    leftForeheadX: 0.36,
    leftForeheadY: 0.32,
    leftForeheadZ: 0.00,
    rightTempleX: 0.69,
    rightTempleY: 0.50,
    rightTempleZ: 0.02,
    rightForeheadX: 0.64,
    rightForeheadY: 0.32,
    rightForeheadZ: 0.00,
    leftTempleX: 0.31,
    leftTempleY: 0.50,
    leftTempleZ: 0.02,
  );
}

List<Landmark3D> _translate(
  List<Landmark3D> landmarks, {
  required double dx,
  required double dy,
}) {
  return landmarks
      .map((lm) => Landmark3D(x: lm.x + dx, y: lm.y + dy, z: lm.z))
      .toList();
}

void main() {
  group('distance helpers', () {
    test('dist3D handles basic euclidean distance', () {
      const a = Landmark3D(x: 0, y: 0, z: 0);
      const b = Landmark3D(x: 1, y: 1, z: 1);
      expect(dist3D(a, b), closeTo(math.sqrt(3), 1e-9));
    });

    test('dist2D ignores z differences', () {
      const a = Landmark3D(x: 0, y: 0, z: 0);
      const b = Landmark3D(x: 3, y: 4, z: 9);
      expect(dist2D(a, b), closeTo(5, 1e-9));
    });
  });

  group('camera angle validation', () {
    test('accepts a supported top-down view', () {
      final result = validateCameraAngle(_buildBalancedLandmarks());
      expect(result.isValid, isTrue);
      expect(result.error, isNull);
    });

    test('rejects a flat view', () {
      final landmarks = _buildLandmarks(
        noseTipX: 0.50,
        noseTipY: 0.38,
        noseTipZ: 0.001,
        glabellaX: 0.50,
        glabellaY: 0.20,
        glabellaZ: 0.00,
        leftForeheadX: 0.36,
        leftForeheadY: 0.32,
        leftForeheadZ: 0.00,
        rightTempleX: 0.69,
        rightTempleY: 0.50,
        rightTempleZ: 0.02,
        rightForeheadX: 0.64,
        rightForeheadY: 0.32,
        rightForeheadZ: 0.00,
        leftTempleX: 0.31,
        leftTempleY: 0.50,
        leftTempleZ: 0.02,
      );

      final result = validateCameraAngle(landmarks);
      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
    });
  });

  group('cranial screening', () {
    test('balanced landmarks produce a supported low-risk screen', () {
      final result = analyzeCranialMetrics(_buildBalancedLandmarks());

      expect(result.supportedView, isTrue);
      expect(result.riskBand, CranialRiskBand.lowRisk);
      expect(result.screeningScore, lessThan(35));
      expect(result.cranialIndex, inInclusiveRange(75.0, 85.0));
      expect(result.cvai, lessThan(4.0));
    });

    test('broad cranial proportion triggers review or refer', () {
      final result = analyzeCranialMetrics(
        _buildLandmarks(
          noseTipX: 0.50,
          noseTipY: 0.40,
          noseTipZ: 0.08,
          glabellaX: 0.50,
          glabellaY: 0.20,
          glabellaZ: 0.00,
          leftForeheadX: 0.36,
          leftForeheadY: 0.32,
          leftForeheadZ: 0.00,
          rightTempleX: 0.75,
          rightTempleY: 0.50,
          rightTempleZ: 0.02,
          rightForeheadX: 0.64,
          rightForeheadY: 0.32,
          rightForeheadZ: 0.00,
          leftTempleX: 0.25,
          leftTempleY: 0.50,
          leftTempleZ: 0.02,
        ),
      );

      expect(result.cranialIndex, greaterThan(86.0));
      expect(result.requiresMedicalReview, isTrue);
      expect(result.reasons.join(' '), contains('broad'));
    });

    test('diagonal asymmetry raises the screening band', () {
      final result = analyzeCranialMetrics(
        _buildLandmarks(
          noseTipX: 0.50,
          noseTipY: 0.38,
          noseTipZ: 0.08,
          glabellaX: 0.50,
          glabellaY: 0.20,
          glabellaZ: 0.00,
          leftForeheadX: 0.36,
          leftForeheadY: 0.32,
          leftForeheadZ: 0.00,
          rightTempleX: 0.69,
          rightTempleY: 0.50,
          rightTempleZ: 0.02,
          rightForeheadX: 0.57,
          rightForeheadY: 0.32,
          rightForeheadZ: 0.00,
          leftTempleX: 0.31,
          leftTempleY: 0.50,
          leftTempleZ: 0.02,
        ),
      );

      expect(result.cvai, greaterThan(4.0));
      expect(result.riskBand.index, greaterThanOrEqualTo(CranialRiskBand.review.index));
      expect(result.reasons.join(' '), contains('asymmetry'));
    });

    test('unsupported view is surfaced as a screening warning', () {
      final result = analyzeCranialMetrics(
        _buildLandmarks(
          noseTipX: 0.50,
          noseTipY: 0.38,
          noseTipZ: 0.001,
          glabellaX: 0.50,
          glabellaY: 0.20,
          glabellaZ: 0.00,
          leftForeheadX: 0.36,
          leftForeheadY: 0.32,
          leftForeheadZ: 0.00,
          rightTempleX: 0.69,
          rightTempleY: 0.58,
          rightTempleZ: 0.02,
          rightForeheadX: 0.64,
          rightForeheadY: 0.32,
          rightForeheadZ: 0.00,
          leftTempleX: 0.31,
          leftTempleY: 0.42,
          leftTempleZ: 0.02,
        ),
      );

      expect(result.supportedView, isFalse);
      expect(result.screeningScore, greaterThanOrEqualTo(55));
      expect(result.warnings, isNotEmpty);
      expect(result.cameraAngleError, isNotNull);
    });

    test('metrics stay stable under translation', () {
      final base = analyzeCranialMetrics(_buildBalancedLandmarks());
      final shifted = analyzeCranialMetrics(
        _translate(_buildBalancedLandmarks(), dx: 0.05, dy: 0.07),
      );

      expect(shifted.cranialIndex, closeTo(base.cranialIndex, 0.01));
      expect(shifted.cvai, closeTo(base.cvai, 0.01));
      expect(
        shifted.facialSymmetryOffsetPct,
        closeTo(base.facialSymmetryOffsetPct, 0.01),
      );
    });
  });
}
