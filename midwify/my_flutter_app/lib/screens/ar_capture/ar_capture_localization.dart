import 'ar_capture_models.dart';

class ARCaptureLocalization {
  static Map<String, String> headCapture(AppLanguage language) {
    const english = {
      'title': 'Head Screening Capture',
      'instruction':
          'Capture an oblique top-down frontal view with the forehead, temples, and nose visible.',
      'instructionSecondary':
          'Primary capture saved. Take a second confirmation image from a nearby supported angle.',
      'processing': 'Running head screening...',
      'processingDetail': 'Reviewing the head image, landmarks, and geometry.',
      'stepPrimary': 'Step 1 of 2',
      'stepSecondary': 'Step 2 of 2',
      'resetPair': 'Start Over',
      'noImage': 'No image captured. Please take a photo first.',
      'savedPrimary':
          'Primary head capture saved. Take a second confirmation image to improve Gemini accuracy.',
      'invalidFallback':
          'No usable head image was detected. Retake with the infant in frame.',
      'errorPrefix': 'Error:',
      'healthNote': 'Health Note',
    };

    const sinhala = {
      'title': 'හිස පරීක්ෂණ ඡායාරූප ග්‍රහණය',
      'instruction':
          'නළල, පැති දෙපස සහ නාසය පෙනෙන පරිදි ඉහළින් සුළු කෝණයකින් ඡායාරූපය ගන්න.',
      'instructionSecondary':
          'ප්‍රාථමික හිස ඡායාරූපය සුරක්ෂිතයි. Gemini නිරවද්‍යතාව වැඩි කිරීමට අසන්න සහාය දක්වන කෝණයකින් දෙවන තහවුරු ඡායාරූපයක් ගන්න.',
      'processing': 'හිස පරීක්ෂණය ක්‍රියාත්මක වෙමින්...',
      'processingDetail':
          'හිස ඡායාරූපය, ලෑන්ඩ්මාර්ක් සහ ජ්‍යාමිතිය සමාලෝචනය කරමින් පවතී.',
      'stepPrimary': 'පියවර 1 / 2',
      'stepSecondary': 'පියවර 2 / 2',
      'resetPair': 'නැවත ආරම්භ කරන්න',
      'noImage': 'ඡායාරූපයක් ග්‍රහණය වී නොමැත. කරුණාකර පළමුව ඡායාරූපයක් ගන්න.',
      'savedPrimary':
          'ප්‍රාථමික හිස ඡායාරූපය සුරක්ෂිතයි. Gemini නිරවද්‍යතාව වැඩි කිරීමට දෙවන තහවුරු ඡායාරූපයක් ගන්න.',
      'invalidFallback':
          'භාවිත කළ හැකි හිස ඡායාරූපයක් හඳුනාගත නොහැකි විය. ළදරුවා පැහැදිලිව පෙනෙන ලෙස නැවත ග්‍රහණය කරන්න.',
      'errorPrefix': 'දෝෂය:',
      'healthNote': 'සෞඛ්‍ය සටහන',
    };

    return language == AppLanguage.si ? sinhala : english;
  }

  static Map<String, String> postureCapture(AppLanguage language) {
    const english = {
      'title': 'Posture Screening Capture',
      'instruction':
          'Capture a centered frontal or top-down body view with the shoulders and hips visible.',
      'processing': 'Running posture screening...',
      'processingDetail':
          'Reviewing body keypoints, alignment, and posture geometry.',
      'singleStep': 'Single capture flow',
      'healthNote': 'Positioning Note',
      'positioningHint':
          'Keep both shoulders and hips inside the guide before capturing.',
      'noImage': 'No image captured. Please take a photo first.',
      'invalidFallback':
          'No usable posture image was detected. Retake with the infant body fully visible.',
      'errorPrefix': 'Error:',
    };

    const sinhala = {
      'title': 'ඉරියව් පරීක්ෂණ ඡායාරූප ග්‍රහණය',
      'instruction':
          'උරහිස් සහ උකුල් පැහැදිලිව පෙනෙන ලෙස මධ්‍යගත ඉදිරිපස හෝ ඉහළින් ගත් සම්පූර්ණ ශරීර දර්ශනයක් ගන්න.',
      'processing': 'ඉරියව් පරීක්ෂණය ක්‍රියාත්මක වෙමින්...',
      'processingDetail':
          'ශරීර keypoints, පෙළගැස්ම සහ ඉරියව් ජ්‍යාමිතිය සමාලෝචනය කරමින් පවතී.',
      'singleStep': 'එක් ග්‍රහණ ප්‍රවාහය',
      'healthNote': 'ස්ථානගත කිරීමේ සටහන',
      'positioningHint':
          'ග්‍රහණයට පෙර උරහිස් සහ උකුල් දෙකම මාර්ගෝපදේශය තුළ තබන්න.',
      'noImage': 'ඡායාරූපයක් ග්‍රහණය වී නොමැත. කරුණාකර පළමුව ඡායාරූපයක් ගන්න.',
      'invalidFallback':
          'භාවිත කළ හැකි ඉරියව් ඡායාරූපයක් හඳුනාගත නොහැකි විය. ළදරුවාගේ සම්පූර්ණ ශරීරය පැහැදිලිව පෙනෙන ලෙස නැවත ගන්න.',
      'errorPrefix': 'දෝෂය:',
    };

    return language == AppLanguage.si ? sinhala : english;
  }

  static List<String> postureProcessingThoughts(AppLanguage language) {
    const english = [
      'Keep the baby centered so both shoulders and hips stay inside the guide.',
      'A straight overhead capture reduces false tilt from camera angle.',
      'If the baby is moving, retaking the image is better than trusting a blurred screen.',
      'A firm, flat surface makes shoulder and hip alignment easier to review.',
      'Clinical concern matters more than any app score if posture looks persistently uneven.',
    ];

    const sinhala = [
      'උරහිස් සහ උකුල් දෙකම මාර්ගෝපදේශය තුළ රැඳෙන ලෙස ළදරුවා මධ්‍යයේ තබන්න.',
      'සෘජු ඉහළ ග්‍රහණයක් කැමරා කෝණයෙන් ඇතිවන වැරදි ඇලවීම අඩු කරයි.',
      'ළදරුවා චලනය වෙමින් සිටී නම්, අඳුරු රූපයක් මත විශ්වාසය තැබීමට වඩා නැවත ග්‍රහණය කිරීම හොඳය.',
      'ස්ථිර, සමතලා මතුපිටක් උරහිස් සහ උකුල් පෙළගැස්ම සමාලෝචනය කිරීමට පහසු කරයි.',
      'ඉරියව්ය දිගටම අසම බව පෙනේ නම්, යෙදුමේ ලකුණකට වඩා වෛද්‍ය සැලකිල්ල වැදගත් වේ.',
    ];

    return language == AppLanguage.si ? sinhala : english;
  }

  static Map<String, String> geometricTool(AppLanguage language) {
    const english = {
      'title': 'Posture Geometric Review',
      'subtitle':
          'Review the captured posture image with the detected shoulder, hip, trunk, and head guides before finalizing the result.',
      'status': 'Review Status',
      'pending': 'Pending Review',
      'confirmed': 'Review Confirmed',
      'capturePreview': 'Captured Image Preview',
      'captureMissing':
          'The captured posture image is no longer available. Retake the posture scan before handover.',
      'overlayHint':
          'Overlay lines are drawn from the detected body landmarks in this capture.',
      'summaryTitle': 'Review Summary',
      'riskBand': 'Signal Band',
      'screeningScore': 'Research Score',
      'qualityScore': 'Capture Quality',
      'visibility': 'Visibility Quality',
      'shoulderLine': 'Shoulder Line',
      'hipLine': 'Hip Line',
      'trunkLine': 'Trunk Midline',
      'headLine': 'Head Tilt',
      'confirm': 'Confirm Geometric Review',
      'retake': 'Retake Capture',
      'note': 'Geometric review confirmed against the captured body landmarks.',
      'source': 'Landmark Overlay',
      'percent': '%',
      'degrees': 'deg',
    };

    const sinhala = {
      'title': 'ඉරියව් ජ්‍යාමිතික සමාලෝචනය',
      'subtitle':
          'ප්‍රතිඵලය අවසන් කිරීමට පෙර හඳුනාගත් උරහිස්, උකුල්, ශරීර මැද සහ හිස මාර්ගෝපදේශ සමඟ ගත් ඉරියව් ඡායාරූපය සමාලෝචනය කරන්න.',
      'status': 'සමාලෝචන තත්ත්වය',
      'pending': 'සමාලෝචනය බලාපොරොත්තුවෙන්',
      'confirmed': 'සමාලෝචනය තහවුරුයි',
      'capturePreview': 'ග්‍රහණය කළ ඡායාරූප පෙරදසුන',
      'captureMissing':
          'ග්‍රහණය කළ ඉරියව් ඡායාරූපය තවදුරටත් ලබාගත නොහැක. භාරදීමට පෙර ඉරියව් ස්කෑනය නැවත ගන්න.',
      'overlayHint':
          'Overlay රේඛා මෙම ග්‍රහණයේ හඳුනාගත් ශරීර ලෑන්ඩ්මාර්ක් මත ඇඳේ.',
      'summaryTitle': 'සමාලෝචන සාරාංශය',
      'riskBand': 'සංඥා කාණ්ඩය',
      'screeningScore': 'පර්යේෂණ ලකුණු',
      'qualityScore': 'ග්‍රහණ ගුණාත්මකභාවය',
      'visibility': 'පෙනී සිටීමේ ගුණාත්මකභාවය',
      'shoulderLine': 'උරහිස් රේඛාව',
      'hipLine': 'උකුල් රේඛාව',
      'trunkLine': 'ශරීර මැද රේඛාව',
      'headLine': 'හිස ඇලවීම',
      'confirm': 'ජ්‍යාමිතික සමාලෝචනය තහවුරු කරන්න',
      'retake': 'ග්‍රහණය නැවත ගන්න',
      'note':
          'ග්‍රහණය කළ ශරීර ලෑන්ඩ්මාර්ක් සමඟ ජ්‍යාමිතික සමාලෝචනය තහවුරු කරන ලදී.',
      'source': 'ලෑන්ඩ්මාර්ක් Overlay',
      'percent': '%',
      'degrees': 'අංශක',
    };

    return language == AppLanguage.si ? sinhala : english;
  }

  static List<String> headProcessingThoughts(AppLanguage language) {
    const english = [
      'Lighting from the front helps the scan read the forehead and temples.',
      'A retake from the supported angle is better than relying on a weak image.',
      'Tummy time while awake can reduce constant pressure on one side of the head.',
      'If feeding difficulty or unusual irritability is present, clinical review matters more than any app score.',
      'Clear forehead, temple, and nose visibility improves head-shape measurement quality.',
    ];

    const sinhala = [
      'ඉදිරිපසින් ලැබෙන ආලෝකය නළල සහ පැති දෙපස නිරවද්‍යව කියවීමට උපකාරී වේ.',
      'දුර්වල ඡායාරූපයක් මත විශ්වාසය තැබීමකට වඩා සහාය දක්වන කෝණයකින් නැවත ග්‍රහණය කිරීම හොඳය.',
      'ළදරුවා අවදියෙන් සිටියදී tummy time ලබාදීම හිසෙහි එක් පැත්තකට නිරන්තර පීඩනය අඩු කිරීමට උපකාරී විය හැක.',
      'පෝෂණ අපහසුතා හෝ අසාමාන්‍ය කලබලකාරී බව පවතින්නේ නම්, යෙදුමේ ලකුණකට වඩා වෛද්‍ය සමාලෝචනය වැදගත් වේ.',
      'නළල, පැති දෙපස සහ නාසය පැහැදිලිව පෙනීම හිස හැඩ මිනුම් ගුණාත්මකභාවය වැඩි කරයි.',
    ];

    return language == AppLanguage.si ? sinhala : english;
  }

  static Map<String, String> diagnosis(AppLanguage language) {
    const english = {
      'title': 'Research Results',
      'headModel': 'Head Research Pipeline',
      'postureModel': 'Posture Research Pipeline',
      'captureQuality': 'Capture Quality',
      'screeningScore': 'Research Score',
      'riskBand': 'Signal Band',
      'impactLevel': 'Research Signal',
      'supportedView': 'Supported View',
      'yes': 'Yes',
      'no': 'No',
      'summary': 'Summary',
      'warnings': 'Warnings',
      'headMetrics': 'Head Metrics',
      'postureMetrics': 'Posture Metrics',
      'researchDisclaimer':
          'Experimental research output only. Not validated for diagnosis, referral, or treatment decisions.',
      'landmarkSource': 'Landmark Source',
      'retake': 'Retake Photo',
      'finish': 'Back to Dashboard',
      'tool': 'Open Geometric Review',
      'invalid':
          'No usable infant image was detected for screening. Retake the photo with the infant clearly visible.',
      'invalidTitle': 'Screening Unavailable',
      'ci': 'Cranial Index',
      'cvai': 'Cranial Vault Asymmetry Index',
      'symmetry': 'Facial Symmetry Offset',
      'headQuality': 'Landmark Quality',
      'cephalicProportion': 'Cephalic Proportion Score',
      'angleDelta': 'Top-Down Angle Delta',
      'imageClassifier': 'Image Classifier',
      'abnormalProb': 'Abnormal Probability',
      'normalProb': 'Normal Probability',
      'aiDetails': 'AI Details',
      'headShape': 'Head Shape',
      'aiRiskLevel': 'AI Risk Level',
      'aiConfidence': 'AI Confidence',
      'aiUrgency': 'AI Urgency',
      'visualObservation': 'Visual Observation',
      'recommendationTitle': 'Recommendation',
      'keyFindings': 'Key Findings',
      'aiProvider': 'AI Provider',
      'inputImages': 'Input Images',
      'totalTokens': 'Total Tokens',
      'promptTokens': 'Prompt Tokens',
      'fallbackMode': 'Fallback Mode',
      'cephalicRisk': 'Cephalic Index Risk',
      'asymmetryRisk': 'Asymmetry Risk',
      'orbitalRisk': 'Orbital Symmetry Risk',
      'aiError': 'AI Error',
      'shoulderTilt': 'Shoulder Tilt',
      'hipTilt': 'Hip Tilt',
      'trunkTilt': 'Trunk Tilt',
      'headTilt': 'Head Tilt',
      'midlineOffset': 'Midline Offset',
      'visibility': 'Visibility Quality',
      'cameraRoll': 'Camera Roll',
      'geometricReview': 'Geometric Review',
      'reviewStatus': 'Review Status',
      'reviewPending': 'Pending',
      'reviewConfirmed': 'Confirmed',
      'reviewNote': 'Review Note',
      'percent': '%',
      'degrees': 'deg',
      'ratio': 'ratio',
      'unsupportedCapture':
          'The capture did not match the supported screening view.',
      'impactUnsupported':
          'The capture quality was not strong enough to estimate a reliable research signal. Retake the image before relying on this output.',
      'impactHeadLow': 'Low head-shape research signal in this capture.',
      'impactHeadReview':
          'Moderate head-shape research signal. Repeat capture and review carefully.',
      'impactHeadRefer':
          'High-priority head research signal. This may justify further study, not a diagnosis.',
      'impactHeadUnavailable':
          'No head research signal is available for this capture.',
      'impactPostureLow': 'Low posture research signal in this capture.',
      'impactPostureReview':
          'Moderate posture research signal. Repeat capture and review carefully.',
      'impactPostureRefer':
          'High-priority posture research signal. This may justify further study, not a diagnosis.',
      'impactPostureUnavailable':
          'No posture research signal is available for this capture.',
      'riskUnavailable': 'Unavailable',
      'riskLowSignal': 'Low Signal',
      'riskReviewSignal': 'Review Signal',
      'riskHighPriority': 'High Priority',
      'levelUnavailable': 'Unavailable',
      'levelLow': 'Low',
      'levelMedium': 'Medium',
      'levelHigh': 'High',
    };

    const sinhala = {
      'title': 'පර්යේෂණ ප්‍රතිඵල',
      'headModel': 'හිස පර්යේෂණ පයිප්ලයිනය',
      'postureModel': 'ඉරියව් පර්යේෂණ පයිප්ලයිනය',
      'captureQuality': 'ග්‍රහණ ගුණාත්මකභාවය',
      'screeningScore': 'පර්යේෂණ ලකුණු',
      'riskBand': 'සංඥා කාණ්ඩය',
      'impactLevel': 'පර්යේෂණ සංඥාව',
      'supportedView': 'සහාය දක්වන කෝණය',
      'yes': 'ඔව්',
      'no': 'නැත',
      'summary': 'සාරාංශය',
      'warnings': 'අවවාද',
      'headMetrics': 'හිස මිනුම්',
      'postureMetrics': 'ඉරියව් මිනුම්',
      'researchDisclaimer':
          'මෙය පර්යේෂණ ප්‍රතිදානයක් පමණි. රෝග නිශ්චය, යොමු කිරීම හෝ ප්‍රතිකාර තීරණ සඳහා මෙය තහවුරු කර නොමැත.',
      'landmarkSource': 'ලෑන්ඩ්මාර්ක් මූලාශ්‍රය',
      'retake': 'ඡායාරූපය නැවත ගන්න',
      'finish': 'පාලක පුවරුවට යන්න',
      'tool': 'ජ්‍යාමිතික සමාලෝචනය විවෘත කරන්න',
      'invalid':
          'පරීක්ෂණයට භාවිත කළ හැකි ළදරු ඡායාරූපයක් හඳුනාගත නොහැකි විය. ළදරුවා පැහැදිලිව පෙනෙන ලෙස නැවත ඡායාරූපය ගන්න.',
      'invalidTitle': 'පරීක්ෂාව නොලැබේ',
      'ci': 'ක්‍රේනියල් දර්ශකය',
      'cvai': 'ක්‍රේනියල් වෝල්ට් අසමමිතිය දර්ශකය',
      'symmetry': 'මුහුණු සමමිතික වෙනස',
      'headQuality': 'ලෑන්ඩ්මාර්ක් ගුණාත්මකභාවය',
      'cephalicProportion': 'සෙෆැලික් අනුපාත ලකුණු',
      'angleDelta': 'ඉහළ කෝණ වෙනස',
      'imageClassifier': 'රූප වර්ගීකරණය',
      'abnormalProb': 'අසාමාන්‍ය සම්භාවිතාව',
      'normalProb': 'සාමාන්‍ය සම්භාවිතාව',
      'aiDetails': 'AI විස්තර',
      'headShape': 'හිස හැඩය',
      'aiRiskLevel': 'AI අවදානම් මට්ටම',
      'aiConfidence': 'AI විශ්වාස මට්ටම',
      'aiUrgency': 'AI ප්‍රමුඛතාව',
      'visualObservation': 'දෘශ්‍ය නිරීක්ෂණය',
      'recommendationTitle': 'නිර්දේශය',
      'keyFindings': 'ප්‍රධාන නිරීක්ෂණ',
      'aiProvider': 'AI සැපයුම්කරු',
      'inputImages': 'ආදාන රූප',
      'totalTokens': 'මුළු ටෝකන්',
      'promptTokens': 'ප්‍රොම්ප්ට් ටෝකන්',
      'fallbackMode': 'විකල්ප ක්‍රමය',
      'cephalicRisk': 'සෙෆැලික් දර්ශක අවදානම',
      'asymmetryRisk': 'අසමමිතිය අවදානම',
      'orbitalRisk': 'ඕබිටල් සමමිතික අවදානම',
      'aiError': 'AI දෝෂය',
      'shoulderTilt': 'කන්ධ ඇලවීම',
      'hipTilt': 'පිටුබඩ ඇලවීම',
      'trunkTilt': 'ශරීර මැද ඇලවීම',
      'headTilt': 'හිස ඇලවීම',
      'midlineOffset': 'මැද රේඛා වෙනස',
      'visibility': 'පෙනී සිටීමේ ගුණාත්මකභාවය',
      'cameraRoll': 'කැමරා රෝල්',
      'geometricReview': 'ජ්‍යාමිතික සමාලෝචනය',
      'reviewStatus': 'සමාලෝචන තත්ත්වය',
      'reviewPending': 'බලාපොරොත්තුවෙන්',
      'reviewConfirmed': 'තහවුරු',
      'reviewNote': 'සමාලෝචන සටහන',
      'percent': '%',
      'degrees': 'අංශක',
      'ratio': 'අනුපාතය',
      'unsupportedCapture': 'මෙම ග්‍රහණය සහාය දක්වන පරීක්ෂණ කෝණයට නොගැළපුණි.',
      'impactUnsupported':
          'විශ්වාසදායක පර්යේෂණ සංඥාවක් තක්සේරු කිරීමට මෙම ග්‍රහණයේ ගුණාත්මකභාවය ප්‍රමාණවත් නොවීය. මෙම ප්‍රතිදානය මත විශ්වාසය තැබීමට පෙර ඡායාරූපය නැවත ගන්න.',
      'impactHeadLow': 'මෙම ග්‍රහණයේ හිස හැඩය සඳහා අඩු පර්යේෂණ සංඥාවක් පෙනේ.',
      'impactHeadReview':
          'මධ්‍යම මට්ටමේ හිස හැඩ පර්යේෂණ සංඥාවක් පෙනේ. නැවත ග්‍රහණය කර සැලකිලිමත්ව සමාලෝචනය කරන්න.',
      'impactHeadRefer':
          'ඉහළ ප්‍රමුඛතාවක් සහිත හිස පර්යේෂණ සංඥාවක් පෙනේ. මෙය රෝග නිශ්චය නොව වැඩිදුර අධ්‍යයනයකට හේතුවක් විය හැක.',
      'impactHeadUnavailable': 'මෙම ග්‍රහණය සඳහා හිස පර්යේෂණ සංඥාවක් නොලැබේ.',
      'impactPostureLow': 'මෙම ග්‍රහණයේ ඉරියව් සඳහා අඩු පර්යේෂණ සංඥාවක් පෙනේ.',
      'impactPostureReview':
          'මධ්‍යම මට්ටමේ ඉරියව් පර්යේෂණ සංඥාවක් පෙනේ. නැවත ග්‍රහණය කර සැලකිලිමත්ව සමාලෝචනය කරන්න.',
      'impactPostureRefer':
          'ඉහළ ප්‍රමුඛතාවක් සහිත ඉරියව් පර්යේෂණ සංඥාවක් පෙනේ. මෙය රෝග නිශ්චය නොව වැඩිදුර අධ්‍යයනයකට හේතුවක් විය හැක.',
      'impactPostureUnavailable':
          'මෙම ග්‍රහණය සඳහා ඉරියව් පර්යේෂණ සංඥාවක් නොලැබේ.',
      'riskUnavailable': 'නොලැබේ',
      'riskLowSignal': 'අඩු සංඥාව',
      'riskReviewSignal': 'සමාලෝචන සංඥාව',
      'riskHighPriority': 'ඉහළ ප්‍රමුඛතාව',
      'levelUnavailable': 'නොලැබේ',
      'levelLow': 'අඩු',
      'levelMedium': 'මධ්‍යම',
      'levelHigh': 'ඉහළ',
    };

    return language == AppLanguage.si ? sinhala : english;
  }

  static String localizedRiskBandLabel(
    AppLanguage language,
    RiskBand band,
    Map<String, String> t,
  ) {
    switch (band) {
      case RiskBand.lowRisk:
        return t['riskLowSignal']!;
      case RiskBand.review:
        return t['riskReviewSignal']!;
      case RiskBand.refer:
        return t['riskHighPriority']!;
      case RiskBand.unavailable:
        return t['riskUnavailable']!;
    }
  }

  static String localizedImpactLevel(
    AppLanguage language,
    RiskBand band,
    Map<String, String> t,
  ) {
    switch (band) {
      case RiskBand.lowRisk:
        return t['levelLow']!;
      case RiskBand.review:
        return t['levelMedium']!;
      case RiskBand.refer:
        return t['levelHigh']!;
      case RiskBand.unavailable:
        return t['levelUnavailable']!;
    }
  }

  static String impactDescription(
    AppLanguage language,
    AppMode mode,
    ARCaptureResult result,
    Map<String, String> t,
  ) {
    if (!result.supportedView) {
      return t['impactUnsupported']!;
    }

    if (mode == AppMode.head) {
      switch (result.riskBand) {
        case RiskBand.lowRisk:
          return t['impactHeadLow']!;
        case RiskBand.review:
          return t['impactHeadReview']!;
        case RiskBand.refer:
          return t['impactHeadRefer']!;
        case RiskBand.unavailable:
          return t['impactHeadUnavailable']!;
      }
    }

    switch (result.riskBand) {
      case RiskBand.lowRisk:
        return t['impactPostureLow']!;
      case RiskBand.review:
        return t['impactPostureReview']!;
      case RiskBand.refer:
        return t['impactPostureRefer']!;
      case RiskBand.unavailable:
        return t['impactPostureUnavailable']!;
    }
  }

  static String localizeResultText(AppLanguage language, String text) {
    if (language == AppLanguage.en || text.isEmpty) {
      return text;
    }

    final exact = _sinhalaResultText[text];
    if (exact != null) {
      return exact;
    }

    if (text.startsWith('Visual observation: ')) {
      return 'දෘශ්‍ය නිරීක්ෂණය: ${text.substring('Visual observation: '.length)}';
    }

    if (text.startsWith('Recommendation: ')) {
      return 'නිර්දේශය: ${text.substring('Recommendation: '.length)}';
    }

    if (text.startsWith('Gemini AI error: ')) {
      return 'Gemini AI දෝෂය: ${text.substring('Gemini AI error: '.length)}';
    }

    if (text.startsWith('Research-only pipeline: ')) {
      return 'පර්යේෂණ පයිප්ලයිනය පමණි: ${text.substring('Research-only pipeline: '.length)}';
    }

    final comparedMatch = RegExp(
      r'^Gemini compared (\d+) head images for this result\.$',
    ).firstMatch(text);
    if (comparedMatch != null) {
      return 'මෙම ප්‍රතිඵලය සඳහා Gemini හිස ඡායාරූප ${comparedMatch.group(1)} ක් සංසන්දනය කළේය.';
    }

    final confidenceMatch = RegExp(
      r'^AI confidence: ([^.]+)\. Urgency: ([^.]+)\.$',
    ).firstMatch(text);
    if (confidenceMatch != null) {
      final confidence = localizeValue(language, confidenceMatch.group(1)!);
      final urgency = localizeValue(language, confidenceMatch.group(2)!);
      return 'AI විශ්වාස මට්ටම: $confidence. ප්‍රමුඛතාව: $urgency.';
    }

    if (text.startsWith('Head image was downscaled to ')) {
      return 'දේශීය මතක පීඩනය අඩු කිරීමට විශ්ලේෂණයට පෙර හිස ඡායාරූපය ප්‍රමාණය අඩු කරන ලදී.';
    }

    if (text.startsWith('Secondary head image was downscaled to ')) {
      return 'Gemini විශ්ලේෂණයට පෙර දෙවන හිස ඡායාරූපයේ ප්‍රමාණය අඩු කරන ලදී.';
    }

    return localizeValue(language, text);
  }

  static String localizeValue(AppLanguage language, String value) {
    if (language == AppLanguage.en || value.isEmpty) {
      return value;
    }

    final direct = _sinhalaValueMap[value];
    if (direct != null) {
      return direct;
    }

    final trimmed = value.trim();
    final lower = trimmed.toLowerCase();
    return _sinhalaValueMap[lower] ?? value;
  }

  static const Map<String, String> _sinhalaValueMap = {
    'low': 'අඩු',
    'medium': 'මධ්‍යම',
    'high': 'ඉහළ',
    'moderate': 'මධ්‍යම',
    'pending': 'බලාපොරොත්තුවෙන්',
    'confirmed': 'තහවුරු',
    'routine': 'සාමාන්‍ය',
    'soon': 'ඉක්මනින්',
    'urgent': 'හදිසි',
    'normal': 'සාමාන්‍ය',
    'mild': 'මෘදු',
    'significant': 'සැලකිය යුතු',
    'unclassified': 'වර්ගීකරණය නොකළ',
    'geometry_fallback': 'ජ්‍යාමිතික විකල්ප ක්‍රමය',
    'plagiocephaly': 'ප්ලැජියෝසෙෆලි',
    'scaphocephaly': 'ස්කැෆෝසෙෆලි',
    'trigonocephaly': 'ට්‍රයිගොනොසෙෆලි',
    'brachycephaly': 'බ්‍රැකීසෙෆලි',
    'fallback face landmarks': 'විකල්ප මුහුණේ ලෑන්ඩ්මාර්ක්',
  };

  static const Map<String, String> _sinhalaResultText = {
    'No image path was provided for screening.':
        'පරීක්ෂණය සඳහා ඡායාරූප මාර්ගය ලබා දී නොමැත.',
    'AR screening is unavailable on web.':
        'වෙබ් වේදිකාවේ AR පරීක්ෂණය ලබාගත නොහැක.',
    'The captured image file could not be found.':
        'ග්‍රහණය කළ ඡායාරූප ගොනුව සොයාගත නොහැකි විය.',
    'The captured image could not be decoded for screening.':
        'ග්‍රහණය කළ ඡායාරූපය පරීක්ෂණය සඳහා කියවීමට නොහැකි විය.',
    'Screening failed while processing the captured image.':
        'ග්‍රහණය කළ ඡායාරූපය සකසන අතරතුර පරීක්ෂණය අසාර්ථක විය.',
    'Head screening is unavailable on web.':
        'වෙබ් වේදිකාවේ හිස පරීක්ෂණය ලබාගත නොහැක.',
    'No image file was found for head screening.':
        'හිස පරීක්ෂණය සඳහා ඡායාරූප ගොනුව සොයාගත නොහැකි විය.',
    'No infant face landmarks were detected.':
        'ළදරුවාගේ මුහුණේ ලෑන්ඩ්මාර්ක් හඳුනාගත නොහැකි විය.',
    'Retake from the supported oblique top-down frontal view.':
        'සහාය දක්වන ඉහළින්-ඉදිරි කෝණයෙන් නැවත ඡායාරූපය ගන්න.',
    'The captured head image could not be decoded.':
        'ග්‍රහණය කළ හිස ඡායාරූපය විශ්ලේෂණය සඳහා කියවීමට නොහැකි විය.',
    'Retake the image and try again.': 'ඡායාරූපය නැවත ගෙන නැවත උත්සාහ කරන්න.',
    'Face landmarks were incomplete for head screening.':
        'හිස පරීක්ෂණය සඳහා මුහුණේ ලෑන්ඩ්මාර්ක් ප්‍රමාණවත් නොවීය.',
    'Ensure the forehead, temples, and nose are all visible.':
        'නළල, දෙපස සහ නාසය සියල්ල පැහැදිලිව පෙනෙන බව තහවුරු කරන්න.',
    'No clear baby head was detected in this image. Avoid background objects and retake with the head filling more of the guide.':
        'මෙම ඡායාරූපයේ ළදරුවාගේ හිස පැහැදිලිව හඳුනාගත නොහැකි විය. පසුබිම් වස්තූන් වළක්වා, මාර්ගෝපදේශය වැඩි ප්‍රමාණයකින් හිස පිරෙන පරිදි නැවත ග්‍රහණය කරන්න.',
    'Keep the baby\'s forehead, temples, and nose clearly visible and reduce background clutter.':
        'ළදරුවාගේ නළල, දෙපස සහ නාසය පැහැදිලිව පෙනෙන ලෙස තබා පසුබිම් අවුල් අවම කරන්න.',
    'Head screening failed before the analysis could complete.':
        'විශ්ලේෂණය අවසන් වීමට පෙර හිස පරීක්ෂණය අසාර්ථක විය.',
    'Detected landmarks were too sparse to confirm a baby head.':
        'ළදරු හිසක් බව තහවුරු කිරීමට හඳුනාගත් ලෑන්ඩ්මාර්ක් ප්‍රමාණවත් නොවීය.',
    'The detected face region is too small or too weak for reliable head screening.':
        'හඳුනාගත් මුහුණු ප්‍රදේශය විශ්වාසදායක හිස පරීක්ෂණයකට ඉතා කුඩා හෝ ඉතා දුර්වලය.',
    'The head is clipped by the image edges. Retake with the full head inside the guide.':
        'ඡායාරූපයේ අගවලින් හිස කපා ඇත. සම්පූර්ණ හිස මාර්ගෝපදේශය තුළ සිටින ලෙස නැවත ග්‍රහණය කරන්න.',
    'Head is rotated relative to the camera. Retake from the supported oblique top-down view.':
        'කැමරාවට සාපේක්ෂව හිස හැරී ඇත. සහාය දක්වන ඉහළින්-ඉදිරි කෝණයෙන් නැවත ග්‍රහණය කරන්න.',
    'Forehead and temple visibility are imbalanced. Ensure both sides are clearly visible.':
        'නළල සහ දෙපස පෙනී සිටීම සමාන නොවේ. දෙපසම පැහැදිලිව පෙනෙන බව තහවුරු කරන්න.',
    'Cranial proportion is elongated relative to the temple width.':
        'දෙපස පළලට සාපේක්ෂව හිස අනුපාතය දිගු වී ඇත.',
    'Cranial proportion is broad relative to the glabella-nose distance.':
        'glabella-නාස දුරට සාපේක්ෂව හිස අනුපාතය පුළුල් වේ.',
    'Forehead-to-temple diagonal asymmetry is elevated.':
        'නළලෙන් දෙපසට ඇති අඩිඅසමමිතිය ඉහළයි.',
    'Mild frontal asymmetry is present across diagonal landmarks.':
        'අඩි ලෑන්ඩ්මාර්ක් හරහා මෘදු ඉදිරිපස අසමමිතියක් පවතී.',
    'Capture quality is insufficient for a reliable low-risk screen.':
        'විශ්වාසදායක අඩු-අවදානම් පරීක්ෂණයකට මෙම ග්‍රහණයේ ගුණාත්මකභාවය ප්‍රමාණවත් නොවේ.',
    'Unsupported head capture view. Retake before relying on the screen.':
        'මෙම හිස ග්‍රහණ කෝණයට සහාය නොදක්වයි. මෙම ප්‍රතිඵලය මත විශ්වාසය තැබීමට පෙර නැවත ග්‍රහණය කරන්න.',
    'Low-signal head research result from landmark geometry only.':
        'ලෑන්ඩ්මාර්ක් ජ්‍යාමිතියෙන් පමණක් ලැබුණු අඩු සංඥා හිස පර්යේෂණ ප්‍රතිඵලයකි.',
    'Review-level head research signal from landmark geometry. Gemini AI was unavailable for this scan.':
        'ලෑන්ඩ්මාර්ක් ජ්‍යාමිතියෙන් මධ්‍යම මට්ටමේ හිස පර්යේෂණ සංඥාවක් ලැබුණි. මෙම පරීක්ෂාව සඳහා Gemini AI ලබාගත නොහැකි විය.',
    'High-priority head research signal from landmark geometry. Gemini AI was unavailable for this scan.':
        'ලෑන්ඩ්මාර්ක් ජ්‍යාමිතියෙන් ඉහළ ප්‍රමුඛතාවක් ඇති හිස පර්යේෂණ සංඥාවක් ලැබුණි. මෙම පරීක්ෂාව සඳහා Gemini AI ලබාගත නොහැකි විය.',
    'Head screening output unavailable.': 'හිස පරීක්ෂණ ප්‍රතිදානය ලබාගත නොහැක.',
    'Retake the head image from the supported oblique top-down view before relying on the result.':
        'ප්‍රතිඵලය මත විශ්වාසය තැබීමට පෙර සහාය දක්වන ඉහළින්-ඉදිරි කෝණයෙන් හිස ඡායාරූපය නැවත ගන්න.',
    'Repeat the scan and review the geometry metrics. If there is ongoing concern, consult a pediatrician.':
        'ස්කෑනය නැවත කර ජ්‍යාමිතික මිනුම් සමාලෝචනය කරන්න. තවදුරටත් සැලකිල්ලක් තිබේ නම් ළමා වෛද්‍යවරයෙකු අමතන්න.',
    'The capture did not match the supported screening view.':
        'මෙම ග්‍රහණය සහාය දක්වන පරීක්ෂණ කෝණයට නොගැළපුණි.',
    'Parent risk factors and age are not collected in this capture flow yet; Gemini used default context values.':
        'මෙම ග්‍රහණ ප්‍රවාහයේදී දෙමාපිය අවදානම් කරුණු සහ වයස තවමත් එකතු නොකෙරේ; Gemini පෙරනිමි සන්දර්භ අගයන් භාවිත කළේය.',
    'The posture screening model is not initialized.':
        'ඉරියව් පරීක්ෂණ මෝඩලය තවමත් ආරම්භ කර නොමැත.',
    'No reliable posture capture was detected. Retake with the infant body centered and both shoulders and hips clearly visible.':
        'විශ්වාසදායක ඉරියව් ග්‍රහණයක් හඳුනාගත නොහැකි විය. ළදරුවාගේ ශරීරය මධ්‍යයේ පිහිටින ලෙස සහ උරහිස් සහ උකුල් දෙකම පැහැදිලිව පෙනෙන ලෙස නැවත ග්‍රහණය කරන්න.',
    'Research-only pipeline: MoveNet pose keypoints plus rule-based posture geometry.':
        'පර්යේෂණ පයිප්ලයිනය පමණි: MoveNet pose keypoints සහ නියම මත පදනම් වූ ඉරියව් ජ්‍යාමිතිය.',
    'Pose output is incomplete. Retake with the full infant body visible.':
        'Pose ප්‍රතිදානය අපූර්ණයි. ළදරුවාගේ සම්පූර්ණ ශරීරය පෙනෙන ලෙස නැවත ග්‍රහණය කරන්න.',
    'The posture model did not return the required torso landmarks.':
        'ඉරියව් මෝඩලය අවශ්‍ය torso landmarks ආපසු ලබා නොදුන්නේය.',
    'Keypoint visibility is low. Keep the shoulders and hips fully visible.':
        'Keypoint පැහැදිලිතාව අඩුයි. උරහිස් සහ උකුල් දෙකම සම්පූර්ණයෙන් පෙනෙන ලෙස තබන්න.',
    'Torso span is too small. Move the camera closer to the baby.':
        'Torso පරාසය ඉතා කුඩායි. කැමරාව ළදරුවාට තව ටිකක් ලං කරන්න.',
    'The body appears too narrow for a frontal asymmetry screen.':
        'ඉදිරිපස අසමමිතිය පරීක්ෂණයකට ශරීරය ඉතා පටු ලෙස පෙනේ.',
    'Head landmarks are weak. Head tilt will be less reliable on this capture.':
        'හිස landmarks දුර්වලයි. මෙම ග්‍රහණයේ හිස ඇලවීමේ මිනුම අඩු විශ්වාසදායක විය හැක.',
    'Body detection confidence is too low for posture screening.':
        'ඉරියව් පරීක්ෂණයට ශරීර හඳුනාගැනීමේ විශ්වාස මට්ටම ඉතා අඩුයි.',
    'One side of the torso is weakly detected. Keep both shoulders and hips visible.':
        'Torso එක පැත්තක් දුර්වල ලෙස හඳුනාගෙන ඇත. උරහිස් සහ උකුල් දෙකම පැහැදිලිව පෙනෙන ලෙස තබන්න.',
    'The torso span is too small. Move the camera closer before capturing.':
        'Torso පරාසය ඉතා කුඩායි. ග්‍රහණය කිරීමට පෙර කැමරාව ළදරුවාට ලං කරන්න.',
    'The infant body is too narrow in frame. Capture a centered full-body view.':
        'රූප රාමුව තුළ ළදරුවාගේ ශරීරය ඉතා පටුයි. මධ්‍යගත සම්පූර්ණ ශරීර දසුනක් ගන්න.',
    'The infant body is too far from the center of the frame.':
        'ළදරුවාගේ ශරීරය රාමුවේ මධ්‍යයෙන් ඉතා ඈතින් පිහිටා ඇත.',
    'Unsupported posture view. Retake with a centered frontal or top-down body view.':
        'මෙම ඉරියව් කෝණයට සහාය නොදක්වයි. මධ්‍යගත ඉදිරිපස හෝ ඉහළින් ගත් ශරීර දසුනක් සමඟ නැවත ගන්න.',
    'Unsupported posture capture view. Retake before relying on the screen.':
        'මෙම ඉරියව් ග්‍රහණ කෝණයට සහාය නොදක්වයි. මෙම ප්‍රතිඵලය මත විශ්වාසය තැබීමට පෙර නැවත ග්‍රහණය කරන්න.',
    'Low-signal posture research result from body keypoints.':
        'ශරීර keypoints මත පදනම් වූ අඩු සංඥා ඉරියව් පර්යේෂණ ප්‍රතිඵලයකි.',
    'Review-level posture research signal. Repeat capture and review the metrics.':
        'මධ්‍යම මට්ටමේ ඉරියව් පර්යේෂණ සංඥාවක් පෙනේ. ග්‍රහණය නැවත කර මිනුම් සමාලෝචනය කරන්න.',
    'High-priority posture research signal from the captured body keypoints. This is still not a diagnosis.':
        'ග්‍රහණය කළ ශරීර keypoints මත ඉහළ ප්‍රමුඛතාවක් ඇති ඉරියව් පර්යේෂණ සංඥාවක් පෙනේ. මෙය තවමත් රෝග නිශ්චයක් නොවේ.',
    'Screening output unavailable.': 'පරීක්ෂණ ප්‍රතිදානය ලබාගත නොහැක.',
    'Geometric review confirmed against the captured body landmarks.':
        'ග්‍රහණය කළ ශරීර ලෑන්ඩ්මාර්ක් සමඟ ජ්‍යාමිතික සමාලෝචනය තහවුරු කරන ලදී.',
  };
}
