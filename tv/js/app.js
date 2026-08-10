'use strict';

import { escucharContenidos, actualizarSesionActiva, escucharSesionActiva, obtenerVinculacion, marcarVinculacionUsada } from './firestore-service.js';
import { renderizarGrid, inicializarNavegacion } from './grid.js';

// Punto de arranque de la app CEOSMOS TV
console.log('[CEOSMOS TV] app.js cargado correctamente.');

// Uid del usuario vinculado (lo establece el flujo de vinculación).
// Si aún no hay vinculación, se deja pendiente hasta la pantalla de login.
const UID_STORAGE_KEY = 'ceosmos_uid_vinculado';

export function obtenerUidVinculado() {
  return localStorage.getItem(UID_STORAGE_KEY);
}

export function guardarUidVinculado(uid) {
  localStorage.setItem(UID_STORAGE_KEY, uid);
}

// ------------------------------------------------------------------
// Reloj de cabecera (hora + fecha)
// ------------------------------------------------------------------
function actualizarReloj() {
  const ahora = new Date();
  const horaEl = document.getElementById('reloj-hora');
  const fechaEl = document.getElementById('reloj-fecha');
  if (horaEl) {
    horaEl.textContent = ahora.toLocaleTimeString([], {
      hour: '2-digit',
      minute: '2-digit'
    });
  }
  if (fechaEl) {
    fechaEl.textContent = ahora.toLocaleDateString([], {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    });
  }
}
actualizarReloj();
setInterval(actualizarReloj, 1000);

// ------------------------------------------------------------------
// Grid navegable + fondo multimedia
// ------------------------------------------------------------------
const gridEl = document.querySelector('.grid-contenidos');
let navegacion = null;

function manejadorSeleccion(contenido) {
  if (!contenido) return;
  console.log('[CEOSMOS TV] Contenido seleccionado:', contenido.id);

  const uid = obtenerUidVinculado();
  if (uid) {
    actualizarSesionActiva(uid, contenido);
  }

  const fondoEl = document.getElementById('fondo-media');
  if (fondoEl) {
    if (contenido.fondoUrl) {
      fondoEl.style.backgroundImage = `url(${contenido.fondoUrl})`;
      fondoEl.style.backgroundColor = '';
      fondoEl.style.backgroundSize = 'cover';
      fondoEl.style.backgroundPosition = 'center';
    } else {
      fondoEl.style.backgroundImage = 'none';
      fondoEl.style.backgroundColor = contenido.colorAcento || '';
    }
  }
}

// Inicia la app con el uid ya vinculado: renderiza el grid y escucha la
// sesión activa del usuario.
function iniciarApp(uid) {
  escucharContenidos((contenidos) => {
    renderizarGrid(contenidos, gridEl);

    if (navegacion === null) {
      navegacion = inicializarNavegacion(gridEl, manejadorSeleccion);
    } else {
      navegacion.aplicarFoco();
    }
  });

  escucharSesionActiva(uid, (sesion) => {
    const idActivo = sesion?.contenidoId;
    const tarjetas = document.querySelectorAll('.tarjeta-contenido');
    tarjetas.forEach((tarjeta) => {
      tarjeta.classList.toggle('activa', tarjeta.dataset.id === idActivo);
    });
  });
}

// ------------------------------------------------------------------
// Pantalla de vinculación (email + código de 6 dígitos)
// ------------------------------------------------------------------
const vinOverlay = document.getElementById('vinculacion');
const vinForm = document.getElementById('vinculacion-form');
const vinEmail = document.getElementById('vinculacion-email');
const vinCodigo = document.getElementById('vinculacion-codigo');
const vinError = document.getElementById('vinculacion-error');

function mostrarErrorVinculacion(mensaje) {
  vinError.textContent = mensaje;
  vinError.hidden = false;
}

function ocultarErrorVinculacion() {
  vinError.hidden = true;
}

// Normaliza un valor de Firestore (Timestamp) a Date si hace falta.
function aFecha(valor) {
  if (!valor) return null;
  if (typeof valor.toDate === 'function') return valor.toDate();
  if (valor instanceof Date) return valor;
  return new Date(valor);
}

async function manejarVinculacion(evento) {
  evento.preventDefault();

  const email = vinEmail.value.trim().toLowerCase();
  const codigo = vinCodigo.value.trim();

  if (!email) {
    mostrarErrorVinculacion('Ingresa tu email.');
    return;
  }
  if (!/^\d{6}$/.test(codigo)) {
    mostrarErrorVinculacion('El código debe tener 6 dígitos.');
    return;
  }

  vinForm.querySelector('button[type="submit"]').disabled = true;
  ocultarErrorVinculacion();

  const docVinculacion = await obtenerVinculacion(codigo);

  if (!docVinculacion) {
    mostrarErrorVinculacion('Código no válido. Revisa que coincida con el de tu teléfono.');
    vinForm.querySelector('button[type="submit"]').disabled = false;
    return;
  }

  const expiraEn = aFecha(docVinculacion.expiraEn);
  if (expiraEn && expiraEn.getTime() < Date.now()) {
    mostrarErrorVinculacion('El código ya expiró. Genera uno nuevo desde la app móvil.');
    vinForm.querySelector('button[type="submit"]').disabled = false;
    return;
  }

  if (docVinculacion.usado === true) {
    mostrarErrorVinculacion('Este código ya fue usado.');
    vinForm.querySelector('button[type="submit"]').disabled = false;
    return;
  }

  if ((docVinculacion.email || '').toLowerCase() !== email) {
    mostrarErrorVinculacion('El email no coincide con el de la vinculación.');
    vinForm.querySelector('button[type="submit"]').disabled = false;
    return;
  }

  await marcarVinculacionUsada(codigo);
  guardarUidVinculado(docVinculacion.uid);

  vinOverlay.hidden = true;
  iniciarApp(docVinculacion.uid);
}

const uidVinculado = obtenerUidVinculado();
if (uidVinculado) {
  vinOverlay.hidden = true;
  iniciarApp(uidVinculado);
} else {
  vinForm.addEventListener('submit', manejarVinculacion);
  vinEmail.focus();
}

// Registro del Service Worker
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('/service-worker.js')
      .then(() => {
        console.log('[CEOSMOS TV] Service worker registrado.');
      })
      .catch((error) => {
        console.error('[CEOSMOS TV] Error al registrar service worker:', error);
      });
  });
} else {
  console.warn(
    '[CEOSMOS TV] El navegador no soporta service workers. La app sigue funcionando offline parcialmente.'
  );
}