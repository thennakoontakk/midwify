import { auth, db } from "../firebase";
import {
    createUserWithEmailAndPassword,
    deleteUser,
    signInWithEmailAndPassword,
    signOut,
} from "firebase/auth";
import {
    collection,
    doc,
    setDoc,
    getDoc,
    getDocs,
    updateDoc,
    deleteDoc,
    query,
    orderBy,
    Timestamp,
} from "firebase/firestore";

export interface MidwifeData {
    uid?: string;
    fullName: string;
    nicNumber: string;
    email: string;
    phone: string;
    registrationNumber: string;
    dateOfBirth: string;
    assignedArea: string;
    qualification: string;
    status: "active" | "inactive";
    createdAt?: any;
    updatedAt?: any;
}

const MIDWIVES_COLLECTION = "midwives";

/**
 * Register a new midwife:
 * 1. Create Firebase Auth user with email/password
 * 2. Store profile in Firestore midwives collection
 */
export async function registerMidwife(
    data: MidwifeData,
    password: string
): Promise<string> {
    // We need to create the user via a secondary auth instance approach
    // to avoid logging out the current admin. We'll create, store, then sign back.

    // Store current admin credentials temporarily — since admin isn't logged in via Auth,
    // we can directly create the user.
    const userCredential = await createUserWithEmailAndPassword(
        auth,
        data.email,
        password
    );

    const uid = userCredential.user.uid;

    // Store profile in Firestore
    const midwifeDoc: MidwifeData = {
        ...data,
        uid,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
    };

    await setDoc(doc(db, MIDWIVES_COLLECTION, uid), midwifeDoc);

    // Sign out the newly created user so the admin panel stays accessible
    await signOut(auth);

    return uid;
}

/**
 * Get all midwives from Firestore
 */
export async function getAllMidwives(): Promise<MidwifeData[]> {
    const q = query(
        collection(db, MIDWIVES_COLLECTION),
        orderBy("createdAt", "desc")
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map((doc) => ({
        uid: doc.id,
        ...doc.data(),
    })) as MidwifeData[];
}

/**
 * Get a single midwife by UID
 */
export async function getMidwife(uid: string): Promise<MidwifeData | null> {
    const docSnap = await getDoc(doc(db, MIDWIVES_COLLECTION, uid));
    if (docSnap.exists()) {
        return { uid: docSnap.id, ...docSnap.data() } as MidwifeData;
    }
    return null;
}

/**
 * Update midwife profile in Firestore
 */
export async function updateMidwife(
    uid: string,
    data: Partial<MidwifeData>
): Promise<void> {
    const updateData = {
        ...data,
        updatedAt: Timestamp.now(),
    };
    await updateDoc(doc(db, MIDWIVES_COLLECTION, uid), updateData);
}

/**
 * Delete midwife: remove from Firestore
 */
export async function deleteMidwife(uid: string): Promise<void> {
    await deleteDoc(doc(db, MIDWIVES_COLLECTION, uid));
}
