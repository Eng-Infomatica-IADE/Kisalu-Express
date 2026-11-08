import 'json_leitura.dart';
import 'pedido_perto.dart';

/// Dados do Início do profissional (ecrã 14).
class PainelProfissional {
  const PainelProfissional({
    required this.nome,
    required this.zona,
    required this.raioKm,
    required this.pedidosNovos,
    required this.rating,
    required this.servicos,
    required this.disponivel,
    required this.pedidos,
  });

  /// `GET /profissionais/eu/painel`. O nome chega completo; o ecrã usa o
  /// primeiro.
  factory PainelProfissional.fromJson(Map<String, dynamic> j) =>
      PainelProfissional(
        nome: JsonLeitura.primeiroNome(JsonLeitura.texto(j['nome'])),
        zona: JsonLeitura.texto(j['zona']),
        raioKm: JsonLeitura.inteiro(j['raio_km']),
        pedidosNovos: JsonLeitura.inteiro(j['pedidos_novos']),
        rating: JsonLeitura.decimal(j['rating']),
        servicos: JsonLeitura.inteiro(j['servicos']),
        disponivel: JsonLeitura.booleano(j['disponivel']),
        pedidos: JsonLeitura.lista(j['pedidos'], PedidoPerto.fromJson),
      );

  /// Primeiro nome: "Joaquim".
  final String nome;

  /// "Viana"
  final String zona;
  final int raioKm;
  final int pedidosNovos;
  final double rating;
  final int servicos;

  /// Interruptor "Disponível para trabalhar".
  final bool disponivel;

  /// "Pedidos perto de si", mais recentes primeiro.
  final List<PedidoPerto> pedidos;

  PainelProfissional copyWith({bool? disponivel}) => PainelProfissional(
    nome: nome,
    zona: zona,
    raioKm: raioKm,
    pedidosNovos: pedidosNovos,
    rating: rating,
    servicos: servicos,
    disponivel: disponivel ?? this.disponivel,
    pedidos: pedidos,
  );
}
