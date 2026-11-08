import 'utilizador.dart';

/// Pedido de código SMS em curso (ecrã 11). Vive só no repositório, em
/// memória: o telemóvel nunca viaja em rotas, `extra` nem logs.
class PedidoCodigoSms {
  const PedidoCodigoSms({
    required this.telemovel,
    required this.perfil,
    this.criarConta = false,
  });

  /// Número normalizado: "+244923000000".
  final String telemovel;
  final PerfilUtilizador perfil;

  /// true quando veio de "Criar conta" (profissional segue para o registo).
  final bool criarConta;
}
