import { initializeApp, getApps } from 'firebase/app';
import { getAuth, signInAnonymously, onAuthStateChanged } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

// Remplace ces valeurs par ta config Firebase :
// console.firebase.google.com → Projet cercle-4cc09 → Paramètres → Tes apps → SDK
const firebaseConfig = {
  apiKey: 'AIzaSyPLACEHOLDER_REPLACE_ME',
  authDomain: 'cercle-4cc09.firebaseapp.com',
  projectId: 'cercle-4cc09',
  storageBucket: 'cercle-4cc09.appspot.com',
  messagingSenderId: '000000000000',
  appId: '1:000000000000:android:PLACEHOLDER',
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];

export const auth = getAuth(app);
export const db = getFirestore(app);

let _currentUser = null;

export function getCurrentUser() {
  return new Promise((resolve, reject) => {
    if (_currentUser) {
      resolve(_currentUser);
      return;
    }
    const unsub = onAuthStateChanged(auth, async (user) => {
      unsub();
      if (user) {
        _currentUser = user;
        resolve(user);
      } else {
        try {
          const cred = await signInAnonymously(auth);
          _currentUser = cred.user;
          resolve(cred.user);
        } catch (e) {
          reject(e);
        }
      }
    });
  });
}

export function clearCurrentUser() {
  _currentUser = null;
}
