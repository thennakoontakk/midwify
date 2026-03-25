# AR Screening Research Protocol

## Scope

This AR module is a research screening pipeline. It is not a diagnostic tool.

- Head track: infant cranial asymmetry screening from landmarks and geometry
- Posture track: infant postural asymmetry screening from pose keypoints
- Runtime labels: `Low Risk`, `Review`, `Refer`
- Runtime outputs are intended for research review and referral support only

## Runtime Architecture

### Head screening

- Intended landmark asset: `assets/models/face_landmarker.task`
- Current active runtime: ML Kit face mesh fallback until a MediaPipe Tasks runtime is integrated
- Feature engine:
  - cranial index
  - cranial vault asymmetry index
  - facial symmetry offset
  - cephalic proportion score
  - landmark quality
  - top-down angle delta
- Capture protocol:
  - oblique top-down frontal view
  - forehead, temples, and nose must be visible
  - unsupported views are rejected or escalated to retake

### Posture screening

- Pose estimator asset: `assets/models/posture_analysis.tflite`
- Runtime interpretation: pose/keypoint extraction only
- Feature engine:
  - shoulder tilt
  - hip tilt
  - trunk tilt
  - head tilt
  - midline offset
  - visibility quality
  - camera roll
- Capture protocol:
  - centered frontal or top-down body view
  - shoulders and hips must be visible
  - unsupported views are rejected or escalated to retake

## Dataset Specification

Build two datasets with subject-level separation:

- `Head Screening`
- `Posture Screening`

Minimum pilot target per track:

- 150 subjects
- 2-3 captures per subject
- dual-rater labels
- standardized capture protocol

Required split:

- 60% train
- 20% validation
- 20% test

No subject may appear in more than one split.

## Labeling Guidance

### Head labels

Use clinician-rated asymmetry severity or external reference measurements to assign:

- `low-risk`
- `review`
- `refer`

Do not expose named diseases as runtime outputs in v1.

### Posture labels

Store both:

- continuous asymmetry measurements
- calibrated `low-risk` / `review` / `refer` bands

Do not expose named posture disorders as runtime outputs in v1.

## Calibration

Use the validation set to choose operating thresholds that prioritize high sensitivity for referral-worthy cases.

Document:

- chosen thresholds
- sensitivity
- specificity
- PPV
- NPV
- AUC
- confusion matrix

## Logging

Log the following for each capture:

- subject identifier
- study split
- view type
- capture accepted or rejected
- quality score
- screening score
- risk band
- raw feature values
- warnings
- manual reviewer outcome

Rejected captures are a first-class outcome and must be counted in usability reporting.

## Evaluation

Run offline evaluation on the held-out test set for each track.

Required outputs:

- AUC
- sensitivity
- specificity
- PPV
- NPV
- confusion matrix
- correlation between raw metrics and clinician scores
- inter-rater agreement for labels

Before declaring the system usable, review:

- false positives
- false negatives
- rejected captures

## Mobile Integration Notes

- Keep head screening on the landmarks-plus-geometry path
- Keep posture screening on the pose-estimator-plus-geometry path
- Do not reintroduce generic `confidence` for heuristic outputs
- UI must display:
  - capture quality
  - screening score
  - risk band
  - warnings
  - research-only disclaimer

## Claims Boundary

Allowed claims:

- research screening aid
- asymmetry screening
- referral support

Disallowed claims without further validation:

- diagnosis
- treatment recommendation
- disease confirmation
