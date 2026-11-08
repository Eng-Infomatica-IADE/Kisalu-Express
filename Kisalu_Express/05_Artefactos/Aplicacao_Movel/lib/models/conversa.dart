import 'json_leitura.dart';
import 'mensagem.dart';
import 'profissional.dart';

/// Conversa ligada a um pedido (ecrãs 18 e 19).
class Conversa {
  const Conversa({
    required this.id,
    required this.interlocutor,
    required this.pedidoTitulo,
    required this.categoriaId,
    required this.valor,
    required this.mensagens,
    this.naoLidas = 0,
  });

  /// ConversaJSON. O `interlocutor` pode ser um profissional ou o cliente
  /// (`{id, nome, foto_url, e_cliente}`); os dois cabem em [Profissional].
  factory Conversa.fromJson(Map<String, dynamic> j) => Conversa(
    id: JsonLeitura.id(j['id']),
    interlocutor: Profissional.fromJson(JsonLeitura.mapa(j['interlocutor'])),
    pedidoTitulo: JsonLeitura.texto(j['pedido_titulo']),
    categoriaId: JsonLeitura.texto(j['categoria_chave']),
    valor: JsonLeitura.inteiroOuNull(j['valor']),
    mensagens: JsonLeitura.lista(j['mensagens'], Mensagem.fromJson),
    naoLidas: JsonLeitura.inteiro(j['nao_lidas']),
  );

  final String id;

  /// A outra pessoa da conversa.
  final Profissional interlocutor;

  /// "Fuga de água na cozinha"
  final String pedidoTitulo;
  final String categoriaId;

  /// Valor fechado do pedido, em Kz; null enquanto não há proposta aceite.
  final int? valor;

  /// Da mais antiga para a mais recente.
  final List<Mensagem> mensagens;
  final int naoLidas;

  Mensagem? get ultima => mensagens.isEmpty ? null : mensagens.last;

  Conversa copyWith({List<Mensagem>? mensagens, int? naoLidas}) => Conversa(
    id: id,
    interlocutor: interlocutor,
    pedidoTitulo: pedidoTitulo,
    categoriaId: categoriaId,
    valor: valor,
    mensagens: mensagens ?? this.mensagens,
    naoLidas: naoLidas ?? this.naoLidas,
  );
}
