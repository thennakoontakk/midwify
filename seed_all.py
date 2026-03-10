import firebase_admin
from firebase_admin import credentials, firestore, auth
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

# Dummy names for patients
PATIENT_FIRST_NAMES = ["Anula", "Sunethra", "Kumari", "Nilmini", "Dilini", "Samanthi", "Priyanka", "Malani", "Inoka", "Sanduni"]
PATIENT_LAST_NAMES = ["Silva", "Perera", "Fernando", "Jayasinghe", "Wickramasinghe", "Senanayake", "Bandara", "Gunawardena", "Weerasinghe", "Herath"]

# Dummy data for midwives
MIDWIFE_DATA_POOL = [
    {
        "fullName": "P.M. Kanthi Rajapaksa",
        "email": "kanthi@midwify.com",
        "phone": "0712345678",
        "nicNumber": "198012345678",
        "registrationNumber": "MW/2024/002",
        "assignedArea": "Maharagama MOH Area",
        "qualification": "B.Sc. in Nursing",
        "dateOfBirth": "1980-05-12"
    },
    {
        "fullName": "M.L. Chathurika Gomis",
        "email": "chathurika@midwify.com",
        "phone": "0771234567",
        "nicNumber": "198598765432",
        "registrationNumber": "MW/2024/003",
        "assignedArea": "Nugegoda MOH Area",
        "qualification": "Diploma in Midwifery",
        "dateOfBirth": "1985-11-20"
    },
    {
        "fullName": "S.A. Harshani Perera",
        "email": "harshani@midwify.com",
        "phone": "0755554443",
        "nicNumber": "199011223344",
        "registrationNumber": "MW/2024/004",
        "assignedArea": "Kaduwela MOH Area",
        "qualification": "Advanced Diploma in Midwifery",
        "dateOfBirth": "1990-02-28"
    }
]

def generate_patient_data(midwife_id):
    first = random.choice(PATIENT_FIRST_NAMES)
    last = random.choice(PATIENT_LAST_NAMES)
    full_name = f"{first} {last}"
    age = random.randint(18, 45)
    nic = f"{random.randint(1975, 2005)}{random.randint(10000000, 99999999)}V"
    gestational_weeks = random.randint(4, 38)
    
    today = datetime.date.today()
    edd_date = today + datetime.timedelta(weeks=(40 - gestational_weeks))
    edd = edd_date.strftime("%d/%m/%Y")
    lmp_date = edd_date - datetime.timedelta(weeks=40)
    lmp = lmp_date.strftime("%d/%m/%Y")

    weight = random.uniform(55, 90)
    height = random.uniform(150, 170)
    bmi = round(weight / ((height/100)**2), 1)

    return {
        'fullName': full_name,
        'age': age,
        'nic': nic,
        'address': f"No. {random.randint(1, 150)}, {random.choice(PATIENT_LAST_NAMES)} Road, Town {random.randint(1, 5)}",
        'phone': f"07{random.randint(0, 9)}{random.randint(1000000, 9999999)}",
        'emergencyContact': f"07{random.randint(0, 9)}{random.randint(1000000, 9999999)}",
        'bloodGroup': random.choice(BLOOD_GROUPS),
        'height': round(height, 1),
        'weight': round(weight, 1),
        'bmi': bmi,
        'gravidity': random.randint(1, 3),
        'parity': random.randint(0, 2),
        'gestationalWeeks': gestational_weeks,
        'edd': edd,
        'lmp': lmp,
        'riskLevel': random.choice(RISK_LEVELS),
        'bloodPressure': f"{random.randint(110, 135)}/{random.randint(70, 90)}",
        'hemoglobin': round(random.uniform(10.5, 13.5), 1),
        'diabetesStatus': random.choice(DIABETES_STATUS),
        'allergies': "None",
        'medicalHistory': "None",
        'notes': "Generated for demonstration.",
        'status': random.choice(STATUSES),
        'midwifeId': midwife_id,
        'createdAt': firestore.SERVER_TIMESTAMP,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }

def seed_all():
    print(f"🚀 Starting comprehensive seed...")
    
    for mw_data in MIDWIFE_DATA_POOL:
        email = mw_data['email']
        password = "password123" # Simple password for demo
        
        print(f"\n👩‍⚕️ Creating Midwife: {mw_data['fullName']}...")
        
        try:
            # 1. Create Auth User
            user = auth.create_user(
                email=email,
                password=password,
                display_name=mw_data['fullName']
            )
            uid = user.uid
            print(f"   ✅ Auth user created (UID: {uid})")
            
            # 2. Create Firestore Record
            midwife_record = mw_data.copy()
            midwife_record['uid'] = uid
            midwife_record['createdAt'] = firestore.SERVER_TIMESTAMP
            midwife_record['updatedAt'] = firestore.SERVER_TIMESTAMP
            
            db.collection('midwives').document(uid).set(midwife_record)
            print(f"   ✅ Firestore record added")
            
            # 3. Create 5 Patients for this Midwife
            print(f"   👶 Seeding 5 patients for this midwife...")
            for i in range(5):
                patient = generate_patient_data(uid)
                db.collection('patients').add(patient)
                print(f"      - Added: {patient['fullName']}")
                
        except Exception as e:
            if "ALREADY_EXISTS" in str(e) or "email-already-exists" in str(e):
                print(f"   ⚠️ Midwife {email} already exists. Skipping auth creation.")
                # We can still add patients if we can find the UID
                user = auth.get_user_by_email(email)
                uid = user.uid
                print(f"   👶 Seeding 5 patients for existing midwife {uid}...")
                for i in range(5):
                    patient = generate_patient_data(uid)
                    db.collection('patients').add(patient)
                    print(f"      - Added: {patient['fullName']}")
            else:
                print(f"   ❌ Error: {e}")

    print("\n✨ Comprehensive seeding complete!")
    print("🔑 Admin Credentials (Password: password123):")
    for mw in MIDWIFE_DATA_POOL:
        print(f"   - {mw['email']}")

if __name__ == "__main__":
    seed_all()
