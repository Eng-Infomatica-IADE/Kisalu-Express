/// Falhas do repositório. Cada uma traz uma [mensagem] em português para o
/// utilizador (catálogo de VALIDACOES.md); detalhes técnicos não saem desta
/// camada e o corpo bruto de uma resposta nunca chega ao ecrã.
sealed class KisaluException implements Exception {
  const KisaluException(this.mensagem);

  final String mensagem;

  @override
  String toString() => '$runtimeType: $mensagem';
}

class SemRedeException extends KisaluException {
  const SemRedeException([
    super.mensagem = 'Sem ligação. Confirme a sua rede e tente outra vez.',
  ]);
}

class SessaoExpiradaException extends KisaluException {
  const SessaoExpiradaException([
    super.mensagem =
        'A sua sessão terminou. Entre outra vez com o seu telemóvel.',
  ]);
}

class SemPermissaoException extends KisaluException {
  const SemPermissaoException([
    super.mensagem = 'Não tem acesso a esta informação.',
  ]);
}

class NaoEncontradoException extends KisaluException {
  const NaoEncontradoException([
    super.mensagem = 'Não encontrámos o que procura.',
  ]);
}

/// Regra de negócio recusada: a [mensagem] é a do catálogo para o caso.
class ValidacaoException extends KisaluException {
  const ValidacaoException(super.mensagem);
}

class ServidorException extends KisaluException {
  const ServidorException([
    super.mensagem =
        'Algo correu mal do nosso lado. Tente outra vez daqui a pouco.',
  ]);
}
