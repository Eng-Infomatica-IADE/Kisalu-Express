import multer from 'multer';
import sharp from 'sharp';
import path from 'node:path';
import fs from 'node:fs/promises';
import { env } from '../config/env';
import { badRequest, notFound } from '../utils/errors';
import { uuid } from '../utils/crypto';

const TIPOS = ['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'];

/** Recebe imagens em memória; são comprimidas antes de ir para o disco (RM03) */
export const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: env.uploadMaxMb * 1024 * 1024, files: 5 },
  fileFilter: (_req, file, cb) => {
    if (TIPOS.includes(file.mimetype)) cb(null, true);
    else cb(badRequest('Só são aceites imagens (JPG, PNG, WEBP ou HEIC).', 'UPLOAD_INVALIDO'));
  },
});

/** Redimensiona para no máximo 1280 px, converte para JPEG (qualidade 75) e grava em `dir`. Devolve o nome do ficheiro. */
async function comprimirPara(file: Express.Multer.File, dir: string): Promise<string> {
  await fs.mkdir(dir, { recursive: true });
  const nome = `${uuid()}.jpg`;
  try {
    await sharp(file.buffer)
      .rotate() // respeita a orientação EXIF da câmara
      .resize({ width: 1280, height: 1280, fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 75, mozjpeg: true })
      .toFile(path.join(dir, nome));
  } catch {
    throw badRequest('Não conseguimos abrir esta foto. Escolha outra.', 'UPLOAD_INVALIDO');
  }
  return nome;
}

/** Imagem pública: grava em uploads/<pasta>/<uuid>.jpg e devolve o URL (/uploads/...) */
export async function guardarImagem(file: Express.Multer.File, pasta: string): Promise<string> {
  const nome = await comprimirPara(file, path.resolve(env.uploadDir, pasta));
  return `/uploads/${pasta}/${nome}`;
}

/**
 * Imagem privada (documentos de identidade, fotos de reclamações): grava fora da pasta pública,
 * em <PRIVADO_DIR>/<pasta>/<uuid>.jpg, e devolve o caminho relativo ("verificacoes/<uuid>.jpg")
 * a guardar na base de dados. Só se lê pela API de administração (caminhoPrivado).
 */
export async function guardarImagemPrivada(file: Express.Multer.File, pasta: string): Promise<string> {
  const nome = await comprimirPara(file, path.resolve(env.privadoDir, pasta));
  return `${pasta}/${nome}`;
}

/**
 * Caminho absoluto de uma imagem privada guardada na base de dados. Recusa capturas simuladas
 * e caminhos que saiam da pasta privada. Aceita o formato antigo "/uploads/verificacoes/...".
 */
export async function caminhoPrivado(guardado: string | null | undefined): Promise<string> {
  if (!guardado || guardado.startsWith('simulado://')) throw notFound('Ficheiro');
  const base = path.resolve(env.privadoDir);
  const abs = path.resolve(base, guardado.replace(/^\/?uploads\//, ''));
  if (!abs.startsWith(base + path.sep)) throw notFound('Ficheiro');
  try {
    await fs.access(abs);
  } catch {
    throw notFound('Ficheiro');
  }
  return abs;
}

/** Envia uma imagem privada (já resolvida por caminhoPrivado), sem cache partilhada */
export function enviarImagemPrivada(res: import('express').Response, abs: string): Promise<void> {
  res.set('Cache-Control', 'private, no-store');
  return new Promise((resolve, reject) => {
    // dotfiles: 'allow' porque a pasta pode estar dentro de um caminho com ponto (ex.: tests/.privado)
    res.sendFile(abs, { dotfiles: 'allow' }, (err) => (err ? reject(notFound('Ficheiro')) : resolve()));
  });
}

export function ficheiros(req: Express.Request, campo: string): Express.Multer.File[] {
  const f = (req as any).files;
  if (!f) return [];
  if (Array.isArray(f)) return f.filter((x: Express.Multer.File) => x.fieldname === campo);
  return f[campo] ?? [];
}
