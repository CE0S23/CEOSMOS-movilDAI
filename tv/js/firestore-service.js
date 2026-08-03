import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js';
import {
  getFirestore,
  collection,
  doc,
  onSnapshot,
  setDoc,
  serverTimestamp
} from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js';

import { firebaseConfig } from './firebase-config.js';

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

/**
 * Escucha en tiempo real la colección "contenidos".
 * Invoca a `callback` con un array de {id, modo, titulo, tipoContenido, fondoUrl,
 * audioUrl, colorAcento} cada vez que hay cambios. Devuelve la función unsubscribe.
 */
export function escucharContenidos(callback) {
  const ref = collection(db, 'contenidos');

  return onSnapshot(
    ref,
    (snapshot) => {
      const contenidos = snapshot.docs.map((docSnap) => {
        const datos = docSnap.data();
        return {
          id: docSnap.id,
          modo: datos.modo ?? null,
          titulo: datos.titulo ?? '',
          tipoContenido: datos.tipoContenido ?? '',
          fondoUrl: datos.fondoUrl ?? null,
          audioUrl: datos.audioUrl ?? null,
          colorAcento: datos.colorAcento ?? null
        };
      });
      callback(contenidos);
    },
    (error) => {
      console.error('[CEOSMOS TV] Error escuchando "contenidos":', error);
    }
  );
}

/**
 * Escucha en tiempo real el documento "sesiones/activa". Invoca a `callback` con
 * los datos del documento (o null si no existe). Devuelve la función unsubscribe.
 */
export function escucharSesionActiva(callback) {
  const ref = doc(db, 'sesiones', 'activa');

  return onSnapshot(
    ref,
    (docSnap) => {
      if (docSnap.exists()) {
        callback(docSnap.data());
      } else {
        callback(null);
      }
    },
    (error) => {
      console.error('[CEOSMOS TV] Error escuchando "sesiones/activa":', error);
    }
  );
}

/**
 * Escribe o actualiza la sesión activa en Firestore.
 */
export async function actualizarSesionActiva(contenido) {
  const ref = doc(db, 'sesiones', 'activa');
  try {
    await setDoc(ref, {
      modoActual: contenido.modo,
      contenidoId: contenido.id,
      estado: 'activa',
      inicioTimestamp: serverTimestamp()
    }, { merge: true });
    console.log('[CEOSMOS TV] Sesión activa actualizada en Firestore:', contenido.id);
  } catch (error) {
    console.error('[CEOSMOS TV] Error actualizando sesión activa:', error);
  }
}