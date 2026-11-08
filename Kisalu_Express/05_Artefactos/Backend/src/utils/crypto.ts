import { createHash, randomBytes, randomInt, randomUUID } from 'node:crypto';

export const sha256 = (value: string) => createHash('sha256').update(value).digest('hex');

/** Código de 6 dígitos (OTP e código alternativo ao QR) */
export const codigo6 = () => String(randomInt(0, 1_000_000)).padStart(6, '0');

export const uuid = () => randomUUID();

/** Conteúdo do QR: texto opaco, sem relação com o pedido nem com o código (ex.: kx_qr_8Wm4Zt1L…) */
export const tokenQr = () => `kx_qr_${randomBytes(24).toString('base64url')}`;
