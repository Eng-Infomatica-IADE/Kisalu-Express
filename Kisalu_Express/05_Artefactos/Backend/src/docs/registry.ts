import { z } from 'zod';
import { extendZodWithOpenApi, OpenAPIRegistry, OpenApiGeneratorV3 } from '@asteasolutions/zod-to-openapi';

extendZodWithOpenApi(z);

export const registry = new OpenAPIRegistry();

registry.registerComponent('securitySchemes', 'bearerAuth', {
  type: 'http',
  scheme: 'bearer',
  bearerFormat: 'JWT',
  description: 'Token devolvido por POST /auth/sms/verificar (ou /auth/codigo/verificar)',
});

/** Campo de ficheiro para formulários multipart no Swagger */
export const ficheiro = () => z.any().openapi({ type: 'string', format: 'binary' });

export function gerarOpenApi() {
  return new OpenApiGeneratorV3(registry.definitions).generateDocument({
    openapi: '3.0.3',
    info: {
      title: 'Kisalu Express API',
      version: '1.0.0',
      description:
        'API do marketplace de serviços informais Kisalu Express ("Quem sabe, resolve."). ' +
        'Para testar: 1) POST /auth/sms/pedir com o telemóvel (ex.: +244923000000); 2) POST /auth/sms/verificar com o codigo_dev; ' +
        '3) "Authorize" com o token. Também se entra por email (/auth/codigo/...). Valores em kwanzas (Kz), datas em UTC.',
    },
    servers: [{ url: '/api' }],
  });
}
