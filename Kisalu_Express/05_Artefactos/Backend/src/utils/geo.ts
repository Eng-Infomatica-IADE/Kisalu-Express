/**
 * Expressão SQL da distância em km (fórmula de Haversine) entre (lat, lng) e as colunas indicadas.
 * Usa 3 parâmetros, por esta ordem: lat, lat, lng. Funciona em MySQL e MariaDB.
 */
export const distanciaKmSql = (colLat: string, colLng: string) =>
  `(6371 * 2 * ASIN(SQRT(POWER(SIN(RADIANS(${colLat} - ?) / 2), 2) + COS(RADIANS(?)) * COS(RADIANS(${colLat})) * POWER(SIN(RADIANS(${colLng} - ?) / 2), 2))))`;

export const geoParams = (lat: number, lng: number) => [lat, lat, lng];

/** Ponto de referência quando o utilizador ainda não tem morada com GPS (Talatona, Luanda) */
export const PONTO_PREDEFINIDO = { lat: -8.92, lng: 13.185 };

const num = (v: unknown) => (v === null || v === undefined ? null : Number(v));

/** Distância em km (Haversine) entre dois pontos; null se faltar alguma coordenada */
export function distanciaKm(lat1: unknown, lng1: unknown, lat2: unknown, lng2: unknown): number | null {
  const [a, b, c, d] = [num(lat1), num(lng1), num(lat2), num(lng2)];
  if (a === null || b === null || c === null || d === null) return null;
  const rad = (x: number) => (x * Math.PI) / 180;
  const h = Math.sin(rad(c - a) / 2) ** 2 + Math.cos(rad(a)) * Math.cos(rad(c)) * Math.sin(rad(d - b) / 2) ** 2;
  return Math.round(6371 * 2 * Math.asin(Math.sqrt(h)) * 10) / 10;
}

/**
 * Posição num mapa quadrado centrado em `centro`, com `raioKm` para cada lado.
 * x e y vão de 0 a 1 (0,0 é o canto superior esquerdo); null se ficar fora do mapa.
 */
export function pontoNoMapa(centro: { lat: number; lng: number }, lat: unknown, lng: unknown, raioKm: number) {
  const [la, ln] = [num(lat), num(lng)];
  if (la === null || ln === null) return null;
  const dxKm = (ln - centro.lng) * 111.32 * Math.cos((centro.lat * Math.PI) / 180);
  const dyKm = (la - centro.lat) * 110.57;
  const x = 0.5 + dxKm / (2 * raioKm);
  const y = 0.5 - dyKm / (2 * raioKm);
  if (x < 0 || x > 1 || y < 0 || y > 1) return null;
  return { x: Math.round(x * 1000) / 1000, y: Math.round(y * 1000) / 1000 };
}
