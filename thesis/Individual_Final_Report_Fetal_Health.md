# SRI LANKA INSTITUTE OF INFORMATION TECHNOLOGY

## Faculty of Computing
### Department of Software Engineering

---

# INDIVIDUAL FINAL REPORT

## RP-25-26J-426

---

# Automated Fetal Health Risk Assessment Using Image Processing and Human-in-the-Loop Machine Learning

**Component:** Fetal Health Risk Assessment System

---

| Field | Details |
|-------|---------|
| **Student Name** | Thennakoon T.A.K.K. |
| **Student ID** | IT22096920 |
| **Degree Programme** | BSc (Hons) in Information Technology Specialising in Software Engineering |
| **Supervisor** | Mr. Didula Thanaweera Arachchi |
| **Co-Supervisor** | Mrs. Narmada Gamage |
| **Submission Date** | April 2026 |

---

# DECLARATION

I confirm that the work submitted in this report is the result of my own investigation, except where otherwise stated. All sources of information have been specifically acknowledged. I understand that plagiarism constitutes a serious offence in academic work.

**Student Signature:** ______________________

**Date:** ______________________

---

# ACKNOWLEDGEMENT

I would like to express my sincere gratitude to my supervisor for their invaluable guidance and continuous support throughout this research. I also extend my appreciation to the Faculty of Computing at SLIIT for providing the necessary resources and academic environment. Special thanks to my fellow group members for their collaboration on the overall Midwify project. Finally, I am grateful to the healthcare professionals who provided domain expertise and participated in usability evaluations.

---

# ABSTRACT

Cardiotocography (CTG) interpretation remains a critical yet highly subjective component of antenatal care in Sri Lanka. Rural healthcare facilities frequently lack specialist obstetricians, placing the burden of CTG analysis on public health midwives who may lack the expertise for accurate interpretation. This research addresses the dual challenge of the "Interpretation Gap" and the "Data-Entry Bottleneck" by engineering a mobile-first, AI-powered Fetal Health Risk Assessment System.

The proposed system integrates a Computer Vision pipeline (OpenCV) for automated CTG parameter extraction, Optical Character Recognition (PyTesseract) for image validation, and a Random Forest Classifier trained on the UCI Fetal Health Dataset for risk stratification into Normal, Suspect, or Pathological categories. The Synthetic Minority Over-sampling Technique (SMOTE) was applied to address severe class imbalances in the training data.

A critical contribution is the Human-in-the-Loop (HITL) verification paradigm, where extracted macroscopic features are presented to midwives for mandatory verification before algorithmic processing. The system operates in both online mode (Flask REST API backend) and offline mode (on-device Random Forest inference in pure Dart), ensuring functionality in connectivity-constrained rural environments.

An Explainable AI (XAI) module provides human-readable diagnostic reasoning by mapping feature importance weights to clinical descriptions. The system achieved 94.2% overall classification accuracy with 94% recall for pathological cases. The Flutter-based mobile frontend provides an intuitive, clinically-safe workflow tailored for resource-constrained healthcare environments.

**Keywords:** Cardiotocography, Fetal Health, Machine Learning, Random Forest, Computer Vision, OpenCV, OCR, Human-in-the-Loop, Explainable AI, Flutter, Mobile Health

---

# TABLE OF CONTENTS

1. [Introduction](#chapter-1-introduction)
   - 1.1 Background of the Study
   - 1.2 Research Problem
   - 1.3 Research Objectives
   - 1.4 Scope and Limitations
   - 1.5 Structure of the Report
2. [Literature Review](#chapter-2-literature-review)
   - 2.1 Evolution of Fetal Monitoring
   - 2.2 Existing Automated CTG Analysis Systems
   - 2.3 Machine Learning in CTG Classification
   - 2.4 Research Gap Identification
3. [Methodology](#chapter-3-methodology)
   - 3.1 Research Approach
   - 3.2 System Architecture
   - 3.3 Dataset and Data Engineering
   - 3.4 Image Processing Pipeline
   - 3.5 Human-in-the-Loop Verification
   - 3.6 Predictive Modeling and XAI
4. [Implementation](#chapter-4-implementation)
   - 4.1 Technology Stack
   - 4.2 Backend Implementation
   - 4.3 Frontend Implementation
   - 4.4 Offline Inference Engine
   - 4.5 Data Persistence Layer
5. [Results and Evaluation](#chapter-5-results-and-evaluation)
   - 5.1 Machine Learning Model Evaluation
   - 5.2 Extraction Pipeline Accuracy
   - 5.3 System Testing
6. [Conclusion and Future Work](#chapter-6-conclusion-and-future-work)
   - 6.1 Conclusion
   - 6.2 Limitations
   - 6.3 Future Enhancements
7. [References](#references)
8. [Appendices](#appendices)

---

# CHAPTER 1: INTRODUCTION

## 1.1 Background of the Study

Maternal and fetal mortality rates serve as critical indicators of a nation's healthcare infrastructure. In Sri Lanka, while maternal healthcare has achieved commendable standards overall, significant geographical disparities persist between urban tertiary care hospitals and rural peripheral units. The cornerstone of fetal monitoring is Cardiotocography (CTG), a continuous electronic record of the fetal heart rate (FHR) plotted alongside uterine contractions (UC). The resulting graphical trace provides vital information regarding the autonomic nervous system of the fetus and its oxygenation status.

However, CTG interpretation requires nuanced clinical expertise. Subtle deviations such as late decelerations or reduced baseline variability can indicate severe fetal distress. In rural settings, Visiting Obstetricians and Gynaecologists (VOGs) are not perpetually available. Therefore, the onus of early detection falls upon midwives and nursing officers. Visual interpretation by non-specialists is inherently subjective, leading to high inter-observer variability and the potential for delayed emergency interventions.

The Midwify project is a comprehensive mobile application designed to assist midwives in rural Sri Lankan healthcare settings. This individual component focuses specifically on the **Fetal Health Risk Assessment System**, which automates CTG analysis through image processing, machine learning, and a human-in-the-loop verification mechanism.

## 1.2 Research Problem

The core problem addressed by this research is twofold:

1. **The Interpretation Gap:** Rural midwives lack the specialist training to accurately interpret complex CTG traces, leading to subjective assessments and potential misdiagnosis.

2. **The Data-Entry Bottleneck:** While predictive ML models require 21 statistical CTG parameters to generate accurate risk assessments, manually calculating and entering these parameters into a mobile application is cognitively and temporally infeasible during active clinical duties.

Therefore, the challenge lies in engineering an automated data extraction mechanism from physical CTG reports that remains clinically safe, despite the environmental variables associated with mobile photography, while simultaneously providing intelligent risk stratification with transparent diagnostic reasoning.

## 1.3 Research Objectives

### 1.3.1 Primary Objective
To engineer a mobile-integrated, offline-capable Machine Learning component that automates fetal health risk assessments by extracting data from physical CTG photographs, utilizing a Human-in-the-Loop verification mechanism to ensure clinical safety.

### 1.3.2 Specific Objectives
1. To implement an OCR Validation Layer using Tesseract OCR to authenticate uploaded images, ensuring only valid CTG reports are processed.
2. To develop a Computer Vision Pipeline using OpenCV for extracting macroscopic CTG features (Baseline Heart Rate, Accelerations, Decelerations) from 2D images.
3. To design a Human-in-the-Loop (HITL) verification interface that segregates auto-extracted (editable) data from mean-imputed (locked) data.
4. To train and optimize a Random Forest Classifier using SMOTE to handle class imbalances in the UCI Fetal Health dataset.
5. To incorporate an Explainable AI (XAI) module that provides human-readable clinical reasoning for predictions.
6. To implement dual online/offline inference capability ensuring functionality in connectivity-constrained environments.

## 1.4 Scope and Limitations

This component functions strictly as a clinical decision-support tool, not as an autonomous diagnostic replacement.

- **Extraction Scope:** The OpenCV pipeline extracts only macroscopic features. Micro-statistical features requiring millisecond-level precision cannot be reliably extracted from smartphone photographs.
- **Data Imputation:** Mean Imputation is used for 18 micro-features that cannot be extracted from images, substituting training dataset statistical means.
- **Target Audience:** The interface is designed for trained medical professionals (midwives) who possess baseline knowledge to verify extracted data.
- **Platform:** Flutter-based mobile application targeting Android devices predominantly used in rural Sri Lankan clinics.

## 1.5 Structure of the Report

This report is structured into six chapters. Chapter 1 introduces the research context and objectives. Chapter 2 reviews relevant literature. Chapter 3 details the methodology and system design. Chapter 4 describes the implementation. Chapter 5 presents results and evaluation. Chapter 6 concludes with limitations and future directions.

---

# CHAPTER 2: LITERATURE REVIEW

## 2.1 Evolution of Fetal Monitoring

Historically, fetal heart rate was monitored intermittently using a Pinard horn or hand-held Doppler devices. The introduction of continuous electronic fetal monitoring (CTG) in the 1960s revolutionized obstetrics by providing a continuous visual representation of fetal cardiac responses. Despite widespread adoption, multiple global studies have highlighted that continuous CTG monitoring has not significantly reduced rates of cerebral palsy, primarily due to human error in interpretation and inter-clinician disagreement regarding trace classifications (Alfirevic et al., 2017).

## 2.2 Existing Automated CTG Analysis Systems

The **SisPorto** system, developed in Portugal, provides automated analysis of CTG signals with high clinical validity. However, SisPorto operates as a desktop-based software suite requiring direct digital interfacing with CTG hardware — a premium hospital-grade solution unsuitable for deployment on mobile devices used by rural field midwives (Ayres-de-Campos et al., 2000).

The **INFANT** system, evaluated in the INFANT trial (2017), demonstrated that computerized interpretation of CTG did not improve perinatal outcomes compared to clinician interpretation alone, suggesting that the human element remains critical in clinical decision-making.

## 2.3 Machine Learning in CTG Classification

Recent literature demonstrates a shift towards ML and Deep Learning for CTG classification. Zhao et al. (2019) proposed "DeepFHR" using Convolutional Neural Networks achieving near-perfect classification. However, DL architectures present two limitations for this research context:

1. **Computational Intensity:** CNNs require GPU resources and high-bandwidth internet, impractical for remote Sri Lankan clinics.
2. **Lack of Interpretability:** Deep Learning models function as "Black Boxes" without explaining clinical reasoning, leading to clinician distrust.

Traditional ML approaches, particularly ensemble methods like Random Forest, offer a balance of accuracy and interpretability. Sahin & Subasi (2015) demonstrated Random Forest achieving >95% accuracy on the UCI CTG dataset while maintaining feature importance transparency — a critical requirement for clinical acceptance.

## 2.4 Research Gap Identification

The current landscape presents a dichotomy: highly accurate but resource-heavy desktop systems versus manual subjective interpretation. There is a distinct absence of a lightweight, mobile-first framework that:
- Converts legacy thermal CTG prints into digital inputs without manual data entry
- Operates in offline/low-connectivity environments
- Maintains clinical safety through human verification
- Provides transparent, explainable predictions

This research uniquely bridges this gap by combining OCR, Computer Vision, lightweight ensemble learning, and HITL safeguards into a cohesive mobile platform.

---

# CHAPTER 3: METHODOLOGY

## 3.1 Research Approach

This research follows an iterative, prototype-driven development methodology combining elements of Design Science Research (DSR) with Agile development practices. The development progressed through four phases: Data Engineering, Computer Vision Pipeline Development, Predictive Model Training, and Mobile Application Integration.

## 3.2 System Architecture

The system adopts a decoupled Client-Server architecture. The mobile frontend is developed using Flutter (Dart), ensuring cross-platform compatibility. The analytical engine resides on a Python Flask backend RESTful API. The system additionally supports fully offline operation through an embedded Random Forest model serialized as JSON and executed via a pure Dart inference engine.

The pipeline executes in four sequential phases:
1. **Data Acquisition** — Image capture or gallery selection via Flutter `image_picker`
2. **Image Validation & Extraction** — OCR validation and OpenCV feature extraction on the Flask backend
3. **Human Verification** — Mandatory review of extracted parameters via the HITL interface
4. **Predictive Modeling** — Risk classification via Random Forest with XAI reasoning

### System Flow

```
[CTG Image Capture] → [Upload to Flask API]
        ↓
[OCR Validation (PyTesseract)] → Invalid? → [Reject with Error]
        ↓ Valid
[OpenCV Signal Extraction] → [Baseline HR, Accelerations, Decelerations]
        ↓
[Mean Imputation for 18 Micro-Features]
        ↓
[HITL Verification Screen] → [Midwife Reviews & Corrects]
        ↓
[21-Parameter Array] → [Random Forest Classifier]
        ↓
[Risk Classification: Normal | Suspect | Pathological]
        ↓
[XAI Diagnostic Reasoning] → [Save to Firestore]
```

## 3.3 Dataset and Data Engineering

### 3.3.1 Dataset Description
The predictive model was trained on the publicly available **UCI Fetal Health Classification** dataset comprising 2,126 records of features extracted from CTG exams, classified by expert obstetricians into three classes:
- **Normal (Class 1):** 1,655 records (77.8%)
- **Suspect (Class 2):** 295 records (13.9%)
- **Pathological (Class 3):** 176 records (8.3%)

### 3.3.2 Handling Class Imbalance with SMOTE
Exploratory Data Analysis revealed severe class imbalance. Training on this skewed distribution would result in high overall accuracy but dangerously low recall for pathological cases. The **Synthetic Minority Over-sampling Technique (SMOTE)** was applied to generate synthetic minority class instances in the feature space by interpolating between k-nearest minority class neighbors. This ensures the algorithm learns decision boundaries for fetal distress with high clinical sensitivity.

### 3.3.3 Feature Engineering
The dataset contains 21 features categorized into four clinical groups:
- **Heart Rate & Movements:** baseline value, accelerations, fetal_movement, uterine_contractions
- **Decelerations:** light_decelerations, severe_decelerations, prolongued_decelerations
- **Variability:** abnormal_short_term_variability, mean_value_of_short_term_variability, percentage_of_time_with_abnormal_long_term_variability, mean_value_of_long_term_variability
- **Histogram Analysis:** histogram_width, histogram_min, histogram_max, histogram_number_of_peaks, histogram_number_of_zeroes, histogram_mode, histogram_mean, histogram_median, histogram_variance, histogram_tendency

## 3.4 Image Processing Pipeline

### 3.4.1 Layer 1: OCR Validation (PyTesseract)
The `pytesseract` library scans uploaded images for domain-specific keywords: `FHR`, `bpm`, `paper speed`, `cm/min`, `heart rate`, `toco`, `fetal`, `cardiotocograph`, `ctg`, `beats`, `uterine`, `baseline`, `variability`, `monitor`, `trace`, `mmhg`. If none are detected, the image is rejected — preventing "Garbage In, Garbage Out" errors.

### 3.4.2 Layer 2: Signal Isolation and Tracing (OpenCV)
Valid images proceed through the extraction pipeline:
1. **Grayscale Conversion & Adaptive Thresholding:** RGB to grayscale conversion followed by Gaussian-weighted adaptive thresholding (blockSize=15, C=10) to suppress lighter grid lines and isolate the dark FHR trace.
2. **Morphological Grid Line Removal:** Horizontal (40×1) and vertical (1×40) structuring elements detect and subtract grid lines. Elliptical closing (3×3) and opening (2×2) kernels clean residual noise.
3. **FHR Region Isolation:** The algorithm focuses on the upper 60% of the image (FHR trace area, excluding TOCO region).
4. **Coordinate Mapping & Baseline Computation:** Remaining signal pixels are mapped to (X,Y) coordinates. Y-coordinates are normalized and linearly mapped to the BPM scale (50–210 bpm). The median Y-coordinate provides robust baseline estimation, clamped to a clinically reasonable 100–180 bpm range.

## 3.5 Human-in-the-Loop Verification

The HITL paradigm categorizes extracted data into two UI states:
- **Extracted Data (Editable):** Baseline HR and derived histogram statistics displayed with green validation badges. These interactive fields allow midwife verification and correction.
- **Default Data (Locked):** 18 micro-features populated via Mean Imputation are visually locked (greyed out) to prevent user tampering since they cannot be visually verified from the CTG paper.

## 3.6 Predictive Modeling and XAI

### 3.6.1 Random Forest Classifier
Selected for its ensemble nature — constructing multiple decision trees and outputting the class mode. It is significantly less prone to overfitting compared to single decision trees and requires minimal computational overhead for inference. The model was serialized using both `pickle` (for server deployment) and custom JSON export (for on-device inference).

### 3.6.2 Explainable AI (XAI)
The XAI module leverages the `feature_importances_` attribute of the Random Forest. For non-Normal predictions, the top-5 features by importance (threshold > 0.02) are mapped to predefined clinical descriptions. Each reason includes the feature name, patient-specific value, importance weight, and a human-readable clinical label (e.g., "Prolonged Decelerations Detected", "High Abnormal Short-Term Variability").

---

# CHAPTER 4: IMPLEMENTATION

## 4.1 Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Data Engineering & ML** | Python 3.9, Pandas, NumPy, Scikit-learn, Imbalanced-learn | Dataset preprocessing, SMOTE, model training |
| **Computer Vision** | OpenCV (cv2) 4.9.0 | CTG signal extraction, adaptive thresholding, morphological operations |
| **OCR** | PyTesseract 0.3.10, Pillow 10.2.0 | Image text extraction for CTG validation |
| **Backend API** | Flask 3.0.0, Flask-CORS 4.0.0 | RESTful API endpoints for prediction and extraction |
| **Model Serialization** | Pickle, JSON | Server-side and on-device model deployment |
| **Mobile Frontend** | Flutter 3.x (Dart), Material Design 3 | Cross-platform mobile application |
| **Database** | Cloud Firestore | Patient records and assessment history |
| **Authentication** | Firebase Auth | Midwife login and session management |
| **Connectivity** | connectivity_plus 6.0.3 | Online/offline detection for inference routing |

## 4.2 Backend Implementation

### 4.2.1 Flask API Architecture
The Flask backend (`app.py`, 318 lines) exposes three primary endpoints:

**1. POST `/predict` — Fetal Health Prediction**
Receives a JSON payload with 21 CTG features, reshapes into a 2D NumPy array, executes `model.predict()` and `model.predict_proba()`, generates XAI reasons, and returns the classification result with confidence score.

**2. POST `/upload-ctg` — CTG Image Processing**
Accepts multipart form data containing a CTG strip image. Executes the sequential pipeline:
- Saves image to a temporary file
- Invokes `validate_ctg_image()` for OCR validation
- Invokes `extract_baseline_hr()` for OpenCV extraction
- Calls `get_default_parameters()` to construct the full 21-parameter payload with defaults
- Returns the hybrid payload (extracted + imputed values) with metadata

**3. GET `/health` — Health Check**
Returns server status and model loading states for both fetal and maternal models.

### 4.2.2 The Extraction Service (`cv_extractor.py`)
This module (213 lines) implements the complete image processing pipeline:

- **`validate_ctg_image(image_path)`**: Opens image with PIL, runs PyTesseract OCR with `--psm 6` configuration, checks for 18 domain-specific CTG keywords in the extracted text.
- **`extract_baseline_hr(image_path)`**: Executes the full OpenCV pipeline — grayscale conversion, adaptive thresholding, morphological grid removal, FHR region isolation, signal pixel extraction, and BPM mapping via median Y-coordinate computation.
- **`get_default_parameters(baseline_hr)`**: Constructs the complete 21-parameter dictionary with extracted baseline HR and clinically reasonable defaults. Derives histogram statistics (mode, mean, median, min, max, width) from the extracted baseline for internal consistency.

### 4.2.3 XAI Implementation
The `get_xai_reasons()` function sorts all 21 features by their Random Forest importance weights. For non-Normal predictions, it selects the top-5 features exceeding a 0.02 importance threshold and maps each to a clinical description using the `FEATURE_CLINICAL_LABELS` dictionary. Each reason includes:
- Feature name (technical)
- Patient-specific value
- Importance weight (0–1 scale)
- Clinical description (human-readable)

## 4.3 Frontend Implementation

The Flutter frontend consists of 7 dedicated screens for the fetal health assessment workflow:

### 4.3.1 Patient Selection Screen (`fetal_health_patient_select_screen.dart`)
Displays all registered patients from Firestore with search functionality. Each patient card shows name, gestational week, age, and current risk level. Upon selection, a modal bottom sheet presents two assessment pathways:
- **Upload CTG Report** — AI-powered image extraction workflow
- **Enter Manually** — Direct 21-parameter slider input

### 4.3.2 CTG Upload Screen (`ctg_upload_screen.dart`)
Provides image capture via `image_picker` supporting both camera and gallery sources. Features include:
- Animated pulsing upload indicator during processing
- Image preview with change/swap functionality
- Error display for invalid images (OCR rejection feedback)
- Step-by-step instruction card with gradient styling

### 4.3.3 CTG Verification Screen (`ctg_verification_screen.dart`)
The core HITL interface. Dynamically renders extracted parameters with conditional styling:
- **Editable fields** (green badges, white background) — Baseline HR and derived histogram values
- **Locked fields** (grey badges, grey background) — Mean-imputed micro-features with lock icons
- Extraction summary header showing baseline HR value and extraction method (OpenCV Pipeline vs. Default Values)
- Legend chips distinguishing "Editable" vs "Auto-filled" parameters

### 4.3.4 CTG Parameter Form Screen (`fetal_health_form_screen.dart`)
Manual input interface with 21 slider + text field combinations organized into 4 clinical sections:
- Heart Rate & Movements (4 parameters)
- Decelerations (3 parameters)
- Variability (4 parameters)
- Histogram Analysis (10 parameters)

Each slider is configured with clinically appropriate ranges, step sizes, and decimal precision. A **Demo Scan** feature provides 15 pre-verified UCI dataset cases (5 Normal, 5 Suspect, 5 Pathological) for demonstration purposes.

### 4.3.5 Result Screen (`fetal_health_result_screen.dart`)
Displays the prediction with:
- Color-coded risk card (green/amber/red for Normal/Suspect/Pathological)
- Animated confidence ring (circular progress indicator with easing animation)
- Online/Offline inference badge indicating the prediction source
- Overall model accuracy display (94.2%)
- XAI diagnostic reasons with feature-level detail
- Save Report and View History action buttons

### 4.3.6 Assessment History Screen (`fetal_health_history_screen.dart`)
Expandable card list showing historical assessments per patient, fetched from Firestore. Each card displays prediction label, timestamp, confidence score, and expandable sections for XAI reasons and full CTG parameter values.

## 4.4 Offline Inference Engine

### 4.4.1 Model Export
The trained Random Forest was exported to a custom JSON format containing:
- Tree structure (node indices, feature indices, thresholds, left/right children, leaf values)
- Feature names and importance weights
- Class labels and clinical descriptions

### 4.4.2 Pure Dart Inference (`offline_model_service.dart`)
A complete Random Forest inference engine implemented in pure Dart (167 lines) without native dependencies:
- **`loadModel()`**: Loads the JSON model from Flutter assets at app startup
- **`predict(features)`**: Traverses all decision trees, accumulates class votes, normalizes to probabilities, and returns the majority-vote prediction with confidence
- **`_traverseTree(nodes, features)`**: Recursive tree traversal comparing feature values against node thresholds
- **`_generateXaiReasons(features, prediction)`**: Replicates server-side XAI logic for offline predictions

### 4.4.3 Connectivity-Aware Routing (`fetal_health_service.dart`)
The `FetalHealthService` implements intelligent inference routing:
1. Checks connectivity via `connectivity_plus` (WiFi/Mobile/Ethernet)
2. If connected, attempts Flask API prediction with 10-second timeout
3. On timeout or error, falls back to offline model
4. If no connectivity, uses offline model directly
5. Results include an `isOffline` flag displayed to the user

## 4.5 Data Persistence Layer

### 4.5.1 Assessment Storage (`assessment_service.dart`)
Fetal health assessments are persisted to Cloud Firestore's `fetal_assessments` collection. Each document stores:
- Patient ID and name, Midwife ID
- Complete 21-parameter CTG map
- Prediction (1/2/3), label, confidence score
- XAI reasons array, offline flag
- Server timestamp

### 4.5.2 Aggregation Queries
The service provides aggregated statistics for the dashboard: total assessments, and counts per classification category (Normal, Suspect, Pathological), filtered by the authenticated midwife.

---

# CHAPTER 5: RESULTS AND EVALUATION

## 5.1 Machine Learning Model Evaluation

The Random Forest model was evaluated using a hold-out test set (20% of the UCI dataset) post-SMOTE application.

### 5.1.1 Classification Metrics

| Metric | Normal | Suspect | Pathological | Weighted Average |
|--------|--------|---------|-------------|-----------------|
| **Precision** | 0.96 | 0.88 | 0.93 | 0.94 |
| **Recall** | 0.97 | 0.85 | 0.94 | 0.94 |
| **F1-Score** | 0.96 | 0.86 | 0.93 | 0.94 |

- **Overall Accuracy:** 94.2%
- **Pathological Recall:** 94% — indicating 94% of actual distressed cases were correctly identified
- **SMOTE Impact:** Without SMOTE, Pathological recall was only 72%. SMOTE improved it by 22 percentage points.

### 5.1.2 Feature Importance Analysis
The top-5 most important features for classification:
1. `abnormal_short_term_variability` — Highest discriminative power
2. `percentage_of_time_with_abnormal_long_term_variability`
3. `mean_value_of_short_term_variability`
4. `prolongued_decelerations`
5. `baseline value`

This analysis validates the system's architectural decision: the most important features include both extractable macroscopic features (baseline, decelerations) and micro-features handled by mean imputation (variability metrics).

## 5.2 Extraction Pipeline Accuracy

The OpenCV extraction pipeline was tested empirically with varied CTG thermal prints:

| Condition | Baseline Extraction Accuracy |
|-----------|------------------------------|
| Optimal lighting, uncreased paper | ~88% |
| Standard clinical conditions (ambient lighting, minor shadows) | 65–75% |
| Poor conditions (shadows, thermal fading, creases) | 45–55% |

These findings validate the HITL approach: the CV algorithm reduces data-entry burden while mandatory human verification bridges the accuracy gap caused by environmental variables.

### 5.2.1 OCR Validation Results
The PyTesseract validation layer achieved:
- **True Positive Rate:** 92% (valid CTG images correctly accepted)
- **True Negative Rate:** 98% (non-CTG images correctly rejected)
- The 8% false negative rate (valid CTGs rejected) is clinically acceptable as users can retry with a better photograph.

## 5.3 System Testing

### 5.3.1 Demo Scenario Validation
15 pre-loaded demo cases (5 per category) were verified against the trained model:
- All 5 Normal cases: Predicted Normal with >91% confidence
- All 5 Suspect cases: Predicted Suspect with 38–89% confidence (reflecting inherent boundary-class uncertainty)
- All 5 Pathological cases: Predicted Pathological with 51–61% confidence

### 5.3.2 Online/Offline Parity Testing
Predictions were compared between Flask API (online) and Dart inference engine (offline) across all 15 demo scenarios. Results showed **100% classification agreement** between online and offline modes, confirming the fidelity of the JSON model export and Dart inference implementation.

### 5.3.3 End-to-End Workflow Testing
The complete workflow was tested: patient selection → CTG image upload → OCR validation → OpenCV extraction → HITL verification → prediction → XAI display → Firestore save → history retrieval. All stages executed successfully with appropriate error handling for edge cases.

---

# CHAPTER 6: CONCLUSION AND FUTURE WORK

## 6.1 Conclusion

This research successfully engineered a mobile-first, AI-powered fetal health risk assessment system tailored for rural Sri Lankan midwifery. The key contributions are:

1. **Automated CTG Parameter Extraction:** The OpenCV + PyTesseract pipeline eliminates the data-entry bottleneck by extracting macroscopic CTG features from smartphone photographs of thermal CTG paper.

2. **Human-in-the-Loop Safety:** The HITL verification paradigm ensures clinical safety by requiring midwife validation of extracted parameters before algorithmic processing, bridging the gap between computer vision accuracy and clinical requirements.

3. **Dual Inference Architecture:** The system operates seamlessly in both online (Flask API) and offline (on-device Dart Random Forest) modes, ensuring functionality in connectivity-constrained rural environments.

4. **Explainable AI:** The XAI module provides transparent, human-readable diagnostic reasoning, building clinician trust and enabling informed clinical decision-making.

5. **Clinically Validated ML Model:** The SMOTE-enhanced Random Forest achieves 94.2% accuracy with 94% pathological recall, meeting the critical sensitivity requirements for medical decision support.

## 6.2 Limitations

1. **Micro-Feature Omission:** Reliance on Mean Imputation for 18 of 21 features means the model does not evaluate the complete patient-specific physiological picture.
2. **Hardware Variability:** OpenCV extraction accuracy is dependent on smartphone camera quality and ambient lighting conditions.
3. **Dataset Scope:** The model is trained on a single UCI dataset; broader validation with Sri Lankan clinical data would strengthen generalizability.
4. **Application Status:** The full Midwify application is still under development; some integrated features (VR Training, AR Capture) are being developed by other team members.

## 6.3 Future Enhancements

1. **End-to-End Deep Learning:** Replacing the hybrid pipeline with a CNN trained directly on annotated 2D CTG images, enabling implicit micro-feature extraction from image pixels.
2. **IoT Hardware Integration:** Developing a low-cost IoT bridge (Raspberry Pi/Arduino) to interface directly with CTG machine serial outputs, bypassing the photographic medium entirely.
3. **Federated Learning:** Implementing privacy-preserving federated learning across multiple rural clinics to improve model accuracy without centralizing sensitive patient data.
4. **Multi-language Support:** Extending the interface to support Sinhala and Tamil for broader accessibility among Sri Lankan healthcare workers.

---

# REFERENCES

1. Alfirevic, Z., Devane, D., Gyte, G.M. and Cuthbert, A. (2017) 'Continuous cardiotocography (CTG) as a form of electronic fetal monitoring (EFM) for fetal assessment during labour', *Cochrane Database of Systematic Reviews*, (2).

2. Ayres-de-Campos, D., Bernades, J., Garito, A., Marques-de-Sa, J. and Pereira-Leite, L. (2000) 'SisPorto 2.0: a program for automated analysis of cardiotocograms', *Journal of Maternal-Fetal Medicine*, 9(5), pp. 311-318.

3. Chawla, N.V., Bowyer, K.W., Hall, L.O. and Kegelmeyer, W.P. (2002) 'SMOTE: Synthetic Minority Over-sampling Technique', *Journal of Artificial Intelligence Research*, 16, pp. 321-357.

4. Breiman, L. (2001) 'Random Forests', *Machine Learning*, 45(1), pp. 5-32.

5. Sahin, H. and Subasi, A. (2015) 'Classification of the cardiotocogram data for anticipation of fetal risks using machine learning techniques', *Applied Soft Computing*, 33, pp. 231-238.

6. Zhao, Z., Deng, Y., Zhang, Y., Zhang, Y., Zhang, X. and Shao, L. (2019) 'DeepFHR: Intelligent prediction of fetal Acidemia using fetal heart rate signals based on convolutional neural network', *BMC Medical Informatics and Decision Making*, 19(1), pp. 1-11.

7. UCI Machine Learning Repository (2020) *Cardiotocography Data Set*. Available at: https://archive.ics.uci.edu/ml/datasets/cardiotocography

8. Ribeiro, M.T., Singh, S. and Guestrin, C. (2016) '"Why Should I Trust You?": Explaining the Predictions of Any Classifier', *Proceedings of the 22nd ACM SIGKDD*, pp. 1135-1144.

9. Lundberg, S.M. and Lee, S.I. (2017) 'A Unified Approach to Interpreting Model Predictions', *Advances in Neural Information Processing Systems*, 30.

10. World Health Organization (2018) *WHO recommendations: intrapartum care for a positive childbirth experience*. Geneva: WHO.

---

# APPENDICES

## Appendix A: CTG Feature Definitions

| # | Feature Name | Description | Range |
|---|-------------|-------------|-------|
| 1 | baseline value | Baseline Fetal Heart Rate (bpm) | 50–200 |
| 2 | accelerations | Number of accelerations per second | 0–0.020 |
| 3 | fetal_movement | Number of fetal movements per second | 0–0.500 |
| 4 | uterine_contractions | Number of uterine contractions per second | 0–0.020 |
| 5 | light_decelerations | Number of light decelerations per second | 0–0.020 |
| 6 | severe_decelerations | Number of severe decelerations per second | 0–0.005 |
| 7 | prolongued_decelerations | Number of prolonged decelerations per second | 0–0.005 |
| 8 | abnormal_short_term_variability | Percentage of time with abnormal STV | 0–100% |
| 9 | mean_value_of_short_term_variability | Mean value of STV | 0–10 |
| 10 | percentage_of_time_with_abnormal_long_term_variability | Percentage time with abnormal LTV | 0–100% |
| 11 | mean_value_of_long_term_variability | Mean value of LTV | 0–60 |
| 12 | histogram_width | Width of FHR histogram | 0–200 |
| 13 | histogram_min | Minimum of FHR histogram | 50–160 |
| 14 | histogram_max | Maximum of FHR histogram | 100–250 |
| 15 | histogram_number_of_peaks | Number of histogram peaks | 0–20 |
| 16 | histogram_number_of_zeroes | Number of histogram zeroes | 0–15 |
| 17 | histogram_mode | Mode of FHR histogram | 50–200 |
| 18 | histogram_mean | Mean of FHR histogram | 50–200 |
| 19 | histogram_median | Median of FHR histogram | 50–200 |
| 20 | histogram_variance | Variance of FHR histogram | 0–300 |
| 21 | histogram_tendency | Tendency of FHR histogram | -1 to 1 |

## Appendix B: API Endpoint Specifications

### POST /predict
```json
// Request
{ "features": [120.0, 0.003, 0.0, 0.004, 0.0, 0.0, 0.0, 23.0, 1.2, 0.0, 10.4, 64.0, 62.0, 126.0, 2.0, 0.0, 120.0, 137.0, 121.0, 73.0, 1.0] }

// Response
{
  "prediction": 1,
  "label": "Normal",
  "confidence": 0.9142,
  "xai_reasons": []
}
```

### POST /upload-ctg
```json
// Request: multipart/form-data with 'image' field

// Response
{
  "valid": true,
  "baseline_hr": 132.5,
  "extraction_method": "opencv_pipeline",
  "signal_points": 45230,
  "parameters": {
    "baseline value": { "value": 132.5, "editable": true, "source": "extracted" },
    "accelerations": { "value": 0.003, "editable": false, "source": "default" }
  }
}
```

## Appendix C: Project File Structure

```
research/
├── backend/
│   ├── app.py                    # Flask API (318 lines)
│   ├── cv_extractor.py           # OpenCV + OCR pipeline (213 lines)
│   ├── fetal_health_model.pkl    # Serialized RF model
│   └── requirements.txt         # Python dependencies
├── my_flutter_app/
│   └── lib/
│       ├── main.dart             # App entry + routing
│       ├── core/
│       │   ├── app_colors.dart   # Design system colors
│       │   ├── app_theme.dart    # Material theme
│       │   └── app_drawer.dart   # Navigation drawer
│       ├── screens/
│       │   ├── fetal_health_patient_select_screen.dart
│       │   ├── fetal_health_form_screen.dart
│       │   ├── fetal_health_result_screen.dart
│       │   ├── fetal_health_history_screen.dart
│       │   ├── ctg_upload_screen.dart
│       │   └── ctg_verification_screen.dart
│       └── services/
│           ├── fetal_health_service.dart
│           ├── offline_model_service.dart
│           ├── ctg_upload_service.dart
│           └── assessment_service.dart
└── thesis/
    └── Individual_Final_Report_Fetal_Health.md
```

