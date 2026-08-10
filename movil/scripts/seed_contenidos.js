'use strict';

/**
 * SEED: vuelve visuales los 4 contenidos del catálogo CEOSMOS.
 *
 * Agrega (sin borrar el resto de campos) colorSecundario e iconoNombre a los
 * documentos de la colección "contenidos" identificados por su campo "modo".
 *
 * ANTES DE EJECUTAR:
 *   1) En Firebase Console → Firestore → Rules, cambia temporalmente
 *      `allow write: if false` por `allow write: if true` (solo "contenidos").
 *   2) Publica las reglas, ejecuta:  node movil/scripts/seed_contenidos.js
 *   3) Revierte las reglas y vuelve a publicar.
 *
 * Requiere Node 18+ (usa fetch nativo). No instala dependencias.
 */

const fs = require('node:fs');
const path = require('node:path');

const rutaConfig = path.join(__dirname, '..', '..', 'tv', 'js', 'firebase-config.js');
if (!fs.existsSync(rutaConfig)) {
  console.error('[seed] No se encontró tv/js/firebase-config.js');
  process.exit(1);
}

const contenidoConfig = fs.readFileSync(rutaConfig, 'utf8');
const apiKey = (contenidoConfig.match(/apiKey:\s*"([^"]+)"/) || [])[1];
const projectId = (contenidoConfig.match(/projectId:\s*"([^"]+)"/) || [])[1];

if (!apiKey || !projectId) {
  console.error('[seed] No se pudieron leer apiKey/projectId de firebase-config.js');
  process.exit(1);
}

// Visuales nuevas por modo (se conservan fondoUrl, audioUrl, colorAcento…).
const VISUALES = {
  relajar: { colorSecundario: '#3498db', iconoNombre: 'self_improvement' },
  flow: { colorSecundario: '#5dade2', iconoNombre: 'headphones' },
  flow_profundo: { colorSecundario: '#5dade2', iconoNombre: 'headphones' },
  motivar: { colorSecundario: '#e74c3c', iconoNombre: 'format_quote_rounded' },
  música: { colorSecundario: '#ff6b81', iconoNombre: 'music_note' },
  musica: { colorSecundario: '#ff6b81', iconoNombre: 'music_note' }
};

const base =
  `https://firestore.googleapis.com/v1/projects/${projectId}` +
  `/databases/(default)/documents`;

async function obtenerContenidos() {
  const res = await fetch(`${base}/contenidos?pageSize=100&key=${apiKey}`);
  if (!res.ok) {
    const cuerpo = await res.text();
    throw new Error(`GET contenidos falló (${res.status}): ${cuerpo}`);
  }
  const datos = await res.json();
  return datos.documents || [];
}

function aValores(datos) {
  const campos = {};
  for (const [clave, valor] of Object.entries(datos)) {
    campos[clave] = { stringValue: String(valor) };
  }
  return campos;
}

async function actualizarContenido(nombre, datos) {
  const doc = `contenidos/${nombre}`;
  const res = await fetch(`${base}/${doc}?key=${apiKey}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: aValores(datos) })
  });
  if (!res.ok) {
    const cuerpo = await res.text();
    throw new Error(`PATCH ${doc} falló (${res.status}): ${cuerpo}`);
  }
  return res.json();
}

(async () => {
  console.log(`[seed] Proyecto: ${projectId}`);
  const docs = await obtenerContenidos();
  if (docs.length === 0) {
    console.error('[seed] La colección "contenidos" está vacía. Crea los 4 contenidos antes.');
    process.exit(1);
  }

  let actualizados = 0;
  let sinVisuales = 0;

  for (const doc of docs) {
    const id = doc.name.split('/').pop();
    const datos = doc.fields;
    const modo = (datos.modo?.stringValue || '').toLowerCase().trim();
    const visual = VISUALES[modo] || VISUALES.musica;

    const todos = {};
    for (const [clave, valor] of Object.entries(datos)) {
      const tipo = Object.keys(valor)[0];
      if (tipo === 'stringValue') {
        todos[clave] = valor.stringValue;
      } else if (tipo === 'integerValue') {
        todos[clave] = valor.integerValue;
      }
    }
    todos.colorSecundario = visual.colorSecundario;
    todos.iconoNombre = visual.iconoNombre;

    await actualizarContenido(id, todos);
    actualizados += 1;
    console.log(`[seed] OK  contenidos/${id}  (modo="${modo}" → ${visual.iconoNombre})`);
  }

  console.log(`[seed] Actualizados ${actualizados} de ${docs.length} contenidos.`);
  console.log('[seed] RECUERDA revertir la regla "contenidos" a: allow write: if false;');
})().catch((error) => {
  console.error('[seed] ERROR:', error.message);
  if (String(error.message).includes('403') || String(error.message).includes('PERMISSION_DENIED')) {
    console.error('[seed] >> Cambia temporalmente la regla "contenidos" a allow write: if true; y reintenta.');
  }
  process.exit(1);
});