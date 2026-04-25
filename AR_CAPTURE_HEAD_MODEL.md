# AR Capture — Head Model & Posture Detection Pipeline

## Table of Contents

1. [Overview](#overview)
2. [Architecture Diagrams](#architecture-diagrams)
3. [File Map](#file-map)
4. [Head Screening Pipeline](#head-screening-pipeline)
   - [Step 1 — Image Capture](#step-1--image-capture)
   - [Step 2 — Image Preparation](#step-2--image-preparation)
   - [Step 3 — Landmark Detection](#step-3--landmark-detection)
   - [Step 4 — Head Presence Validation](#step-4--head-presence-validation)
   - [Step 5 — Cranial Geometry Scoring](#step-5--cranial-geometry-scoring)
   - [Step 6 — Gemini AI Analysis](#step-6--gemini-ai-analysis)
   - [Step 7 — Result Building](#step-7--result-building)
5. [Posture Detection Pipeline](#posture-detection-pipeline)
   - [Posture Step 1 — Image Capture](#posture-step-1--image-capture)
   - [Posture Step 2 — MoveNet Inference](#posture-step-2--movenet-inference)
   - [Posture Step 3 — Posture Geometry Scoring](#posture-step-3--posture-geometry-scoring)
   - [Posture Step 4 — Result Building](#posture-step-4--result-building)
6. [Risk Classification System](#risk-classification-system)
7. [Bug: Output Always Shows "Medium" — Root Causes & Fixes Applied](#bug-output-always-shows-medium)
8. [Gemini API Integration](#gemini-api-integration)
9. [Cranial Metrics Engine](#cranial-metrics-engine)
10. [Posture Metrics Engine](#posture-metrics-engine)
11. [Hardcoded Defaults](#hardcoded-defaults)
12. [How to Debug](#how-to-debug)

---

## Overview

The AR Capture module contains two independent screening pipelines sharing common data models (`ARCaptureResult`, `RiskBand`):

| Mode | Model | Purpose |
|------|-------|---------|
| **Head** | MediaPipe + Gemini 2.5 Flash | Craniosynostosis / head shape screening |
| **Posture** | MoveNet (TFLite) | Infant postural asymmetry screening |

Both pipelines are labeled **research-only** — not clinical diagnostic tools.

---

## Architecture Diagrams

### Head Pipeline

```
HeadCaptureScreen
       │  image path(s)
       ▼
CranialAnalysisService.analyzeFromPath()
       │
       ├─► _prepareWorkingImage()         Downscale if > 1 MB
       │
       ├─► HeadLandmarkerRuntime          Native MediaPipe (Android MethodChannel)
       │       │ fail / sparse
       │       ▼
       │   ML Kit FaceMeshDetector        468-point fallback
       │
       ├─► _validateHeadPresence()        Reject weak / clipped captures
       │
       ├─► analyzeCranialMetrics()        Geometry engine (CI, CVAI, quality)
       │
       ├─► GeminiCranioService.analyzeWithAI()   Optional Gemini multimodal AI
       │
       ├── [AI OK]   _buildAiResult()     Uses Gemini riskBand + score
       │
       └── [AI fail] _buildGeometryFallbackResult()
                          Uses geometry riskBand, or RiskBand.unavailable
                          when supportedView = false
                               │
                               ▼
                        ARCaptureResult (riskBand, summary, warnings, headMetrics)
                               │
                               ▼
                        DiagnosisScreen → "Low" / "Medium" / "High" / "Unavailable"
```

### Posture Pipeline

```
PostureCaptureScreen
       │  image path
       ▼
MLService.runInference(AppMode.posture)
       │
       ├─► img.decodeImage()              Decode JPEG/PNG
       │
       ├─► runPostureKeypointInference()
       │       │
       │       ├─► _prepareMoveNetInput() Aspect-preserving resize → 256×256 + black pad
       │       │
       │       ├─► TFLite Interpreter.run()  MoveNet pose model
       │       │
       │       └─► _mapKeypointsBackToOriginalFrame()  Normalize to [0,1]
       │
       ├─► analyzePostureKeypoints()      Geometry scoring (tilts, symmetry)
       │
       ├── [captureAccepted = false]  ARCaptureResult.invalid()
       │
       └── [captureAccepted = true]   ARCaptureResult with PostureScreeningMetrics
                                              │
                                              ▼
                                       DiagnosisScreen → "Low" / "Medium" / "High"
```

---

## File Map

| File | Role |
|------|------|
| `lib/screens/ar_capture/head_capture_screen.dart` | Head camera UI |
| `lib/screens/ar_capture/posture_capture_screen.dart` | Posture camera UI |
| `lib/screens/ar_capture/ar_capture_main_screen.dart` | Mode state machine |
| `lib/screens/ar_capture/diagnosis_screen.dart` | Result display |
| `lib/screens/ar_capture/ar_capture_localization.dart` | Localized label strings |
| `lib/screens/ar_capture/ar_capture_models.dart` | RiskBand, ARCaptureResult, HeadScreeningMetrics, PostureScreeningMetrics |
| `lib/services/ar_capture/cranial_analysis_service.dart` | Head pipeline orchestrator |
| `lib/services/ar_capture/gemini_cranio_service.dart` | Gemini 2.5 Flash API client |
| `lib/services/ar_capture/cranial_metrics.dart` | Cranial geometry engine |
| `lib/services/ar_capture/head_landmarker_runtime.dart` | Native MediaPipe bridge (MethodChannel) |
| `lib/services/ar_capture/ml_service.dart` | Posture TFLite orchestrator |
| `lib/services/ar_capture/posture_screening.dart` | Posture geometry engine |
| `lib/services/ar_capture/classifier_service.dart` | **Retired** — was TFLite head classifier, now no-op |
| `assets/models/face_landmarker.task` | MediaPipe face landmarker model |
| `assets/models/posture_analysis.tflite` | MoveNet pose estimation model (13 MB) |
| `app.env` | `GEMINI_API_KEY` for head AI analysis |
| `test/ar_capture/posture_screening_test.dart` | Posture unit tests |
| `test/ar_capture/gemini_cranio_service_test.dart` | Gemini service unit tests |

---

## Head Screening Pipeline

### Step 1 — Image Capture

**File:** `head_capture_screen.dart`

User takes a primary photo and optionally a second confirmation photo. Paths are passed to `CranialAnalysisService.analyzeFromPath()` via `MLService.runInference(AppMode.head)`.

---

### Step 2 — Image Preparation

**File:** `cranial_analysis_service.dart` → `_prepareWorkingImage()`

- If file size > **1 MB**: downscale to max 1024 px on the longest edge (JPEG quality 85), saved as a temporary working file.
- Original path is still passed to Gemini separately.
- Warning added to result if resizing occurred.

---

### Step 3 — Landmark Detection

**File:** `cranial_analysis_service.dart` (lines 98–187)

**Primary — MediaPipe `face_landmarker.task` (Android native):**
- Calls `HeadLandmarkerRuntime.detectFromPath()` via MethodChannel.
- Returns 468 normalized 3D landmarks.
- Z-axis is sign-flipped (`z: -lm.z`) to match the sign convention of the cranial geometry engine.

**Fallback — ML Kit FaceMeshDetector:**
- Used if MediaPipe returns `null` or fewer than 454 landmarks.
- Pixel coordinates normalized by image width/height.

**Abort cases:**
- No face detected → `ARCaptureResult.invalid`
- Required landmark indices all zero → `ARCaptureResult.invalid`

---

### Step 4 — Head Presence Validation

**File:** `cranial_analysis_service.dart` → `_validateHeadPresence()`

Rejects if:
- Fewer than 32 landmarks in `[0,1]` bounds
- Bounding box width < 0.18, height < 0.18, or area < 0.045
- Temple span < 0.12, forehead span < 0.08, nose depth < 0.03
- Head clipped by any edge (< 0.01 or > 0.99)

---

### Step 5 — Cranial Geometry Scoring

**File:** `cranial_metrics.dart` → `analyzeCranialMetrics()`

See the [Cranial Metrics Engine](#cranial-metrics-engine) section for formulas.

**`supportedView` is `true` only when ALL of:**
- Camera angle z-diff ≥ 0.005
- Temple tilt ≤ 12°
- Facial symmetry offset ≤ 12%
- Quality score ≥ 40

**Risk band mapping (geometry-only):**

| Score | CranialRiskBand | Maps to in geometry fallback |
|-------|----------------|------------------------------|
| ≥ 70 | `refer` | `RiskBand.refer` |
| 35–69 | `review` | `RiskBand.review` |
| 0–34 | `lowRisk` | `RiskBand.lowRisk` |
| — | (any, unsupported view) | `RiskBand.unavailable` ← fixed |

---

### Step 6 — Gemini AI Analysis

**File:** `gemini_cranio_service.dart`

- Model: `gemini-2.5-flash`, timeout 35 s
- API key loaded from `app.env` (`GEMINI_API_KEY`)
- Sends: up to 2 base64 images + JSON measurement payload
- If Gemini fails for any reason, the pipeline catches the exception and uses the geometry fallback

See the [Gemini API Integration](#gemini-api-integration) section for full details.

---

### Step 7 — Result Building

**Two paths:**

**A — AI result available** (`_buildAiResult`):
- `riskBand` = Gemini `riskLevel` → `RiskBand`
- `screeningScore` = Gemini `riskScore`
- `summary` = Gemini `visualObservations`
- Geometry warnings + Gemini key findings combined into `warnings`

**B — Geometry fallback** (`_buildGeometryFallbackResult`):
- If `!supportedView` → `RiskBand.unavailable` (captures with unreliable geometry report unavailable, not a false "Medium")
- If `supportedView` → `RiskBand` from geometry score
- `aiFallbackMessage` explains to the user why AI was skipped

---

## Posture Detection Pipeline

### Posture Step 1 — Image Capture

**File:** `posture_capture_screen.dart`

User takes one photo of the infant from a front-on or top-down view. Minimum on-screen processing display: 3 seconds. Result returned via `widget.onCapture(ARCaptureResult)`.

---

### Posture Step 2 — MoveNet Inference

**File:** `ml_service.dart` → `runPostureKeypointInference()`

**Model:** MoveNet pose estimation (TFLite, 13 MB)  
**Input:** `[1, 256, 256, 3]` RGB tensor  
**Output:** `[1, 1, 17, 3]` — 17 keypoints, each `[y, x, confidence]`

**Preprocessing (`_prepareMoveNetInput`):**
1. Aspect-ratio preserving resize to fit in 256×256
2. Black padding (0,0,0) to fill the 256×256 frame
3. Pixel values as integers (or floats if model requires — detected at runtime)

**Post-processing (`_mapKeypointsBackToOriginalFrame`):**
- Reverse the padding offset: `normalizedY = (paddedY - padTop) / resizedHeight`
- Clamp to `[0.0, 1.0]`

**17 Keypoint Indices (MoveNet standard):**

| Index | Landmark | Used |
|-------|----------|------|
| 0 | Nose | Head tilt anchor |
| 1 | Left Eye | Head tilt anchor |
| 2 | Right Eye | Head tilt anchor |
| 3 | Left Ear | Head tilt anchor (primary) |
| 4 | Right Ear | Head tilt anchor (primary) |
| 5 | Left Shoulder | Critical — torso |
| 6 | Right Shoulder | Critical — torso |
| 11 | Left Hip | Critical — torso |
| 12 | Right Hip | Critical — torso |
| 7–10, 13–16 | Arms, knees, ankles | Not used in scoring |

---

### Posture Step 3 — Posture Geometry Scoring

**File:** `posture_screening.dart` → `analyzePostureKeypoints()`

See the [Posture Metrics Engine](#posture-metrics-engine) section for formulas.

**`supportedView` is `true` only when ALL of:**
- `visibilityQuality` ≥ 0.40
- `torsoSideBalance` ≥ 0.30
- `torsoHeight` ≥ 0.10
- `shoulderWidth` ≥ 0.10
- `hipWidth` ≥ 0.08
- `bodyCenterOffsetRatio` ≤ 0.22

**`captureAccepted = supportedView && bodyPresenceScore ≥ 50`**

---

### Posture Step 4 — Result Building

**File:** `ml_service.dart` → `_runPostureInference()`

- If `!captureAccepted` → `ARCaptureResult.invalid` (`RiskBand.unavailable`)
- If `captureAccepted` → full `ARCaptureResult` with `PostureScreeningMetrics`

**Risk band mapping:**

| PostureRiskBand | RiskBand | Displayed as |
|----------------|----------|-------------|
| `lowRisk` | `RiskBand.lowRisk` | Low |
| `review` | `RiskBand.review` | Medium |
| `refer` | `RiskBand.refer` | High |

---

## Risk Classification System

```
RiskBand enum          impactLevelLabel     Head (Gemini)    Geometry score
──────────────────────────────────────────────────────────────────────────────
RiskBand.lowRisk   →   "Low"           ←   "low"            0–34 + supportedView
RiskBand.review    →   "Medium"        ←   "moderate"       35–69 + supportedView
RiskBand.refer     →   "High"          ←   "high"           ≥ 70
RiskBand.unavailable → "Unavailable"   ←   API failure      !supportedView (geometry fallback)
```

There is **no explicit head size** (small/medium/large) — only clinical risk bands.

---

## Bug: Output Always Shows "Medium"

### Root Causes Found

Three independent causes were identified, all fixed as described below.

---

### Root Cause 1 — Geometry engine artificially pinned scores to 55 for bad views

**Files affected:** `cranial_metrics.dart` and `posture_screening.dart`

**Was (in both files):**
```dart
if (!supportedView) {
  screeningScore = math.max(screeningScore, 55);  // ← forced into review/medium band
  reasons.add('Capture quality is insufficient for a reliable low-risk screen.');
}
```

Score 55 lands in the 35–69 range → `review` band → displayed as **"Medium"**. Since `supportedView` requires a precise oblique angle, correct tilt, and sufficient symmetry, most real captures failed this test and were immediately pinned to "Medium".

**Fix applied:**
```dart
if (!supportedView) {
  reasons.add('Capture quality is insufficient for a reliable low-risk screen.');
  // score is no longer artificially inflated
}
```

---

### Root Cause 2 — Geometry fallback on unsupported view returned "Medium" instead of "Unavailable"

**File:** `cranial_analysis_service.dart` → `_buildGeometryFallbackResult()`

When Gemini failed AND `supportedView = false`, the geometry risk band (inflated to "review" by Root Cause 1) was used directly, producing "Medium" for an effectively useless capture.

**Fix applied:**
```dart
// Was:
final riskBand = switch (cranialResult.riskBand) { ... };

// Now:
final riskBand = !cranialResult.supportedView
    ? RiskBand.unavailable      // ← honest "retake" instead of false "Medium"
    : switch (cranialResult.riskBand) {
        CranialRiskBand.lowRisk => RiskBand.lowRisk,
        CranialRiskBand.review  => RiskBand.review,
        CranialRiskBand.refer   => RiskBand.refer,
      };
```

When `supportedView = false` and Gemini is unavailable, the result now shows **"Unavailable"** with retake instructions rather than a misleading "Medium".

---

### Root Cause 3 — Gemini always received `ageWeeks: 0`, triggering conservative "moderate" bias

**File:** `cranial_analysis_service.dart` (call site) + `gemini_cranio_service.dart` (system prompt)

The app does not collect the baby's age, so `ageWeeks: 0` was hardcoded. The Gemini system prompt instructed:

> *"If the baby is under 8 weeks, note that suture assessment is more difficult and recommend follow-up imaging if any clinical doubt exists."*

Age 0 (always sent) triggered this conservative rule on every scan, biasing Gemini toward `"moderate"` risk as a precautionary default.

**Fix applied — caller (`cranial_analysis_service.dart`):**
```dart
// Was:
ageWeeks: 0,

// Now:
ageWeeks: -1,   // sentinel: age unknown, not captured in this app flow
```

**Fix applied — system prompt (`gemini_cranio_service.dart`):**
```
// Was:
- ageWeeks: baby age in weeks (0-104)

// Now:
- ageWeeks: baby age in weeks (0-104), or -1 when the app did not capture age.
  When ageWeeks is -1 (unknown), do NOT apply the conservative under-8-week rule.
  Treat the age as unknown and base your assessment on geometry and visual evidence only.
```

**Fix applied — payload `dataCompleteness` notes:**
```dart
'ageWeeksKnown': ageWeeks >= 0,
'notes': [
  'ageWeeks is -1 when unknown (not captured yet); do not apply the conservative under-8-week rule in that case.',
  'parentRiskFactors are all false because the app does not yet collect them from the user.',
  'Null metric fields indicate values not computable from the current landmark set.',
],
```

---

### Expected Behavior After Fixes

| Scenario | Before fixes | After fixes |
|----------|-------------|-------------|
| Good camera angle, normal head | Medium (inflated) | Low |
| Good camera angle, asymmetric head | Medium (inflated) | Medium or High |
| Bad camera angle, Gemini fails | Medium | Unavailable + retake warning |
| Bad camera angle, Gemini succeeds | Medium (Gemini also biased) | Gemini result with low confidence |
| Any capture, Gemini running | Medium (age=0 bias) | Gemini's actual assessment |

---

## Gemini API Integration

### Configuration

API key loaded from `app.env` via `flutter_dotenv`:
```
GEMINI_API_KEY=<your key>
```

The service validates the key on every call:
```dart
if (apiKey == null || apiKey.trim().isEmpty || apiKey.trim() == 'your_key_here') {
  throw StateError('GEMINI_API_KEY is missing or still set to the placeholder value.');
}
```

If invalid → exception thrown → geometry fallback used.

### Request Structure

```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=...

{
  "systemInstruction": { "parts": [{ "text": "<100-line cranial screening prompt>" }] },
  "generationConfig": { "responseMimeType": "application/json", "temperature": 0.1 },
  "contents": [{
    "parts": [
      { "inline_data": { "mime_type": "image/jpeg", "data": "<base64>" } },
      { "inline_data": { ...second image, optional... } },
      { "text": "<language instruction> Analyze ... <JSON measurements>" }
    ]
  }]
}
```

### Image Preparation

Images are resized before sending if longest dimension > 896 px or file > 1 MB. Encoded as JPEG at quality 82.

### Measurement Payload

```json
{
  "captureSet": { "imageCount": 1, "secondaryConfirmationProvided": false },
  "ageWeeks": -1,
  "cephalicIndex": <float>,
  "asymmetryIndex": <float>,
  "foreheadSkewPct": <float>,
  "templeTiltDeg": <float>,
  "supportedView": <bool>,
  "cephalicProportionScore": <float>,
  "qualityScore": <int>,
  "screeningScore": <int>,
  "faceMeshLandmarks": {
    "orbitalSymmetry": null,
    "anteriorPosteriorRatio": <float>,
    "templeWidth": <float>,
    "foreheadWidth": <float>
  },
  "parentRiskFactors": {
    "familyHistory": false,
    "visibleSutureRidge": false,
    "feedingDifficulties": false,
    "unusualIrritability": false
  },
  "dataCompleteness": {
    "parentRiskFactorsCapturedInAppFlow": false,
    "ageWeeksKnown": false,
    "notes": [...]
  }
}
```

### Response Fields

| Field | Values | Maps to |
|-------|--------|--------|
| `riskLevel` | `"low"` / `"moderate"` / `"high"` | `RiskBand.lowRisk` / `.review` / `.refer` |
| `riskScore` | 0–100 | `screeningScore` |
| `headShapeClassification` | `"normal"` / `"scaphocephaly"` / etc. | `headShapeLabel` |
| `confidence` | `"low"` / `"medium"` / `"high"` | `aiConfidence` |
| `urgency` | `"routine"` / `"soon"` / `"urgent"` | `aiUrgency` |
| `keyFindings` | string array | shown in warnings |
| `recommendation` | string | shown in warnings |
| `visualObservations` | string | `summary` |

### User-visible failure messages

| Error type | Message shown |
|-----------|--------------|
| Timeout | "AI-assisted photo review did not respond in time, so this result uses on-device geometry only." |
| Missing/invalid API key | "AI-assisted photo review is not configured in this build..." |
| HTTP 401/403 | "AI-assisted photo review was rejected by the server..." |
| Any other error | "AI-assisted photo review was unavailable for this scan..." |

---

## Cranial Metrics Engine

**File:** `cranial_metrics.dart`

### Landmark Indices Used

| Constant | Index | Landmark |
|----------|-------|----------|
| `kLmNoseTip` | 1 | Nose tip |
| `kLmGlabella` | 10 | Forehead center |
| `kLmLeftForehead` | 103 | Left forehead |
| `kLmRightTemple` | 234 | Right temple |
| `kLmRightForehead` | 332 | Right forehead |
| `kLmLeftTemple` | 454 | Left temple |

### Formulas

**Cranial Index (CI):**
```
width  = dist3D(rightTemple, leftTemple)
length = dist2D(glabella, noseTip) × 2.8   (kApLengthScale)
CI     = (width / length) × 100
```
Normal: 75–85. < 70 → elongated. > 90 → broad.

**CVAI (Cranial Vault Asymmetry Index):**
```
diagA = dist3D(leftForehead, rightTemple)
diagB = dist3D(rightForehead, leftTemple)
CVAI  = (|diagA − diagB| / diagA) × 100
```
> 3.5% notable. > 7% → +40 points.

**Quality Score:**
```
angleScore    = clamp01((zDiff − 0.005) / 0.025) × 100
symmetryScore = clamp01(1 − facialSymmetryOffsetPct / 18) × 100
tiltScore     = clamp01(1 − templeTiltDeg / 18) × 100
qualityScore  = angleScore×0.5 + symmetryScore×0.3 + tiltScore×0.2
```

**Screening Score Accumulation:**

| Condition | Points |
|-----------|--------|
| CI < 74 | +35 |
| CI > 86 | +35 |
| 74 ≤ CI < 76 or 84 < CI ≤ 86 | +18 |
| CVAI > 7 | +40 |
| 4 < CVAI ≤ 7 | +24 |
| `facialSymmetryOffsetPct` > 10 | +18 |
| `facialSymmetryOffsetPct` > 6 | +10 |
| ~~`!supportedView`~~ | ~~`max(score, 55)`~~ — **removed** |

---

## Posture Metrics Engine

**File:** `posture_screening.dart`

### Camera Roll Correction

Before computing tilts, the entire pose is rotated to compensate for camera tilt:
```
cameraRollDeg = (shoulderLineAngle + hipLineAngle) / 2
rotatedPose   = _rotatePose(pose, center: torsoCenter, degrees: cameraRollDeg)
```

### Key Measurements (all on rotated pose)

| Metric | Formula |
|--------|---------|
| `shoulderTiltDeg` | `|angle(leftShoulder, rightShoulder)|` |
| `hipTiltDeg` | `|angle(leftHip, rightHip)|` |
| `trunkTiltDeg` | `angleFromVertical(shoulderCenter, hipCenter)` |
| `headTiltDeg` | `|angle(bestHeadLeft, bestHeadRight)|` (0 if head not visible) |
| `midlineOffsetRatio` | `|shoulderCenter.x − hipCenter.x| / torsoHeight` |
| `visibilityQuality` | mean confidence of 4 torso keypoints |
| `torsoSideBalance` | `min(leftSideConf, rightSideConf)` |

### Scores

**bodyPresenceScore (0–100):**
```
= visibilityQuality×50 + scoreForward(torsoHeight, 0.10, 0.20)×25
  + scoreForward(min(shoulderW, hipW), 0.08, 0.18)×15
  + scoreForward(torsoSideBalance, 0.30, 0.65)×5
  + (1 - bodyCenterOffset / 0.22)×5
```

**qualityScore (0–100):**
```
= visibilityQuality×65 + scoreInverse(shoulderTilt, 20)×15
  + scoreInverse(hipTilt, 20)×15 + scoreInverse(trunkTilt, 25)×5
```

**screeningScore (0–100):**

| Component | soft | hard | max pts |
|-----------|------|------|---------|
| Shoulder tilt | 4° | 10° | 25 |
| Hip tilt | 4° | 10° | 25 |
| Trunk tilt | 5° | 12° | 30 |
| Head tilt | 4° | 12° | 15 |
| Midline offset | 0.08 | 0.16 | 15 |
| ~~`!supportedView`~~ | — | — | ~~`max(score, 55)`~~ — **removed** |

**Risk band:**

| screeningScore | PostureRiskBand | Displayed as |
|----------------|----------------|-------------|
| ≥ 70 | `refer` | High |
| 35–69 | `review` | Medium |
| 0–34 | `lowRisk` | Low |

**Capture rejected if:** `!captureAccepted` (i.e., `!supportedView` or `bodyPresenceScore < 50`) → `ARCaptureResult.invalid` / `RiskBand.unavailable`

### Head Anchor Selection (posture)
```dart
PoseKeypoint? _bestHeadAnchor(primary, secondary) {
  if (primary.confidence >= 0.35) return primary;   // ear preferred
  if (secondary.confidence >= 0.35) return secondary; // eye fallback
  return null;  // head tilt = 0.0 if neither visible
}
```

---

## Hardcoded Defaults

| Parameter | Value | Location | Status |
|-----------|-------|----------|--------|
| `ageWeeks` | `-1` (was `0`) | `cranial_analysis_service.dart:255` | **Fixed** — `-1` now signals "unknown" to Gemini |
| `familyHistory` | `false` | `cranial_analysis_service.dart:257` | Not yet collected from user |
| `visibleSutureRidge` | `false` | `cranial_analysis_service.dart:258` | Not yet collected from user |
| `feedingDifficulties` | `false` | `cranial_analysis_service.dart:259` | Not yet collected from user |
| `unusualIrritability` | `false` | `cranial_analysis_service.dart:260` | Not yet collected from user |
| `orbitalSymmetry` | `null` | `cranial_analysis_service.dart:391` | Not computable from current landmark set |

---

## How to Debug

### 1. Check if Gemini is actually being called

Look for Flutter debug logs:
```
[HEAD_AI] Posting multimodal request to Gemini
[HEAD_AI] Gemini response status 200
```

If you see:
```
Gemini head analysis failed: ...
```
Gemini failed and geometry fallback is active.

### 2. Inspect `debugDetails`

`ARCaptureResult.debugDetails` contains:
- `geometry.screeningScore` — raw geometry score
- `geometry.supportedView` — was the camera angle valid?
- `aiResult.riskLevel` — what Gemini returned
- `aiError` — exception if Gemini failed
- `inputContext.defaultsUsed: true` — confirms hardcoded defaults were used

### 3. Check `app.env`

```
GEMINI_API_KEY=<actual key, not "your_key_here">
```

### 4. Verify `supportedView` frequency

If `debugDetails['geometry']['supportedView']` is `false` on most captures, guide users to hold the phone 30–45° above the baby's head with the forehead, temples, and nose all visible.

### 5. Posture — check `captureAccepted`

```
debugDetails['postureAssessment']['captureAccepted']
debugDetails['postureAssessment']['visibilityQuality']
debugDetails['postureAssessment']['supportedView']
```

If `captureAccepted = false`, the result shows `RiskBand.unavailable` with rejection reasons.

---

*Last updated: 2026-04-24*
