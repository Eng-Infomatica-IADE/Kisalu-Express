/**
 * Gera docs/API-REST.md (formato bocoup/api-docs-template) a partir da
 * especificação OpenAPI da própria API. Não precisa do servidor nem da BD.
 *
 *   npm run docs:api
 */
import fs from 'node:fs';
import path from 'node:path';
import { createApp } from '../src/app'; // importar a app regista todas as rotas no registry
import { gerarOpenApi } from '../src/docs/registry';

createApp();
const spec: any = gerarOpenApi();

const METODOS = ['get', 'post', 'put', 'patch', 'delete'];
const TITULOS_ESTADO: Record<string, string> = {
  '200': 'Sucesso', '201': 'Criado com sucesso', '400': 'Dados inválidos', '401': 'Falha na autenticação',
  '403': 'Acesso negado', '404': 'Não encontrado', '409': 'Conflito', '422': 'Regra de negócio violada',
};
const CODIGOS_ERRO: Record<string, string> = {
  '400': 'VALIDACAO', '401': 'NAO_AUTENTICADO', '403': 'SEM_PERMISSAO', '404': 'NAO_ENCONTRADO', '409': 'CONFLITO', '422': 'REGRA_NEGOCIO',
};

const deref = (s: any): any => {
  if (s?.$ref) {
    const nome = s.$ref.split('/').pop();
    return spec.components?.schemas?.[nome] ?? {};
  }
  return s ?? {};
};

/** Valor de exemplo: usa example/default/enum e só em último caso um valor por tipo */
function exemplo(s: any, nome = ''): any {
  s = deref(s);
  if (s.example !== undefined) return s.example;
  if (s.default !== undefined) return s.default;
  if (s.enum) return s.enum[0];
  if (s.allOf) return Object.assign({}, ...s.allOf.map((x: any) => exemplo(x)));
  if (s.oneOf || s.anyOf) return exemplo((s.oneOf ?? s.anyOf)[0], nome);
  switch (s.type) {
    case 'object': {
      const o: any = {};
      for (const [k, v] of Object.entries<any>(s.properties ?? {})) o[k] = exemplo(v, k);
      return o;
    }
    case 'array': return [exemplo(s.items, nome)];
    case 'integer': case 'number': return s.minimum ?? 1;
    case 'boolean': return true;
    case 'string':
      if (s.format === 'binary') return '(ficheiro)';
      if (s.format === 'date-time') return '2026-11-20T10:00:00Z';
      if (s.format === 'email') return 'ana@exemplo.ao';
      return /telemovel/.test(nome) ? '+244923000000' : 'texto';
    default: return null;
  }
}

const tipo = (s: any): string => {
  s = deref(s);
  let t = s.enum ? s.enum.map((e: any) => `\`${e}\``).join(' \\| ') : s.type === 'array' ? `${tipo(s.items)}[]` : (s.type ?? 'any');
  if (s.format === 'binary') t = 'ficheiro';
  const lim: string[] = [];
  if (s.minimum !== undefined) lim.push(`mín. ${s.minimum}`);
  if (s.maximum !== undefined) lim.push(`máx. ${s.maximum}`);
  if (s.minLength !== undefined) lim.push(`mín. ${s.minLength} car.`);
  if (s.maxLength !== undefined) lim.push(`máx. ${s.maxLength} car.`);
  if (s.default !== undefined) lim.push(`omissão ${JSON.stringify(s.default)}`);
  if (s.nullable) lim.push('pode ser null');
  return lim.length ? `${t} (${lim.join(', ')})` : t;
};

const json = (v: any) => '```json\n' + JSON.stringify(v, null, 2) + '\n```';
const celula = (t?: string) => (t ?? '').replace(/\|/g, '\\|').replace(/\n/g, ' ');
const ancora = (t: string) =>
  t.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9 -]/g, '').trim().replace(/ /g, '-');

interface Op { metodo: string; caminho: string; op: any }
const ops: Op[] = [];
for (const [caminho, item] of Object.entries<any>(spec.paths))
  for (const m of METODOS) if (item[m]) ops.push({ metodo: m.toUpperCase(), caminho, op: item[m] });

const porTag = new Map<string, Op[]>();
for (const o of ops) {
  const tag = o.op.tags?.[0] ?? 'Outros';
  porTag.set(tag, [...(porTag.get(tag) ?? []), o]);
}

function envelope(status: number, detail: string, data: any, instance: string) {
  return { title: TITULOS_ESTADO[String(status)] ?? 'Erro', status, detail, instance: `/api${instance}`, data };
}

function bloco({ metodo, caminho, op }: Op): string {
  const L: string[] = [];
  const params: any[] = op.parameters ?? [];
  const urlParams = params.filter((p) => p.in === 'path');
  const queryParams = params.filter((p) => p.in === 'query');
  const auth = !!op.security?.length;
  const multipart = op.requestBody?.content?.['multipart/form-data'];
  const corpoSchema = deref((op.requestBody?.content?.['application/json'] ?? multipart)?.schema);
  const exCaminho = caminho.replace(/\{(\w+)\}/g, (_m, n) => {
    const p = urlParams.find((x) => x.name === n);
    return String(exemplo(p?.schema, n));
  });

  L.push(`#### ${op.summary}`, '');
  L.push('* **Title**', '', `  ${op.summary}`, '');
  L.push('* **URL**', '', `  \`/api${caminho}\``, '');
  L.push('* **Method**', '', `  \`${metodo}\``, '');
  L.push('* **Autenticação**', '', auth ? '  Obrigatória: cabeçalho `Authorization: Bearer <token>`.' : '  Pública (não precisa de token).', '');

  L.push('* **URL Params**', '');
  const obrig = [...urlParams, ...queryParams.filter((p) => p.required)];
  const opc = queryParams.filter((p) => !p.required);
  const linhaParam = (p: any) => `  \`${p.name}=[${tipo(p.schema)}]\`${p.in === 'path' ? ' (no caminho)' : ''}${p.description ? ` — ${p.description}` : ''}`;
  L.push('  **Required:**', '');
  L.push(...(obrig.length ? obrig.map((p) => linhaParam(p) + '  ') : ['  Nenhum.']), '');
  L.push('  **Optional:**', '');
  L.push(...(opc.length ? opc.map((p) => linhaParam(p) + '  ') : ['  Nenhum.']), '');

  L.push('* **Data Params**', '');
  if (corpoSchema.properties) {
    const req = new Set<string>(corpoSchema.required ?? []);
    L.push(`  Formato: \`${multipart ? 'multipart/form-data' : 'application/json'}\``, '');
    L.push('  | Campo | Tipo | Obrigatório | Descrição |', '  |---|---|---|---|');
    for (const [k, v] of Object.entries<any>(corpoSchema.properties)) {
      L.push(`  | \`${k}\` | ${celula(tipo(v))} | ${req.has(k) ? 'sim' : 'não'} | ${celula(deref(v).description)} |`);
    }
    L.push('');
    if (!multipart) L.push(json(exemplo(corpoSchema)).replace(/^/gm, '  '), '');
  } else L.push('  Nenhum.', '');

  const respostas = Object.entries<any>(op.responses ?? {});
  const codOk = respostas.find(([c]) => c.startsWith('2'))?.[0] ?? '200';
  const status = Number(codOk);
  L.push('* **Success Response**', '');
  L.push(`  * **Code:** ${status}  `, '  * **Content:**', '');
  L.push(json(envelope(status, status === 201 ? 'Recurso criado com sucesso.' : 'Pedido processado.', '<conteúdo específico do endpoint>', exCaminho)).replace(/^/gm, '    '), '');

  L.push('* **Error Response**', '');
  for (const [c, r] of respostas.filter(([c]) => !c.startsWith('2'))) {
    const cod = CODIGOS_ERRO[c] ?? 'ERRO';
    L.push(`  * **Code:** ${c} — ${TITULOS_ESTADO[c] ?? r.description}  `);
    L.push(`    **Content:** \`{ "title": "${TITULOS_ESTADO[c] ?? 'Erro'}", "status": ${c}, "detail": "…", "instance": "/api${exCaminho}", "data": { "codigo": "${cod}" } }\``, '');
  }

  L.push('* **Sample Call**', '', '  ```bash');
  const qs = queryParams.filter((p) => p.required).map((p) => `${p.name}=${exemplo(p.schema, p.name)}`).join('&');
  const partes = [`curl -X ${metodo} "http://localhost:3000/api${exCaminho}${qs ? '?' + qs : ''}"`];
  if (auth) partes.push('-H "Authorization: Bearer <token>"');
  if (corpoSchema.properties && !multipart) {
    partes.push('-H "Content-Type: application/json"');
    partes.push(`-d '${JSON.stringify(exemplo(corpoSchema))}'`);
  } else if (multipart) {
    for (const [k, v] of Object.entries<any>(corpoSchema.properties ?? {})) {
      const f = deref(v).format === 'binary' || deref(v.items).format === 'binary';
      partes.push(f ? `-F "${k}=@ficheiro.jpg"` : `-F "${k}=${exemplo(v, k)}"`);
    }
  }
  L.push('  ' + partes.join(' \\\n    '), '  ```', '');

  L.push('* **Notes**', '');
  const notas: string[] = [];
  if (op.description) notas.push(op.description);
  if (!auth) notas.push('Rota pública.');
  L.push('  ' + (notas.join(' ') || '—'), '');
  return L.join('\n');
}

const out: string[] = [];
out.push('# Kisalu Express · Documentação da API REST', '');
out.push('> Gerado automaticamente por `npm run docs:api` (`scripts/gerar-docs-api.ts`) a partir da especificação OpenAPI. Não editar à mão: alterar as rotas em `src/modules/**` e voltar a gerar.', '');
out.push(`Formato baseado em [bocoup/api-docs-template](https://github.com/bocoup/api-docs-template). Versão da API: ${spec.info.version}. Total: **${ops.length} endpoints** em ${porTag.size} grupos.`, '');
out.push('* **Base URL:** `http://localhost:3000/api`');
out.push('* **Swagger interativo:** `http://localhost:3000/docs` · **OpenAPI JSON:** `http://localhost:3000/docs.json`');
out.push('* **Autenticação:** JWT em `Authorization: Bearer <token>`. O token obtém-se em `POST /auth/sms/verificar` ou `POST /auth/codigo/verificar`.');
out.push('* **Formato:** JSON (UTF-8), exceto os endpoints de upload (`multipart/form-data`). Valores em kwanzas (Kz); datas em UTC (ISO 8601).', '');
out.push('## Formato das respostas', '');
out.push('Todas as respostas em `/api`, de sucesso ou de erro, seguem o mesmo envelope. O conteúdo específico de cada endpoint vem sempre em `data`; nos erros, `data` traz `{ "codigo": "...", "detalhes": ... }`.', '');
out.push('| Campo | Tipo | Descrição |', '|---|---|---|', '| `title` | string | Título curto do estado HTTP |', '| `status` | number | Código HTTP |', '| `detail` | string | Mensagem legível, em português |', '| `instance` | string | Caminho do pedido |', '| `data` | any \\| null | Conteúdo da resposta (ou `{ codigo, detalhes? }` nos erros) |', '');
out.push('Sucesso:', '', json({ title: 'Sucesso', status: 200, detail: 'Pedido processado.', instance: '/api/categorias', data: { '…': '…' } }), '');
out.push('Erro:', '', json({ title: 'Falha na autenticação', status: 401, detail: 'Falta o token de acesso.', instance: '/api/admin/verificacoes', data: { codigo: 'NAO_AUTENTICADO' } }), '');
out.push('Nos blocos abaixo, o corpo de sucesso mostra o envelope; o conteúdo exato de `data` pode ver-se no Swagger ou experimentando a Sample Call.', '');
out.push('| Código HTTP | Significado |', '|---|---|');
for (const c of ['200', '201', '400', '401', '403', '404', '409', '422']) out.push(`| ${c} | ${TITULOS_ESTADO[c]} |`);
out.push('', '## Índice', '');
for (const [tag, lista] of porTag) {
  out.push(`* [${tag}](#${ancora(tag)}) (${lista.length})`);
  for (const o of lista) out.push(`  * \`${o.metodo} /api${o.caminho}\` — ${o.op.summary}`);
}
out.push('');
for (const [tag, lista] of porTag) {
  out.push(`## ${tag}`, '');
  for (const o of lista) out.push(bloco(o), '---', '');
}

const destino = path.resolve(__dirname, '../docs/API-REST.md');
fs.writeFileSync(destino, out.join('\n'), 'utf8');
console.log(`docs/API-REST.md gerado: ${ops.length} endpoints, ${porTag.size} grupos.`);
process.exit(0);
