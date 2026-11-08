import { env } from '../config/env';

/**
 * Envio de SMS simulado: o texto aparece no terminal da API.
 * Para enviar a sério, ligar aqui um fornecedor de SMS (ex.: um gateway angolano)
 * sem mudar quem chama esta função.
 */
export async function enviarSms(telemovel: string, texto: string): Promise<void> {
  if (env.nodeEnv !== 'test') console.log(`[sms] ${telemovel} · ${texto}`);
}

/** SMS com o código de entrada (ecrã 11) */
export async function enviarCodigoSms(telemovel: string, codigo: string): Promise<void> {
  await enviarSms(
    telemovel,
    `Kisalu Express: o seu código é ${codigo}. É válido durante ${env.sms.expiraMin} minutos. Não o partilhe com ninguém.`,
  );
}

/** "+244923000000" → "+244 923 000 000" (só para mostrar) */
export function formatarTelemovel(tel: string): string {
  const m = tel.match(/^\+244(\d{3})(\d{3})(\d{3})$/);
  return m ? `+244 ${m[1]} ${m[2]} ${m[3]}` : tel;
}
