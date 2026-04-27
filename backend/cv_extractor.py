"""
Midwify — CTG Image Extraction Module
Uses Tesseract OCR for image validation and OpenCV for signal extraction.
Extracts Baseline FHR, Accelerations, Decelerations, and Histogram statistics
from CTG strip photographs.
"""

import cv2
import numpy as np
import pytesseract
from PIL import Image
from scipy import signal as scipy_signal

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

# ── CTG paper speed assumption ─────────────────────────────────────────
# Standard CTG paper speed is 1 cm/min. A typical strip is ~20-30 cm long.
# We estimate trace duration from image width and assume ~1200 seconds
# (20 minutes) of recording as a reasonable default for normalization.
DEFAULT_TRACE_DURATION_SECONDS = 1200.0

# ── Deceleration/Acceleration thresholds (in BPM above/below baseline) ─
ACCEL_THRESHOLD_BPM = 15.0       # Acceleration: >15 bpm above baseline
LIGHT_DECEL_THRESHOLD_BPM = 15.0 # Light decel: dip of 1–15 bpm below baseline
SEVERE_DECEL_THRESHOLD_BPM = 60.0  # Severe decel: dip >60 bpm below baseline
PROLONGED_DECEL_MIN_WIDTH_FRAC = 0.025  # Prolonged decel: dip spanning >2.5% of trace width

# ── Default parameter values for features that CANNOT be extracted ─────
# These 6 features require millisecond-level beat-to-beat data or
# external sensor input that cannot be reliably obtained from a photo.
MEAN_IMPUTED_DEFAULTS = {
    'fetal_movement':      0.0,
    'uterine_contractions': 0.004,
    'abnormal_short_term_variability': 23.0,
    'mean_value_of_short_term_variability': 1.2,
    'percentage_of_time_with_abnormal_long_term_variability': 0.0,
    'mean_value_of_long_term_variability': 10.0,
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


def _get_smoothed_bpm_trace(bpm_values, x_coords, width):
    """
    Build a smooth 1D BPM trace from scattered (x, bpm) points.
    For each x-column, takes the median BPM, then applies Savitzky-Golay
    smoothing to reduce noise.

    Returns:
        smoothed_trace: 1D numpy array of length `width`, BPM per column
        valid_mask: boolean mask of which columns have data
    """
    # Bin BPM values by x-coordinate
    trace = np.full(width, np.nan)
    for x in range(width):
        mask = x_coords == x
        if np.any(mask):
            trace[x] = np.median(bpm_values[mask])

    # Interpolate small gaps (up to 10px) to get continuous signal
    valid_mask = ~np.isnan(trace)
    if np.sum(valid_mask) < 20:
        return trace, valid_mask

    # Linear interpolation for small gaps
    valid_indices = np.where(valid_mask)[0]
    trace_interp = np.copy(trace)
    for i in range(len(valid_indices) - 1):
        start = valid_indices[i]
        end = valid_indices[i + 1]
        gap = end - start
        if 1 < gap <= 10:  # Only interpolate small gaps
            trace_interp[start:end + 1] = np.linspace(
                trace[start], trace[end], end - start + 1
            )

    # Apply smoothing to reduce noise (window must be odd, >= 5)
    valid_after_interp = ~np.isnan(trace_interp)
    num_valid = np.sum(valid_after_interp)
    if num_valid >= 15:
        # Extract only valid portion for smoothing
        valid_vals = trace_interp[valid_after_interp]
        win_len = min(15, len(valid_vals))
        if win_len % 2 == 0:
            win_len -= 1
        if win_len >= 5:
            smoothed_vals = scipy_signal.savgol_filter(valid_vals, win_len, 3)
            trace_interp[valid_after_interp] = smoothed_vals

    return trace_interp, valid_after_interp


def _detect_accelerations(smoothed_trace, valid_mask, baseline_hr):
    """
    Detect accelerations: regions where BPM > baseline + ACCEL_THRESHOLD_BPM.
    Count distinct acceleration events (contiguous regions above threshold).

    Returns:
        count: number of acceleration events
    """
    above = np.zeros(len(smoothed_trace), dtype=bool)
    for i in range(len(smoothed_trace)):
        if valid_mask[i]:
            above[i] = smoothed_trace[i] > (baseline_hr + ACCEL_THRESHOLD_BPM)

    # Count contiguous regions
    count = 0
    in_accel = False
    for val in above:
        if val and not in_accel:
            count += 1
            in_accel = True
        elif not val:
            in_accel = False

    return count


def _detect_decelerations(smoothed_trace, valid_mask, baseline_hr):
    """
    Detect decelerations from the smoothed BPM trace.

    Returns:
        light_count: dips of 1–15 bpm below baseline
        severe_count: dips >60 bpm below baseline
        prolonged_count: dips >15 bpm below baseline lasting >2.5% of trace width
    """
    trace_len = len(smoothed_trace)
    below_light = np.zeros(trace_len, dtype=bool)
    below_severe = np.zeros(trace_len, dtype=bool)
    below_any = np.zeros(trace_len, dtype=bool)

    for i in range(trace_len):
        if valid_mask[i]:
            drop = baseline_hr - smoothed_trace[i]
            if drop > 0:
                below_any[i] = True
                if drop <= LIGHT_DECEL_THRESHOLD_BPM:
                    below_light[i] = True
                if drop > SEVERE_DECEL_THRESHOLD_BPM:
                    below_severe[i] = True

    # Count contiguous light deceleration regions
    light_count = 0
    in_decel = False
    for val in below_light:
        if val and not in_decel:
            light_count += 1
            in_decel = True
        elif not val:
            in_decel = False

    # Count contiguous severe deceleration regions
    severe_count = 0
    in_decel = False
    for val in below_severe:
        if val and not in_decel:
            severe_count += 1
            in_decel = True
        elif not val:
            in_decel = False

    # Count prolonged decelerations (dips >15bpm below baseline lasting >2.5% of trace)
    min_width = int(trace_len * PROLONGED_DECEL_MIN_WIDTH_FRAC)
    prolonged_count = 0
    below_significant = np.zeros(trace_len, dtype=bool)
    for i in range(trace_len):
        if valid_mask[i]:
            below_significant[i] = (baseline_hr - smoothed_trace[i]) > LIGHT_DECEL_THRESHOLD_BPM

    # Find contiguous runs and check width
    run_start = None
    for i in range(trace_len):
        if below_significant[i]:
            if run_start is None:
                run_start = i
        else:
            if run_start is not None:
                run_width = i - run_start
                if run_width >= min_width:
                    prolonged_count += 1
                run_start = None
    # Check final run
    if run_start is not None:
        run_width = trace_len - run_start
        if run_width >= min_width:
            prolonged_count += 1

    return light_count, severe_count, prolonged_count


def _compute_histogram_features(bpm_values):
    """
    Compute FHR histogram features from the extracted BPM values.
    These match the UCI dataset histogram features.

    Returns:
        dict with histogram_width, histogram_min, histogram_max,
        histogram_number_of_peaks, histogram_number_of_zeroes,
        histogram_mode, histogram_mean, histogram_median,
        histogram_variance, histogram_tendency
    """
    if len(bpm_values) == 0:
        return {}

    # Clamp BPM values to reasonable range
    bpm_clamped = np.clip(bpm_values, 50, 250)

    # Basic statistics
    hist_min = float(np.min(bpm_clamped))
    hist_max = float(np.max(bpm_clamped))
    hist_width = hist_max - hist_min
    hist_mean = float(np.mean(bpm_clamped))
    hist_median = float(np.median(bpm_clamped))
    hist_variance = float(np.var(bpm_clamped))

    # Mode — most frequent BPM value (rounded to nearest integer)
    bpm_rounded = np.round(bpm_clamped).astype(int)
    values, counts = np.unique(bpm_rounded, return_counts=True)
    hist_mode = float(values[np.argmax(counts)])

    # Build histogram with 1-bpm bins for peak and zero counting
    bin_edges = np.arange(int(hist_min), int(hist_max) + 2, 1)
    if len(bin_edges) < 2:
        bin_edges = np.array([int(hist_min), int(hist_min) + 1])
    hist_counts, _ = np.histogram(bpm_clamped, bins=bin_edges)

    # Number of peaks: local maxima in the histogram
    num_peaks = 0
    for i in range(1, len(hist_counts) - 1):
        if hist_counts[i] > hist_counts[i - 1] and hist_counts[i] > hist_counts[i + 1]:
            num_peaks += 1

    # Number of zeroes: bins with zero count (within the range)
    num_zeroes = int(np.sum(hist_counts == 0))

    # Tendency: based on skewness direction
    # -1 = left-skewed (mean < median), 0 = symmetric, 1 = right-skewed (mean > median)
    skew_diff = hist_mean - hist_median
    if abs(skew_diff) < 1.0:
        hist_tendency = 0.0
    elif skew_diff > 0:
        hist_tendency = 1.0
    else:
        hist_tendency = -1.0

    return {
        'histogram_width': round(hist_width, 1),
        'histogram_min': round(hist_min, 1),
        'histogram_max': round(hist_max, 1),
        'histogram_number_of_peaks': float(num_peaks),
        'histogram_number_of_zeroes': float(num_zeroes),
        'histogram_mode': round(hist_mode, 1),
        'histogram_mean': round(hist_mean, 1),
        'histogram_median': round(hist_median, 1),
        'histogram_variance': round(hist_variance, 1),
        'histogram_tendency': hist_tendency,
    }


def extract_ctg_features(image_path):
    """
    Extract all possible CTG features from a CTG strip image.

    OpenCV Pipeline:
        1. Read image and convert to Grayscale
        2. Apply Adaptive Thresholding to remove grid lines and shadows
        3. Morphological operations to clean noise
        4. Extract Y-coordinates of the dark signal trace
        5. Map to BPM scale and build smoothed 1D trace
        6. Detect accelerations and decelerations
        7. Compute histogram statistics from BPM distribution

    Returns:
        dict with:
            'baseline_hr': float (clamped to 100–180 bpm)
            'accelerations': float (per second, UCI format)
            'light_decelerations': float (per second)
            'severe_decelerations': float (per second)
            'prolongued_decelerations': float (per second)
            'histogram_*': float (10 histogram features)
            'extraction_method': str
            'signal_points_detected': int
            'features_extracted': int (count of successfully extracted features)
    """
    try:
        # Step 1: Read image and convert to Grayscale
        img = cv2.imread(image_path)
        if img is None:
            return _fallback_result()

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
        h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (40, 1))
        h_lines = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, h_kernel)
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
        # CTG strips typically have FHR in the top 60% and TOCO in the bottom
        fhr_region = cleaned[0:int(height * 0.6), :]

        # Step 5: Extract signal pixel coordinates
        signal_coords = np.where(fhr_region > 0)
        if len(signal_coords[0]) == 0:
            return _fallback_result()

        y_coords = signal_coords[0]
        x_coords = signal_coords[1]
        fhr_height = int(height * 0.6)

        # Map Y-coordinates to BPM scale
        # In image coordinates: y=0 is top (high BPM), y=max is bottom (low BPM)
        y_normalized = y_coords.astype(float) / fhr_height
        bpm_values = BPM_RANGE_TOP - (y_normalized * (BPM_RANGE_TOP - BPM_RANGE_BOTTOM))

        # Step 6: Compute Baseline HR (median — robust against outliers)
        baseline_hr = float(np.median(bpm_values))
        baseline_hr = max(100.0, min(180.0, baseline_hr))  # Clamp
        baseline_hr = round(baseline_hr, 1)

        # Step 7: Build smoothed 1D trace for event detection
        fhr_width = fhr_region.shape[1]
        smoothed_trace, valid_mask = _get_smoothed_bpm_trace(
            bpm_values, x_coords, fhr_width
        )

        # Step 8: Detect accelerations
        accel_count = _detect_accelerations(smoothed_trace, valid_mask, baseline_hr)
        # Convert to "per second" format as per UCI dataset
        accel_per_sec = round(accel_count / DEFAULT_TRACE_DURATION_SECONDS, 6)

        # Step 9: Detect decelerations
        light_count, severe_count, prolonged_count = _detect_decelerations(
            smoothed_trace, valid_mask, baseline_hr
        )
        light_per_sec = round(light_count / DEFAULT_TRACE_DURATION_SECONDS, 6)
        severe_per_sec = round(severe_count / DEFAULT_TRACE_DURATION_SECONDS, 6)
        prolonged_per_sec = round(prolonged_count / DEFAULT_TRACE_DURATION_SECONDS, 6)

        # Step 10: Compute histogram features from all BPM values
        histogram_features = _compute_histogram_features(bpm_values)

        # Build result
        result = {
            'baseline_hr': baseline_hr,
            'accelerations': accel_per_sec,
            'light_decelerations': light_per_sec,
            'severe_decelerations': severe_per_sec,
            'prolongued_decelerations': prolonged_per_sec,
            'extraction_method': 'opencv_pipeline',
            'signal_points_detected': int(len(y_coords)),
            'features_extracted': 5 + len(histogram_features),  # 5 direct + histogram
        }
        result.update(histogram_features)

        return result

    except Exception as e:
        print(f'[CV Extractor] Error: {e}')
        return _fallback_result()


def _fallback_result():
    """Return fallback values when extraction fails entirely."""
    return {
        'baseline_hr': 120.0,
        'accelerations': 0.003,
        'light_decelerations': 0.0,
        'severe_decelerations': 0.0,
        'prolongued_decelerations': 0.0,
        'histogram_width': 64.0,
        'histogram_min': 62.0,
        'histogram_max': 126.0,
        'histogram_number_of_peaks': 2.0,
        'histogram_number_of_zeroes': 0.0,
        'histogram_mode': 120.0,
        'histogram_mean': 137.0,
        'histogram_median': 121.0,
        'histogram_variance': 73.0,
        'histogram_tendency': 0.0,
        'extraction_method': 'fallback',
        'signal_points_detected': 0,
        'features_extracted': 0,
    }


def get_default_parameters(extracted_features):
    """
    Build the full 21-parameter CTG payload using extracted features,
    calculated histogram stats, and clinically reasonable defaults
    for features that cannot be extracted from images.

    Each parameter is tagged with:
        - value: the numeric value
        - editable: whether the user can edit it in the HITL screen
        - source: 'extracted' | 'calculated' | 'default'

    Args:
        extracted_features: dict from extract_ctg_features()

    Returns:
        dict of all 21 parameters with value/editable/source metadata
    """
    extraction_method = extracted_features.get('extraction_method', 'fallback')
    is_real_extraction = extraction_method == 'opencv_pipeline'

    params = {}

    # ── Extracted features (from OpenCV pipeline directly) ──────────────
    params['baseline value'] = {
        'value': extracted_features.get('baseline_hr', 120.0),
        'editable': True,
        'source': 'extracted' if is_real_extraction else 'default',
    }
    params['accelerations'] = {
        'value': extracted_features.get('accelerations', 0.003),
        'editable': True,
        'source': 'extracted' if is_real_extraction else 'default',
    }
    params['light_decelerations'] = {
        'value': extracted_features.get('light_decelerations', 0.0),
        'editable': True,
        'source': 'extracted' if is_real_extraction else 'default',
    }
    params['severe_decelerations'] = {
        'value': extracted_features.get('severe_decelerations', 0.0),
        'editable': True,
        'source': 'extracted' if is_real_extraction else 'default',
    }
    params['prolongued_decelerations'] = {
        'value': extracted_features.get('prolongued_decelerations', 0.0),
        'editable': True,
        'source': 'extracted' if is_real_extraction else 'default',
    }

    # ── Calculated features (computed from the BPM signal distribution) ─
    histogram_keys = [
        'histogram_width', 'histogram_min', 'histogram_max',
        'histogram_number_of_peaks', 'histogram_number_of_zeroes',
        'histogram_mode', 'histogram_mean', 'histogram_median',
        'histogram_variance', 'histogram_tendency',
    ]
    # Fallback histogram values if not in extracted_features
    histogram_defaults = {
        'histogram_width': 64.0,
        'histogram_min': 62.0,
        'histogram_max': 126.0,
        'histogram_number_of_peaks': 2.0,
        'histogram_number_of_zeroes': 0.0,
        'histogram_mode': 120.0,
        'histogram_mean': 137.0,
        'histogram_median': 121.0,
        'histogram_variance': 73.0,
        'histogram_tendency': 0.0,
    }
    for key in histogram_keys:
        params[key] = {
            'value': extracted_features.get(key, histogram_defaults[key]),
            'editable': True,
            'source': 'calculated' if is_real_extraction else 'default',
        }

    # ── Default features (cannot be extracted from images) ──────────────
    for key, default_val in MEAN_IMPUTED_DEFAULTS.items():
        params[key] = {
            'value': default_val,
            'editable': False,
            'source': 'default',
        }

    return params
