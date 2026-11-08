import '../../models/notificacao.dart';
import '../../models/pergunta_ajuda.dart';
import 'mock_sessao.dart';

/// Notificações e perguntas frequentes fictícias (RF08, RF16).
abstract final class MockAvisos {
  static final _agora = MockSessao.agora;

  static final notificacoes = <Notificacao>[
    Notificacao(
      id: 'n3',
      titulo: 'O profissional está a caminho',
      corpo: 'O Joaquim chega por volta das 15:40.',
      criadaEm: _agora.subtract(const Duration(minutes: 5)),
      pedidoId: 'ped1',
    ),
    Notificacao(
      id: 'n2',
      titulo: 'Nova proposta',
      corpo: 'Recebeu 3 propostas para "Fuga de água na cozinha".',
      criadaEm: _agora.subtract(const Duration(minutes: 40)),
      pedidoId: 'ped1',
    ),
    Notificacao(
      id: 'n1',
      titulo: 'Serviço confirmado',
      corpo: 'Tomada sem luz: comprovativo KX-301854 guardado.',
      criadaEm: DateTime(2026, 9, 24, 11),
      lida: true,
      pedidoId: 'ped2',
    ),
  ];

  static const perguntas = <PerguntaAjuda>[
    PerguntaAjuda(
      id: 'a1',
      tema: 'pedidos',
      pergunta: 'Como faço um pedido?',
      resposta:
          'No Início, toque em "O que precisa de resolver?", descreva o '
          'problema, diga a zona e publique. Os profissionais perto de si '
          'respondem com um preço fechado.',
    ),
    PerguntaAjuda(
      id: 'a2',
      tema: 'pagamento',
      pergunta: 'O preço pode mudar depois de aceitar?',
      resposta:
          'Não. O valor da proposta aceite é o que paga. Se aparecer um '
          'trabalho extra, o profissional tem de pedir e o cliente aceitar.',
    ),
    PerguntaAjuda(
      id: 'a3',
      tema: 'confirmacao',
      pergunta: 'Para que serve o código QR?',
      resposta:
          'Mostre o QR (ou diga o código de 6 dígitos) só quando o trabalho '
          'estiver feito. É assim que o serviço fica confirmado e o '
          'comprovativo é guardado.',
    ),
    PerguntaAjuda(
      id: 'a4',
      tema: 'problemas',
      pergunta: 'O trabalho ficou mal feito. O que faço?',
      resposta:
          'Em Pedidos, abra o comprovativo e toque em "Reportar problema". '
          'Tem 7 dias depois de confirmar. Respondemos em até 48 horas.',
    ),
  ];
}
