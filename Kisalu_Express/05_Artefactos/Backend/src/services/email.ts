import nodemailer, { Transporter } from 'nodemailer';
import { env } from '../config/env';

let transporter: Transporter | null = null;

function obterTransporter(): Transporter | null {
  if (!env.smtp.host) return null;
  transporter ??= nodemailer.createTransport({
    host: env.smtp.host,
    port: env.smtp.port,
    secure: env.smtp.secure,
    auth: env.smtp.user ? { user: env.smtp.user, pass: env.smtp.password } : undefined,
  });
  return transporter;
}

/**
 * Envia um email. Sem SMTP_HOST configurado (desenvolvimento), o email só
 * aparece no terminal.
 */
export async function enviarEmail(para: string, assunto: string, texto: string, html?: string): Promise<void> {
  const t = obterTransporter();
  if (!t) {
    if (env.nodeEnv !== 'test') console.log(`[email] ${para} · ${assunto}\n${texto}`);
    return;
  }
  await t.sendMail({ from: env.emailFrom, to: para, subject: assunto, text: texto, html });
}

/** Email com o código de entrada (RF01) */
export async function enviarCodigoEntrada(para: string, codigo: string): Promise<void> {
  const min = env.codigoExpiresMin;
  await enviarEmail(
    para,
    `Kisalu Express: o seu código é ${codigo}`,
    `O seu código de entrada na Kisalu Express é ${codigo}.\nÉ válido durante ${min} minutos.\n\nSe não pediu este código, ignore este email.`,
    `<div style="font-family:Arial,sans-serif;font-size:15px;color:#222">
       <p>O seu código de entrada na <b>Kisalu Express</b> é:</p>
       <p style="font-size:30px;font-weight:bold;letter-spacing:6px;margin:16px 0">${codigo}</p>
       <p>É válido durante ${min} minutos.</p>
       <p style="color:#777;font-size:13px">Se não pediu este código, ignore este email.</p>
     </div>`,
  );
}
