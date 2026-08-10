import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js';
import {
  getFirestore,
  collection,
  doc,
  getDoc,
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
          colorAcento: datos.colorAcento ?? null,
          colorSecundario: datos.colorSecundario ?? null,
          iconoNombre: datos.iconoNombre ?? null
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
 * Escucha en tiempo real el documento "sesiones/{uid}" del usuario vinculado.
 * Invoca a `callback` con los datos del documento (o null si no existe).
 * Devuelve la función unsubscribe.
 */
export function escucharSesionActiva(uid, callback) {
  const ref = doc(db, 'sesiones', uid);

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
      console.error(`[CEOSMOS TV] Error escuchando "sesiones/${uid}":`, error);
    }
  );
}

/**
 * Escribe o actualiza la sesión activa del usuario en Firestore
 * (documento "sesiones/{uid}").
 */
export async function actualizarSesionActiva(uid, contenido) {
  const ref = doc(db, 'sesiones', uid);
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

/**
 * Escucha en tiempo real el documento "vinculaciones/{codigo}" usado en el
 * flujo de vinculación móvil → TV. Devuelve la función unsubscribe.
 */
export function escucharVinculacion(codigo, callback) {
  const ref = doc(db, 'vinculaciones', codigo);

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
      console.error(`[CEOSMOS TV] Error escuchando "vinculaciones/${codigo}":`, error);
    }
  );
}

/**
 * Lee una sola vez el documento "vinculaciones/{codigo}" para validar
 * email y expiración durante el flujo de vinculación TV.
 * Resuelve con los datos del documento o null si no existe.
 */
export async function obtenerVinculacion(codigo) {
  const ref = doc(db, 'vinculaciones', codigo);
  try {
    const docSnap = await getDoc(ref);
    if (!docSnap.exists()) {
      return null;
    }
    return docSnap.data();
  } catch (error) {
    console.error(`[CEOSMOS TV] Error leyendo "vinculaciones/${codigo}":`, error);
    return null;
  }
}

/**
 * Marca un documento de vinculación como usado.
 */
export async function marcarVinculacionUsada(codigo) {
  const ref = doc(db, 'vinculaciones', codigo);
  try {
    await setDoc(ref, { usado: true }, { merge: true });
  } catch (error) {
    console.error('[CEOSMOS TV] Error marcando vinculación usada:', error);
  }
}