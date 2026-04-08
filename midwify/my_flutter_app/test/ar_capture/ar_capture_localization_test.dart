import 'package:flutter_test/flutter_test.dart';
import 'package:midwify/screens/ar_capture/ar_capture_localization.dart';
import 'package:midwify/screens/ar_capture/ar_capture_models.dart';

void main() {
  test('localizes known head warnings to Sinhala', () {
    expect(
      ARCaptureLocalization.localizeResultText(
        AppLanguage.si,
        'Face landmarks were incomplete for head screening.',
      ),
      'හිස පරීක්ෂණය සඳහා මුහුණේ ලෑන්ඩ්මාර්ක් ප්‍රමාණවත් නොවීය.',
    );
  });

  test('localizes risk labels and head values to Sinhala', () {
    final strings = ARCaptureLocalization.diagnosis(AppLanguage.si);

    expect(
      ARCaptureLocalization.localizedRiskBandLabel(
        AppLanguage.si,
        RiskBand.review,
        strings,
      ),
      'සමාලෝචන සංඥාව',
    );
    expect(
      ARCaptureLocalization.localizeValue(AppLanguage.si, 'plagiocephaly'),
      'ප්ලැජියෝසෙෆලි',
    );
    expect(
      ARCaptureLocalization.localizedImpactLevel(
        AppLanguage.si,
        RiskBand.lowRisk,
        strings,
      ),
      'අඩු',
    );
  });

  test('localizes posture result text to Sinhala', () {
    expect(
      ARCaptureLocalization.localizeResultText(
        AppLanguage.si,
        'No reliable posture capture was detected. Retake with the infant body centered and both shoulders and hips clearly visible.',
      ),
      'විශ්වාසදායක ඉරියව් ග්‍රහණයක් හඳුනාගත නොහැකි විය. ළදරුවාගේ ශරීරය මධ්‍යයේ පිහිටින ලෙස සහ උරහිස් සහ උකුල් දෙකම පැහැදිලිව පෙනෙන ලෙස නැවත ග්‍රහණය කරන්න.',
    );
  });
}
