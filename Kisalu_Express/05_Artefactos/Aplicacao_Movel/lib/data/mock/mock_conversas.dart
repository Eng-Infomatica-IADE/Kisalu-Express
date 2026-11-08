import '../../models/categoria.dart';
import '../../models/conversa.dart';
import '../../models/mensagem.dart';
import 'mock_profissionais.dart';
import 'mock_sessao.dart';

/// Conversas fictícias (ecrãs 18 e 19). As mensagens do Joaquim vêm do
/// Figma; as outras duas conversas são inventadas.
abstract final class MockConversas {
  static final _agora = MockSessao.agora;

  static DateTime _hoje(int hora, int minuto) =>
      DateTime(_agora.year, _agora.month, _agora.day, hora, minuto);

  static final todas = <Conversa>[
    Conversa(
      id: 'c1',
      interlocutor: MockProfissionais.joaquim,
      pedidoTitulo: 'Fuga de água na cozinha',
      categoriaId: CategoriaId.canalizador,
      valor: 12500,
      naoLidas: 2,
      mensagens: [
        Mensagem(
          id: 'm1',
          texto: 'Boa tarde. Já tem o sifão para a reparação?',
          minha: true,
          enviadaEm: _hoje(14, 51),
          lida: true,
        ),
        Mensagem(
          id: 'm2',
          texto: 'Boa tarde, Maria. Sim, levo o sifão e o vedante.',
          minha: false,
          enviadaEm: _hoje(14, 53),
        ),
        Mensagem(
          id: 'm3',
          texto: 'Chego às 15h40, como combinado.',
          minha: false,
          enviadaEm: _hoje(15, 2),
        ),
      ],
    ),
    Conversa(
      id: 'c2',
      interlocutor: MockProfissionais.carlos,
      pedidoTitulo: 'Tomada sem luz',
      categoriaId: CategoriaId.eletricista,
      valor: 6000,
      mensagens: [
        Mensagem(
          id: 'm1',
          texto: 'Ficou tudo a funcionar. Obrigada!',
          minha: true,
          enviadaEm: DateTime(2026, 9, 24, 11, 5),
          lida: true,
        ),
        Mensagem(
          id: 'm2',
          texto: 'Obrigado pela preferência!',
          minha: false,
          enviadaEm: DateTime(2026, 9, 24, 11, 20),
        ),
      ],
    ),
    Conversa(
      id: 'c3',
      interlocutor: MockProfissionais.nuno,
      pedidoTitulo: 'Limpeza de AC',
      categoriaId: CategoriaId.arCond,
      valor: 9500,
      mensagens: [
        Mensagem(
          id: 'm1',
          texto: 'Já pode ligar o ar condicionado.',
          minha: false,
          enviadaEm: DateTime(2026, 9, 12, 11, 40),
        ),
        Mensagem(
          id: 'm2',
          texto: 'O filtro já está limpo.',
          minha: false,
          enviadaEm: DateTime(2026, 9, 12, 11, 45),
        ),
      ],
    ),
  ];
}
