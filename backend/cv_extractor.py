"""
Midwify — CTG Image Extraction Module
Uses Tesseract OCR for image validation and OpenCV for signal extraction.
Extracts approximate Baseline Fetal Heart Rate from CTG strip photographs.
"""

import cv2
import numpy as np
import pytesseract
from PIL import Image

# ── Configure Tesseract path for Windows ───────────────────────────────
import os
import platform
if platform.system() == 'Windows':
    _tesseract_path = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
    if os.path.exists(_tesseract_path):
        pytesseract.pytesseract.tesseract_cmd = _tesseract_path


# ── Keywords that identify a valid CTG strip ───────────────────────────
CTG_KEYWORDS = [
    'fhr', 'bpm', 'paper speed', 'cm/min', 'heart rate',
    'toco', 'ua', 'fetal', 'cardiotocograph', 'ctg',
    'beats', 'uterine', 'baseline', 'variability',
    'monitor', 'trace', 'recording', 'mmhg',
]

# ── BPM scale mapping (typical CTG strip Y-axis) ──────────────────────
# Most CTG strips show FHR from ~50 bpm (bottom) to ~210 bpm (top)
BPM_RANGE_TOP = 210.0
BPM_RANGE_BOTTOM = 50.0

# ── Default parameter values (clinically reasonable for a normal case) ─
# These match the defaults already used in the Flutter app's form
DEFAULT_PARAMETERS = {
    'baseline value':      {'value': 120.0, 'editable': True,  'source': 'extracted'},
    'accelerations':       {'value': 0.003, 'editable': False, 'source': 'default'},
    'fetal_movement':      {'value': 0.0,   'editable': False, 'source': 'default'},
    'uterine_contractions':{'value': 0.004, 'editable': False, 'source': 'default'},
    'light_decelerations': {'value': 0.0,   'editable': False, 'source': 'default'},
    'severe_decelerations':{'value': 0.0,   'editable': False, 'source': 'default'},
    'prolongued_decelerations': {'value': 0.0, 'editable': False, 'source': 'default'},
    'abnormal_short_term_variability': {'value': 23.0, 'editable': False, 'source': 'default'},
    'mean_value_of_short_term_variability': {'value': 1.2, 'editable': False, 'source': 'default'},
    'percentage_of_time_with_abnormal_long_term_variability': {'value': 0.0, 'editable': False, 'source': 'default'},
    'mean_value_of_long_term_variability': {'value': 10.0, 'editable': False, 'source': 'default'},
    'histogram_width':     {'value': 64.0,  'editable': True,  'source': 'default'},
    'histogram_min':       {'value': 62.0,  'editable': True,  'source': 'default'},
    'histogram_max':       {'value': 126.0, 'editable': True,  'source': 'default'},
    'histogram_number_of_peaks':  {'value': 2.0, 'editable': True, 'source': 'default'},
    'histogram_number_of_zeroes': {'value': 0.0, 'editable': True, 'source': 'default'},
    'histogram_mode':      {'value': 120.0, 'editable': True,  'source': 'default'},
    'histogram_mean':      {'value': 137.0, 'editable': True,  'source': 'default'},
    'histogram_median':    {'value': 121.0, 'editable': True,  'source': 'default'},
    'histogram_variance':  {'value': 73.0,  'editable': True,  'source': 'default'},
    'histogram_tendency':  {'value': 0.0,   'editable': True,  'source': 'default'},
}


def validate_ctg_image(image_path):
    """
    Validate whether an uploaded image is a CTG strip using Tesseract OCR.

    Scans the image for CTG-related keywords (FHR, bpm, Paper Speed, etc.).
    Returns:
        (True, '') if at least one keyword is found.
        (False, error_message) if no keywords are found.
    """
    try:
        # Open with PIL for Tesseract
        img = Image.open(image_path)

        # Run OCR — use both default and legacy modes for best coverage
        extracted_text = pytesseract.image_to_string(img, config='--psm 6')
        text_lower = extracted_text.lower()

        # Check for any CTG keyword
        found_keywords = [kw for kw in CTG_KEYWORDS if kw in text_lower]

        if found_keywords:
            return True, ''
        else:
            return False, 'Invalid Image: Please upload a valid CTG strip.'

    except Exception as e:
        return False, f'Image validation error: {str(e)}'


def extract_baseline_hr(image_path):
    """
    Extract the approximate Baseline Fetal Heart Rate from a CTG strip image.

    OpenCV Pipeline:
        1. Read image and convert to Grayscale
        2. Apply Adaptive Thresholding to remove grid lines and shadows
        3. Morphological operations to clean noise
        4. Extract Y-coordinates of the dark signal trace
        5. Map median Y-coordinate to BPM scale

    Returns:
        dict with 'baseline_hr' (float, clamped to 100–180 bpm range)
    """
    try:
        # Step 1: Read image and convert to Grayscale
        img = cv2.imread(image_path)
        if img is None:
            return {'baseline_hr': 120.0, 'extraction_method': 'fallback'}

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        height, width = gray.shape

        # Step 2: Adaptive Thresholding to remove grid and shadows
        # Uses Gaussian-weighted sum of neighbourhood area for threshold
        thresh = cv2.adaptiveThreshold(
            gray, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY_INV,
            blockSize=15,
            C=10
        )

        # Step 3: Morphological operations to clean noise
        # Remove thin grid lines (horizontal and vertical)
        # Horizontal kernel to remove horizontal grid lines
        h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (40, 1))
        h_lines = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, h_kernel)
        # Vertical kernel to remove vertical grid lines
        v_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, 40))
        v_lines = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, v_kernel)
        # Remove detected grid lines from threshold
        cleaned = thresh - h_lines - v_lines
        cleaned = np.clip(cleaned, 0, 255).astype(np.uint8)

        # Further cleanup: close small gaps, remove speckle noise
        close_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
        cleaned = cv2.morphologyEx(cleaned, cv2.MORPH_CLOSE, close_kernel)

        # Remove very small noise blobs
        open_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2, 2))
        cleaned = cv2.morphologyEx(cleaned, cv2.MORPH_OPEN, open_kernel)

        # Step 4: Focus on the upper portion of the image (FHR trace area)
        # CTG strips typically have FHR in the top half and TOCO in the bottom
        fhr_region = cleaned[0:int(height * 0.6), :]

        # Step 5: Extract Y-coordinates of signal pixels
        signal_coords = np.where(fhr_region > 0)
        if len(signal_coords[0]) == 0:
            # No signal found — return sensible default
            return {'baseline_hr': 120.0, 'extraction_method': 'fallback'}

        y_coords = signal_coords[0]
        fhr_height = int(height * 0.6)

        # Step 6: Map Y-coordinates to BPM scale
        # In image coordinates: y=0 is top (high BPM), y=max is bottom (low BPM)
        # Normalize Y positions to [0, 1] range (0=top, 1=bottom)
        y_normalized = y_coords.astype(float) / fhr_height

        # Map to BPM: top of image = BPM_RANGE_TOP, bottom = BPM_RANGE_BOTTOM
        bpm_values = BPM_RANGE_TOP - (y_normalized * (BPM_RANGE_TOP - BPM_RANGE_BOTTOM))

        # Use median for robust baseline estimation (ignores outliers/decelerations)
        baseline_hr = float(np.median(bpm_values))

        # Clamp to clinically reasonable range
        baseline_hr = max(100.0, min(180.0, baseline_hr))

        # Round to nearest integer
        baseline_hr = round(baseline_hr, 1)

        return {
            'baseline_hr': baseline_hr,
            'extraction_method': 'opencv_pipeline',
            'signal_points_detected': int(len(y_coords)),
        }

    except Exception as e:
        print(f'[CV Extractor] Error: {e}')
        return {'baseline_hr': 120.0, 'extraction_method': 'fallback'}


def get_default_parameters(baseline_hr):
    """
    Build the full 21-parameter CTG payload using the extracted baseline HR
    and clinically reasonable defaults for all other parameters.

    Args:
        baseline_hr: Extracted baseline fetal heart rate (float)

    Returns:
        dict of all 21 parameters, each with value/editable/source metadata
    """
    import copy
    params = copy.deepcopy(DEFAULT_PARAMETERS)

    # Set the extracted baseline heart rate
    params['baseline value']['value'] = baseline_hr
    params['baseline value']['source'] = 'extracted'

    # Derive histogram stats from baseline HR for consistency
    params['histogram_mode']['value'] = baseline_hr
    params['histogram_mean']['value'] = round(baseline_hr + 2.0, 1)
    params['histogram_median']['value'] = round(baseline_hr + 1.0, 1)
    params['histogram_min']['value'] = round(max(50.0, baseline_hr - 30.0), 1)
    params['histogram_max']['value'] = round(min(200.0, baseline_hr + 30.0), 1)
    params['histogram_width']['value'] = round(
        params['histogram_max']['value'] - params['histogram_min']['value'], 1
    )

    return params
