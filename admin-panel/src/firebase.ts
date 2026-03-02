import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyBP2jCLqqi7g7CtWO1FQFY989ikh5bmS_8",
  authDomain: "midwify-3f933.firebaseapp.com",
  projectId: "midwify-3f933",
  storageBucket: "midwify-3f933.firebasestorage.app",
  messagingSenderId: "203322719348",
  appId: "1:203322719348:web:eff930cac9d0cd196e2521",
  measurementId: "G-82CGV7CXZQ",
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export default app;
