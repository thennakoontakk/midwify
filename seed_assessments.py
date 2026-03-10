import firebase_admin
from firebase_admin import credentials, firestore, auth
import random
from datetime import datetime, timedelta

# Initialize Firebase Admin SDK
cred = credentials.Certificate('midwify-3f933-firebase-adminsdk-fbsvc-b4359b0fb9.json')
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app(cred)

db = firestore.client()

def get_recent_midwives(limit=10):
    """Fetch recent midwives from Firestore."""
    midwives_ref = db.collection('midwives')
    # The database seems to use lowercase 'active'
    docs = midwives_ref.where('status', '==', 'active').limit(limit).stream()
    found = [{'id': doc.id, 'data': doc.to_dict()} for doc in docs]
    print(f"Found {len(found)} active midwives in Firestore.")
    return found

def get_patients_for_midwife(midwife_id, limit=3):
    """Fetch some patients for a given midwife."""
    patients_ref = db.collection('patients')
    docs = patients_ref.where('midwifeId', '==', midwife_id).limit(limit).stream()
    return [{'id': doc.id, 'data': doc.to_dict()} for doc in docs]

def generate_ctg_params(prediction):
    """Generate realistic CTG parameters based on prediction type."""
    # prediction: 1=Normal, 2=Suspect, 3=Pathological
    if prediction == 1:
        return {
            "baseline_value": random.uniform(120, 150),
            "accelerations": random.uniform(0.003, 0.015),
            "fetal_movement": random.uniform(0, 0.05),
            "uterine_contractions": random.uniform(0, 0.01),
            "prolongued_decelerations": 0.0,
            "abnormal_short_term_variability": random.uniform(20, 40),
            "percentage_of_time_with_abnormal_long_term_variability": random.uniform(0, 5),
        }
    elif prediction == 2:
        return {
            "baseline_value": random.uniform(100, 160),
            "accelerations": random.uniform(0, 0.003),
            "fetal_movement": random.uniform(0, 0.1),
            "uterine_contractions": random.uniform(0, 0.015),
            "prolongued_decelerations": random.uniform(0, 0.001),
            "abnormal_short_term_variability": random.uniform(40, 60),
            "percentage_of_time_with_abnormal_long_term_variability": random.uniform(5, 20),
        }
    else: # Pathological
        return {
            "baseline_value": random.uniform(90, 180),
            "accelerations": 0.0,
            "fetal_movement": random.uniform(0, 0.2),
            "uterine_contractions": random.uniform(0, 0.02),
            "prolongued_decelerations": random.uniform(0.001, 0.005),
            "abnormal_short_term_variability": random.uniform(60, 90),
            "percentage_of_time_with_abnormal_long_term_variability": random.uniform(20, 100),
        }

def seed_assessments():
    print("Starting Fetal Health Assessment Seeding...")
    
    midwives = get_recent_midwives()
    if not midwives:
        print("No midwives found to associate assessments with.")
        return

    total_seeded = 0
    
    for mw in midwives:
        mw_id = mw['id']
        mw_name = mw['data'].get('fullName', 'Unknown Midwife')
        print(f"\nProcessing Midwife: {mw_name} ({mw_id})")
        
        patients = get_patients_for_midwife(mw_id)
        if not patients:
            print(f"  No patients found for this midwife. Skipping.")
            continue
            
        for pt in patients:
            pt_id = pt['id']
            pt_name = pt['data'].get('fullName', 'Unknown Patient')
            
            # Seed 1-2 assessments per patient
            num_assessments = random.randint(1, 2)
            
            for i in range(num_assessments):
                # Randomly pick prediction type
                # 70% Normal, 20% Suspect, 10% Pathological
                rand_val = random.random()
                if rand_val < 0.7:
                    prediction = 1
                    label = "Normal"
                elif rand_val < 0.9:
                    prediction = 2
                    label = "Suspect"
                else:
                    prediction = 3
                    label = "Pathological"
                
                confidence = random.uniform(0.85, 0.99)
                ctg_params = generate_ctg_params(prediction)
                
                # Mock XAI reasons
                reasons = [
                    {"feature": "Accelerations", "impact": "Positive" if prediction == 1 else "Negative", "weight": random.uniform(0.1, 0.4)},
                    {"feature": "STV", "impact": "Positive" if prediction == 1 else "Negative", "weight": random.uniform(0.1, 0.4)}
                ]
                
                # Random created_at within last 7 days
                days_ago = random.randint(0, 7)
                created_at = datetime.now() - timedelta(days=days_ago)
                
                assessment_data = {
                    'patientId': pt_id,
                    'patientName': pt_name,
                    'midwifeId': mw_id,
                    'ctgParameters': ctg_params,
                    'prediction': prediction,
                    'label': label,
                    'confidence': confidence,
                    'xaiReasons': reasons,
                    'wasOffline': False,
                    'createdAt': created_at
                }
                
                db.collection('fetal_assessments').add(assessment_data)
                total_seeded += 1
                print(f"  Seed assessment for {pt_name}: {label}")

    print(f"\nSeeding complete! Total assessments added: {total_seeded}")

if __name__ == "__main__":
    seed_assessments()
