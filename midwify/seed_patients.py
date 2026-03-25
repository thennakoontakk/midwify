import firebase_admin
from firebase_admin import credentials, firestore
import datetime
import random

# Initialize Firebase
cred = credentials.Certificate('midwify-3f933-firebase-adminsdk-fbsvc-b4359b0fb9.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

# Constants
BLOOD_GROUPS = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
RISK_LEVELS = ['low', 'medium', 'high']
DIABETES_STATUS = ['none', 'gestational', 'pre-existing']
STATUSES = ['active', 'delivered', 'transferred']

# Dummy names
FIRST_NAMES = ["Anula", "Sunethra", "Kumari", "Nilmini", "Dilini", "Samanthi", "Priyanka", "Malani", "Inoka", "Sanduni"]
LAST_NAMES = ["Silva", "Perera", "Fernando", "Jayasinghe", "Wickramasinghe", "Senanayake", "Bandara", "Gunawardena", "Weerasinghe", "Herath"]

def generate_patient(midwife_id=""):
    first = random.choice(FIRST_NAMES)
    last = random.choice(LAST_NAMES)
    full_name = f"{first} {last}"
    age = random.randint(18, 45)
    nic = f"{random.randint(1975, 2005)}{random.randint(10000000, 99999999)}V"
    gestational_weeks = random.randint(4, 38)
    
    # Simple logic for EDD based on today
    today = datetime.date.today()
    edd_date = today + datetime.timedelta(weeks=(40 - gestational_weeks))
    edd = edd_date.strftime("%d/%m/%Y")
    
    # LMP approx 40 weeks before EDD
    lmp_date = edd_date - datetime.timedelta(weeks=40)
    lmp = lmp_date.strftime("%d/%m/%Y")

    weight = random.uniform(50, 95)
    height = random.uniform(145, 175)
    bmi = round(weight / ((height/100)**2), 1)

    return {
        'fullName': full_name,
        'age': age,
        'nic': nic,
        'address': f"No. {random.randint(1, 200)}, {random.choice(LAST_NAMES)} Mawatha, Colombo {random.randint(1, 15)}",
        'phone': f"07{random.choice(['0','1','2','5','6','7','8'])}{random.randint(1000000, 9999999)}",
        'emergencyContact': f"07{random.choice(['0','1','2','5','6','7','8'])}{random.randint(1000000, 9999999)}",
        'bloodGroup': random.choice(BLOOD_GROUPS),
        'height': round(height, 1),
        'weight': round(weight, 1),
        'bmi': bmi,
        'gravidity': random.randint(1, 4),
        'parity': random.randint(0, 3),
        'gestationalWeeks': gestational_weeks,
        'edd': edd,
        'lmp': lmp,
        'riskLevel': random.choice(RISK_LEVELS),
        'bloodPressure': f"{random.randint(100, 140)}/{random.randint(60, 95)}",
        'hemoglobin': round(random.uniform(9, 14), 1),
        'diabetesStatus': random.choice(DIABETES_STATUS),
        'allergies': random.choice(["None", "Dust", "Penicillin", "None", "None"]),
        'medicalHistory': random.choice(["None", "Asthma", "None", "Hypertension", "None"]),
        'notes': "Auto-generated dummy data for testing UI appearance.",
        'status': random.choice(STATUSES),
        'midwifeId': midwife_id,
        'createdAt': firestore.SERVER_TIMESTAMP,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }

def seed_patients(count=5, midwife_id=""):
    print(f"🚀 Seeding {count} patients...")
    for i in range(count):
        patient = generate_patient(midwife_id)
        db.collection('patients').add(patient)
        print(f"✅ Added: {patient['fullName']}")
    print("✨ Seeding complete!")

if __name__ == "__main__":
    # If we knew a specific midwife UID we could put it here.
    # For now leaving it empty or you can provide one.
    # If the app filters by midwifeId, these might not show unless midwifeId matches.
    # Searching for a midwifeId in Firestore would be better.
    
    # Let's try to find an existing midwifeId if possible to make it useful
    midwives = db.collection('midwives').limit(1).get()
    target_uid = ""
    if midwives:
        target_uid = midwives[0].id
        print(f"📍 Using midwife ID: {target_uid}")
    else:
        print("⚠️ No midwives found. Seeding with empty midwifeId.")

    seed_patients(8, target_uid)
