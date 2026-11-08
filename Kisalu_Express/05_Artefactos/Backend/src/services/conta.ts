import { Db, execute, pool, queryOne } from '../config/db';
import type { TipoPerfil } from '../types/express';

/**
 * EuJSON (contrato, secção 1): dados da conta para o Início (02) e o Perfil (20).
 * A zona segue o perfil ativo: a do profissional ou a da morada predefinida.
 */
export async function euJSON(utilizadorId: number, perfilAtivo: TipoPerfil, db: Db = pool) {
  const u = await queryOne(
    `SELECT u.id, u.nome, u.telemovel, u.email, u.foto_url, u.tipo_perfil, u.criado_em,
            EXISTS (SELECT 1 FROM notificacao n WHERE n.utilizador_id = u.id AND n.lida = FALSE) AS tem_novidades,
            (SELECT COUNT(*) FROM morada x WHERE x.utilizador_id = u.id) AS moradas_guardadas,
            (SELECT COUNT(*) FROM favorito f WHERE f.cliente_id = u.id) AS favoritos,
            (SELECT CONCAT(COALESCE(m.bairro, m.municipio), ', ', m.provincia) FROM morada m
              WHERE m.utilizador_id = u.id ORDER BY m.predefinida DESC, m.id LIMIT 1) AS zona_morada
       FROM utilizador u WHERE u.id = ?`,
    [utilizadorId],
    db,
  );
  if (!u) return null;

  const p = await queryOne(
    `SELECT p.*, (SELECT JSON_ARRAYAGG(c.chave) FROM profissional_categoria pc JOIN categoria c ON c.id = pc.categoria_id
                   WHERE pc.profissional_id = p.utilizador_id) AS chaves
       FROM profissional p WHERE p.utilizador_id = ?`,
    [utilizadorId],
    db,
  );
  const categorias: string[] = p?.chaves ?? [];

  const profissional = p
    ? {
        categorias,
        anos_experiencia: p.anos_experiencia,
        zona: p.zona,
        raio_atuacao_km: p.raio_atuacao_km,
        disponivel: !!p.disponivel,
        verificado: !!p.verificado,
        media_avaliacao: Number(p.media_avaliacao),
        total_avaliacoes: p.total_avaliacoes,
        total_servicos: p.total_servicos,
        bio: p.bio,
        registo_completo: categorias.length > 0 && !!p.zona,
      }
    : null;

  return {
    id: u.id,
    nome: u.nome,
    telemovel: u.telemovel,
    email: u.email,
    foto_url: u.foto_url,
    tipo_perfil: u.tipo_perfil,
    perfil_ativo: perfilAtivo,
    zona: perfilAtivo === 'profissional' ? (p?.zona ?? null) : u.zona_morada,
    tem_novidades: !!u.tem_novidades,
    moradas_guardadas: Number(u.moradas_guardadas),
    favoritos: Number(u.favoritos),
    criado_em: u.criado_em,
    profissional,
  };
}

/** Garante a linha de profissional (fica incompleta até ao registo, ecrã 12) */
export async function garantirProfissional(utilizadorId: number, db: Db = pool) {
  await execute(`INSERT IGNORE INTO profissional (utilizador_id) VALUES (?)`, [utilizadorId], db);
}
