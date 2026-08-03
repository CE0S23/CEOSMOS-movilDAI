'use strict';

import { escucharContenidos, actualizarSesionActiva, escucharSesionActiva } from './firestore-service.js';
import { renderizarGrid, inicializarNavegacion } from './grid.js';

// Punto de arranque de la app CEOSMOS TV
console.log('[CEOSMOS TV] app.js cargado correctamente.');

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

// Grid navegable + fondo multimedia
const gridEl = document.querySelector('.grid-contenidos');
let navegacion = null;

function manejadorSeleccion(contenido) {
  if (!contenido) return;
  console.log('[CEOSMOS TV] Contenido seleccionado:', contenido.id);
  
  actualizarSesionActiva(contenido);

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

// Escucha contenidos de Firestore, renderiza el grid y activa la navegación
// únicamente la primera vez (no reinicializa listeners en cada actualización).
escucharContenidos((contenidos) => {
  renderizarGrid(contenidos, gridEl);

  if (navegacion === null) {
    navegacion = inicializarNavegacion(gridEl, manejadorSeleccion);
  } else {
    navegacion.aplicarFoco();
  }
});

escucharSesionActiva((sesion) => {
  const idActivo = sesion?.contenidoId;
  const tarjetas = document.querySelectorAll('.tarjeta-contenido');
  tarjetas.forEach((tarjeta) => {
    tarjeta.classList.toggle('activa', tarjeta.dataset.id === idActivo);
  });
});

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