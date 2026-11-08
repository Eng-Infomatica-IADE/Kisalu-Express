import '../../models/categoria.dart';
import '../../models/nova_proposta.dart';
import '../../models/painel_profissional.dart';
import '../../models/pedido_perto.dart';
import '../../models/registo_profissional.dart';
import '../../models/servico_confirmado.dart';
import '../../models/verificacao_identidade.dart';
import 'mock_sessao.dart';

/// Dados fictícios do lado do profissional (ecrãs 12 a 17).
abstract final class MockPainelProfissional {
  static final _agora = MockSessao.agora;

  /// "Fuga de água na cozinha": o mesmo pedido que o cliente publicou.
  static final fuga = PedidoPerto(
    id: 'pp1',
    titulo: 'Fuga de água na cozinha',
    categoriaId: CategoriaId.canalizador,
    descricao:
        'Cano a pingar debaixo do lava-loiça. Precisa de reparação hoje.',
    zona: 'Talatona',
    distanciaKm: 3.4,
    quando: DateTime(_agora.year, _agora.month, _agora.day, 16),
    publicadoEm: _agora.subtract(const Duration(minutes: 5)),
    novo: true,
  );

  static final muro = PedidoPerto(
    id: 'pp2',
    titulo: 'Reparar muro do quintal',
    categoriaId: CategoriaId.pedreiro,
    descricao: 'Parte do muro caiu com a chuva. Preciso de o refazer.',
    zona: 'Viana',
    distanciaKm: 1.8,
    quando: DateTime(_agora.year, _agora.month, _agora.day + 1, 9),
    publicadoEm: _agora.subtract(const Duration(minutes: 22)),
  );

  static final pedidos = [fuga, muro];

  static final painel = PainelProfissional(
    nome: 'Joaquim',
    zona: 'Viana',
    raioKm: 10,
    pedidosNovos: 3,
    rating: 4.8,
    servicos: 126,
    disponivel: true,
    pedidos: pedidos,
  );

  /// Proposta do ecrã 15 no Figma: 8.000 + 3.500 + 1.000 = 12.500 Kz.
  static const rascunhoProposta = NovaProposta(
    pedidoId: 'pp1',
    maoDeObra: 8000,
    material: 3500,
    deslocacao: 1000,
    chegada: ChegadaProposta.quarentaMinutos,
  );

  /// Passo 1 do registo, como no Figma.
  static const rascunhoRegisto = RegistoProfissional(
    nomeCompleto: 'Joaquim Manuel',
    categoriaIds: [CategoriaId.canalizador, CategoriaId.pedreiro],
    anosExperiencia: 10,
    zona: 'Viana, Luanda',
    raioKm: 10,
  );

  /// Passo 2: documento enviado, falta o rosto.
  static const verificacao = VerificacaoIdentidade(
    documentoEnviado: true,
    rostoEnviado: false,
  );

  /// Trabalho confirmado no ecrã 17.
  static final servicoConfirmado = ServicoConfirmado(
    pedidoId: 'tp1',
    servico: 'Fuga de água na cozinha',
    cliente: 'Maria K.',
    valor: 12500,
    data: DateTime(_agora.year, _agora.month, _agora.day, 15, 52),
  );
}
