const COLUMNAS = 2;
const FONDO_SELECTOR = '#fondo-media';
const VIDEO_REGEX = /\.(mp4|webm|ogv|mov|m4v)(\?|#|$)/i;
const GRADIENTE_DEFAULT =
  'linear-gradient(135deg, #10152b 0%, #1b2142 100%)';

const contenidosPorId = new Map();

/**
 * Genera las tarjetas del grid dentro de `contenedorEl`, una por contenido.
 * Cada tarjeta expone data-index y data-id, y su colorAcento se aplica a un
 * elemento interno. No añade ningún listener de mouse ni handler en línea.
 */
export function renderizarGrid(contenidos, contenedorEl) {
  contenidosPorId.clear();
  contenedorEl.replaceChildren();

  contenidos.forEach((contenido, index) => {
    contenidosPorId.set(contenido.id, contenido);

    const tarjeta = document.createElement('div');
    tarjeta.className = 'tarjeta-contenido';
    tarjeta.dataset.index = String(index);
    tarjeta.dataset.id = contenido.id;

    const indicador = document.createElement('div');
    indicador.className = 'tarjeta-contenido__indicador';
    if (contenido.colorAcento) {
      indicador.style.backgroundColor = contenido.colorAcento;
    }

    const titulo = document.createElement('div');
    titulo.className = 'tarjeta-contenido__titulo';
    titulo.textContent = contenido.titulo || 'Sin contenido';

    const tipo = document.createElement('div');
    tipo.className = 'tarjeta-contenido__tipo';
    tipo.textContent = contenido.tipoContenido || '';

    tarjeta.append(indicador, titulo, tipo);
    contenedorEl.appendChild(tarjeta);
  });
}

/**
 * Activa la navegación por D-pad sobre las tarjetas del grid.
 * - Mueve el foco con ArrowUp/Down/Left/Right respetando un grid de 2 columnas.
 * - En los bordes no se mueve ni da la vuelta.
 * - Enter llama a `onSeleccionar` con el data-id y actualiza el fondo multimedia.
 * - No reacciona al mouse.
 * Devuelve { aplicarFoco, destruir }.
 */
export function inicializarNavegacion(contenedorEl, onSeleccionar) {
  let indiceFoco = 0;
  let totalTarjetas = 0;

  const tarjetas = () =>
    contenedorEl.querySelectorAll('.tarjeta-contenido');

  function aplicarFoco() {
    const lista = tarjetas();
    totalTarjetas = lista.length;
    if (totalTarjetas === 0) {
      return;
    }
    if (indiceFoco >= totalTarjetas) {
      indiceFoco = totalTarjetas - 1;
    }
    lista.forEach((t, i) => t.classList.toggle('focused', i === indiceFoco));
  }

  function mover(direccion) {
    if (totalTarjetas === 0) {
      return;
    }
    const fila = Math.floor(indiceFoco / COLUMNAS);
    const columna = indiceFoco % COLUMNAS;
    const totalFilas = Math.ceil(totalTarjetas / COLUMNAS);
    let nuevoIndice = indiceFoco;

    if (direccion === 'ArrowUp' && fila > 0) {
      nuevoIndice = indiceFoco - COLUMNAS;
    } else if (direccion === 'ArrowDown' && fila < totalFilas - 1) {
      const candidato = indiceFoco + COLUMNAS;
      if (candidato < totalTarjetas) {
        nuevoIndice = candidato;
      }
    } else if (direccion === 'ArrowLeft' && columna > 0) {
      nuevoIndice = indiceFoco - 1;
    } else if (direccion === 'ArrowRight' && columna < COLUMNAS - 1) {
      const candidato = indiceFoco + 1;
      if (candidato < totalTarjetas) {
        nuevoIndice = candidato;
      }
    }

    if (nuevoIndice !== indiceFoco) {
      indiceFoco = nuevoIndice;
      aplicarFoco();
    }
  }

  function manejarKeydown(event) {
    switch (event.key) {
      case 'ArrowUp':
      case 'ArrowDown':
      case 'ArrowLeft':
      case 'ArrowRight':
        event.preventDefault();
        mover(event.key);
        break;
      case 'Enter':
      case 'Return':
        event.preventDefault();
        const lista = tarjetas();
        const enfocada = lista[indiceFoco];
        if (!enfocada) {
          break;
        }
        const id = enfocada.dataset.id;
        const contenido = contenidosPorId.get(id);
        if (typeof onSeleccionar === 'function') {
          onSeleccionar(contenido);
        }
        // Nota: El fondo multimedia complejo se implementará después.
        break;
      default:
        break;
    }
  }

  document.addEventListener('keydown', manejarKeydown);
  aplicarFoco();

  return {
    aplicarFoco,
    destruir: () => document.removeEventListener('keydown', manejarKeydown)
  };
}

// ------------------------------------------------------------------
// Reproducción del fondo multimedia (video/image) + fallback visual
// ------------------------------------------------------------------

const esVideo = (url) => VIDEO_REGEX.test(url);

function crearFondoVisual(contenido) {
  const contenedor = document.createElement('div');
  contenedor.className = 'fondo-media--visual';

  if (contenido.fondoUrl) {
    const medio = document.createElement(
      esVideo(contenido.fondoUrl) ? 'video' : 'img'
    );
    medio.className = 'fondo-media__medio';
    medio.src = contenido.fondoUrl;

    if (medio instanceof HTMLVideoElement) {
      medio.autoplay = true;
      medio.muted = true;
      medio.loop = true;
      medio.playsInline = true;
    }
    medio.alt = contenido.titulo || 'Fondo';

    medio.addEventListener(
      'error',
      () => {
        contenedor.replaceChildren();
        contenedor.appendChild(crearFallbackVisual(contenido));
      },
      { once: true }
    );

    contenedor.appendChild(medio);
  } else {
    contenedor.appendChild(crearFallbackVisual(contenido));
  }

  return contenedor;
}

/** Fallback visual: color sólido del contenido o gradiente por defecto. */
const crearFallbackVisual = (contenido) => {
  const fallback = document.createElement('div');
  fallback.className = 'fondo-media--fallback';
  if (contenido.colorAcento) {
    fallback.style.background = contenido.colorAcento;
  } else {
    fallback.style.background = GRADIENTE_DEFAULT;
  }
  return fallback;
};

/**
 * Refresca la capa #fondo-media con el recurso del contenido seleccionado.
 * Si el fondo falla o no existe, aplica el fallback visual (color/gradiente).
 * El audio se añade como capa sonido aparte (sin interrumpir el fondo visual).
 */
export function cambiarContenidoActivo(contenido) {
  const capa = document.querySelector(FONDO_SELECTOR);
  if (!capa) {
    return;
  }
  capa.replaceChildren();

  capa.appendChild(crearFondoVisual(contenido));

  if (contenido.audioUrl) {
    const audio = document.createElement('audio');
    audio.className = 'fondo-media__audio';
    audio.src = contenido.audioUrl;
    audio.loop = true;
    audio.autoplay = true;
    capa.appendChild(audio);
  }
}