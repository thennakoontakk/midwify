export interface Point3D {
    x: number;
    y: number;
    z: number;
}

export interface CranialMetricsResult {
    CI: number;
    CVAI: number;
    potentialScaphocephaly: boolean;
    potentialBrachycephaly: boolean;
    potentialPlagiocephaly: boolean;
    requiresMedicalReview: boolean;
    isValidAngle: boolean;
    angleError?: string;
}

/**
 * 3D Distance Math Helper
 * Calculates the Euclidean distance between two 3D points.
 * Formula: D = sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
 */
export function calculate3DDistance(p1: Point3D, p2: Point3D): number {
    return Math.sqrt(
        Math.pow(p2.x - p1.x, 2) +
        Math.pow(p2.y - p1.y, 2) +
        Math.pow(p2.z - p1.z, 2)
    );
}

/**
 * Camera Input Constraints & Angle Logic
 * Validates that the camera is positioned at a slight top-down frontal view (approx 30 to 45 degrees).
 * Checks the pitch of the head using the Z-axis (depth) difference between Nose Tip (1) and Forehead (10).
 */
export function validateCameraAngle(landmarks: Point3D[]): { valid: boolean; message?: string } {
    if (!landmarks || landmarks.length < 478) {
        return { valid: false, message: "Invalid landmarks array. Expected 478 landmarks from MediaPipe Face Mesh." };
    }

    const noseTip = landmarks[1];
    const forehead = landmarks[10];

    // In MediaPipe, a smaller Z value means the point is closer to the camera.
    // If looking perfectly straight ahead, the nose tip is significantly closer to the camera than the forehead.
    // If the camera is at a top-down angle, the forehead becomes closer to the camera relative to the nose tip.
    // The difference (forehead.z - noseTip.z) will be large and positive if looking straight ahead.
    // If looking up / camera angled down, this difference decreases and can even become negative.
    
    // Threshold to detect a perfectly flat front-facing profile.
    // This value needs to be calibrated based on the specific camera and MediaPipe scaling, 
    // but a large positive difference indicates the nose is sticking out much further than the forehead.
    const FLAT_PROFILE_Z_DIFF_THRESHOLD = 0.015; // Calibration constant

    const zDiff = forehead.z - noseTip.z;

    if (zDiff > FLAT_PROFILE_Z_DIFF_THRESHOLD) {
        return {
            valid: false,
            message: "Camera angle too low. Please adjust to a slight top-down frontal view (30 to 45 degrees above eye level)."
        };
    }

    return { valid: true };
}

/**
 * Core Processing Logic: Analyze Cranial Metrics
 * Detects signs of Craniosynostosis and Plagiocephaly using MediaPipe Face Mesh landmarks.
 */
export function analyzeCranialMetrics(landmarks: Point3D[]): CranialMetricsResult {
    // 1. Camera Angle Validation
    const angleValidation = validateCameraAngle(landmarks);
    if (!angleValidation.valid) {
        return {
            CI: 0,
            CVAI: 0,
            potentialScaphocephaly: false,
            potentialBrachycephaly: false,
            potentialPlagiocephaly: false,
            requiresMedicalReview: false,
            isValidAngle: false,
            angleError: angleValidation.message
        };
    }

    // 2. Extract Required Landmarks
    // Length Proxies
    const noseTip = landmarks[1];         // Anterior proxy
    const forehead = landmarks[10];       // Glabella/Top of Forehead
    
    // Width Proxies
    const rightCheek = landmarks[234];    // Right Cheek/Temple edge
    const leftCheek = landmarks[454];     // Left Cheek/Temple edge
    
    // Asymmetry Proxies (Diagonals)
    const leftForehead = landmarks[103];  // Left Forehead
    const rightForehead = landmarks[332]; // Right Forehead

    // 3. Mathematical Calculations
    
    // --- A. Estimated Cranial Index (CI) ---
    // Calculate Head Width (W)
    const W = calculate3DDistance(rightCheek, leftCheek);

    // Calculate Head Length (L) proxy
    // Absolute Z-depth differential between Nose Tip (1) and plane of ears/cheeks
    const avgZCheeks = (leftCheek.z + rightCheek.z) / 2;
    const zDepthDiff = Math.abs(noseTip.z - avgZCheeks);
    
    // Scaling constant to account for the unmapped occipital bone
    const OCCIPITAL_SCALING_CONSTANT = 0.04; // Adjust based on calibration
    const L = zDepthDiff + OCCIPITAL_SCALING_CONSTANT;

    // Formula: CI = (W / L) * 100
    const CI = (W / L) * 100;

    const potentialScaphocephaly = CI < 75;
    const potentialBrachycephaly = CI > 85;

    // --- B. Cranial Vault Asymmetry Index (CVAI) ---
    // Measure Diagonal A: Left Forehead (103) to Right Back/Ear plane (234)
    const diagonalA = calculate3DDistance(leftForehead, rightCheek);
    
    // Measure Diagonal B: Right Forehead (332) to Left Back/Ear plane (454)
    const diagonalB = calculate3DDistance(rightForehead, leftCheek);

    // Formula: CVAI = (|Diagonal A - Diagonal B| / Diagonal A) * 100
    const CVAI = (Math.abs(diagonalA - diagonalB) / diagonalA) * 100;

    const potentialPlagiocephaly = CVAI > 3.5;

    // Determine if medical review is required
    const requiresMedicalReview = potentialScaphocephaly || potentialBrachycephaly || potentialPlagiocephaly;

    return {
        CI,
        CVAI,
        potentialScaphocephaly,
        potentialBrachycephaly,
        potentialPlagiocephaly,
        requiresMedicalReview,
        isValidAngle: true
    };
}
