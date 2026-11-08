import 'package:flutter/widgets.dart' show StringCharacters;

import '../utils/k_format.dart';

/// Validadores de formulário (VALIDACOES.md). Funções puras: sem estado,
/// sem rede e sem relógio (`agora` entra por parâmetro). Devolvem `null` se
/// o valor é válido, ou a mensagem em português. É só UX: o servidor repete
/// todas as regras.
abstract final class KValidators {
  // Limites com origem na spec.
  static const maxDescricao = 300;
  static const digitosTelemovel = 9;
  static const digitosCodigo = 6;

  // Limites propostos, a acordar com o servidor.
  static const minDescricao = 10;
  static const minPontoReferencia = 5;
  static const maxPontoReferencia = 120;
  static const maxComentario = 300;
  static const minReporte = 10;
  static const maxReporte = 500;
  static const minValorKz = 500;
  static const maxValorKz = 5000000;
  static const maxDiasDataPedido = 30;
  static const minNome = 2;
  static const maxNome = 60;
  static const maxAnosExperiencia = 60;
  static const maxZona = 60;
  static const maxMensagem = 1000;

  static final _soDigitos = RegExp(r'^\d+$');
  static final _kzSimples = RegExp(r'^\d+$');
  static final _kzMilhares = RegExp(r'^\d{1,3}(\.\d{3})+$');
  static final _kzDecimal = RegExp(r'^\d+[.,]\d{1,2}$');

  static int _tamanho(String s) => s.characters.length;

  static String _n(int n, String singular, String plural) =>
      n == 1 ? singular : plural;

  // ---------------------------------------------------------------- telemóvel

  /// Dígitos nacionais sem espaços nem indicativo (pode ter lixo).
  static String _nacional(String valor) {
    final s = valor.replaceAll(RegExp(r'\s+'), '');
    if (s.startsWith('+244')) return s.substring(4);
    if (s.startsWith('00244')) return s.substring(5);
    if (s.startsWith('244') && s.length >= 12) return s.substring(3);
    return s;
  }

  /// Aceita espaços e indicativo. Valida 9 dígitos começados por 9.
  static String? telemovel(String? valor) {
    final bruto = valor?.trim() ?? '';
    if (bruto.isEmpty) return 'Escreva o seu número de telemóvel.';
    final n = _nacional(bruto);
    if (n.isEmpty) return 'Escreva o seu número de telemóvel.';
    if (!_soDigitos.hasMatch(n)) {
      return 'Use só números. Exemplo: 923 456 789.';
    }
    const regra = 'Um número angolano tem $digitosTelemovel dígitos.';
    if (n.length < digitosTelemovel) {
      final f = digitosTelemovel - n.length;
      return '${_n(f, 'Falta 1 número', 'Faltam $f números')}. $regra';
    }
    if (n.length > digitosTelemovel) {
      final s = n.length - digitosTelemovel;
      return 'Tem ${_n(s, '1 número', '$s números')} a mais. $regra';
    }
    if (!n.startsWith('9')) {
      return 'O número começa por 9. Exemplo: 923 456 789.';
    }
    return null;
  }

  /// "923 456 789" ou "+244923456789" → "+244923456789"; inválido → null.
  static String? normalizarTelemovel(String? valor) =>
      telemovel(valor) == null ? '+244${_nacional(valor!.trim())}' : null;

  // ------------------------------------------------------------------ códigos

  static String? _codigo6(
    String? valor, {
    required String vazio,
    required String soNumeros,
    required String aMais,
  }) {
    final s = (valor ?? '').replaceAll(RegExp(r'\s+'), '');
    if (s.isEmpty) return vazio;
    if (!_soDigitos.hasMatch(s)) return soNumeros;
    if (s.length > digitosCodigo) return aMais;
    if (s.length < digitosCodigo) {
      final f = digitosCodigo - s.length;
      return '${_n(f, 'Falta 1 número', 'Faltam $f números')}. '
          'O código tem $digitosCodigo dígitos.';
    }
    return null;
  }

  /// 6 dígitos. Não diz se o código está certo: isso é do servidor.
  static String? codigoSms(String? valor) => _codigo6(
    valor,
    vazio: 'Escreva o código que recebeu por SMS.',
    soNumeros: 'Use só números. O código tem $digitosCodigo dígitos.',
    aMais: 'O código tem $digitosCodigo dígitos.',
  );

  /// Código alternativo ao QR. Aceita "482 173" e "482173".
  static String? codigoConfirmacao(String? valor) => _codigo6(
    valor,
    vazio: 'Escreva o código que o cliente lhe disse.',
    soNumeros: 'Use só números. Exemplo: 482 173.',
    aMais: 'O código tem $digitosCodigo dígitos. Confirme com o cliente.',
  );

  /// "482 173" → "482173"; inválido → null.
  static String? normalizarCodigo(String? valor) =>
      codigoConfirmacao(valor) == null
      ? valor!.replaceAll(RegExp(r'\s+'), '')
      : null;

  // ------------------------------------------------------------------- pedido

  static String? descricaoPedido(String? valor) {
    final t = (valor ?? '').trim();
    if (t.isEmpty) return 'Descreva o problema para receber propostas certas.';
    final n = _tamanho(t);
    if (n < minDescricao) {
      return 'Escreva um pouco mais. '
          'Exemplo: Cano a pingar debaixo do lava-loiça.';
    }
    if (n > maxDescricao) {
      return 'A descrição pode ter até $maxDescricao caracteres.';
    }
    return null;
  }

  /// [obrigatorio] é true quando não há GPS (RM05).
  static String? pontoReferencia(String? valor, {bool obrigatorio = true}) {
    final t = (valor ?? '').trim();
    if (t.isEmpty) {
      return obrigatorio
          ? 'Diga-nos um ponto de referência perto de si.'
          : null;
    }
    final n = _tamanho(t);
    if (n < minPontoReferencia) {
      return 'Dê um pouco mais de detalhe. '
          'Exemplo: Perto da cantina do Sr. Zé.';
    }
    if (n > maxPontoReferencia) {
      return 'O ponto de referência pode ter até $maxPontoReferencia '
          'caracteres.';
    }
    return null;
  }

  /// null em [valor] significa "o mais cedo possível" se [semData] for true.
  /// Um valor à meia-noite conta como "só o dia" (sem hora escolhida).
  static String? dataPedido(
    DateTime? valor, {
    required DateTime agora,
    bool semData = false,
  }) {
    if (valor == null) {
      return semData ? null : 'Escolha quando precisa do serviço.';
    }
    final dia = DateTime.utc(valor.year, valor.month, valor.day);
    final hoje = DateTime.utc(agora.year, agora.month, agora.day);
    final dias = dia.difference(hoje).inDays;
    if (dias < 0) return 'Escolha uma data a partir de hoje.';
    if (dias > maxDiasDataPedido) {
      return 'Escolha uma data nos próximos $maxDiasDataPedido dias.';
    }
    final temHora = valor.hour != 0 || valor.minute != 0;
    if (dias == 0 && temHora && valor.isBefore(agora)) {
      return 'Essa hora já passou. Escolha outra.';
    }
    return null;
  }

  // ----------------------------------------------------------------------- Kz

  /// "12500", "12.500", "12.500 Kz" → 12500; formato inválido → null.
  /// Não verifica limites.
  static int? kzParaInteiro(String? valor) {
    final s = _limparKz(valor);
    if (_kzSimples.hasMatch(s)) return int.tryParse(s);
    if (_kzMilhares.hasMatch(s)) return int.tryParse(s.replaceAll('.', ''));
    return null;
  }

  static String _limparKz(String? valor) => (valor ?? '')
      .trim()
      .replaceAll(RegExp(r'\s*kz$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), '');

  /// Aceita "12500" e "12.500", com ou sem "Kz".
  static String? valorKz(
    String? valor, {
    int minimo = minValorKz,
    int maximo = maxValorKz,
  }) {
    final s = _limparKz(valor);
    if (s.isEmpty) return 'Escreva o valor da proposta.';
    final inteiro = kzParaInteiro(s);
    if (inteiro == null) {
      return _kzDecimal.hasMatch(s)
          ? 'Escreva o valor sem cêntimos. Exemplo: 12.500 Kz.'
          : 'Use só números. Exemplo: 12.500 Kz.';
    }
    if (inteiro < minimo) return 'O valor mínimo é ${KFormat.kz(minimo)}.';
    if (inteiro > maximo) {
      return 'O valor máximo é ${KFormat.kz(maximo)}. '
          'Confirme o que escreveu.';
    }
    return null;
  }

  // ------------------------------------------------- registo do profissional

  /// Nome de perfil: 2 a 60 caracteres.
  static String? nomeCompleto(String? valor) {
    final t = (valor ?? '').trim();
    if (t.isEmpty) return 'Escreva o seu nome.';
    final n = _tamanho(t);
    if (n < minNome) return 'Escreva o seu nome completo.';
    if (n > maxNome) return 'O nome pode ter até $maxNome caracteres.';
    return null;
  }

  static String? servicosPrestados(List<String> escolhidos) =>
      escolhidos.isEmpty ? 'Escolha pelo menos um serviço.' : null;

  /// Inteiro de 0 a 60.
  static String? anosExperiencia(String? valor) {
    final t = (valor ?? '').trim();
    if (t.isEmpty) return 'Escreva os seus anos de experiência.';
    if (!_soDigitos.hasMatch(t)) return 'Use só números. Exemplo: 10.';
    if (int.parse(t) > maxAnosExperiencia) {
      return 'Escreva um valor até $maxAnosExperiencia anos.';
    }
    return null;
  }

  static String? zonaAtuacao(String? valor) {
    final t = (valor ?? '').trim();
    if (t.isEmpty) return 'Diga-nos a sua zona de atuação.';
    if (_tamanho(t) > maxZona) {
      return 'A zona pode ter até $maxZona caracteres.';
    }
    return null;
  }

  // --------------------------------------------------------------- proposta

  /// Componente do valor (mão de obra, material, deslocação): de 0 ao máximo.
  /// Aceita "8000", "8.000" e "8.000 Kz".
  static String? componenteKz(String? valor, {required String nome}) {
    final s = _limparKz(valor);
    if (s.isEmpty) return 'Escreva o valor de $nome. Se não cobra, escreva 0.';
    final inteiro = kzParaInteiro(s);
    if (inteiro == null) {
      return _kzDecimal.hasMatch(s)
          ? 'Escreva o valor sem cêntimos. Exemplo: 12.500 Kz.'
          : 'Use só números. Exemplo: 12.500 Kz.';
    }
    if (inteiro > maxValorKz) {
      return 'O valor máximo é ${KFormat.kz(maxValorKz)}. '
          'Confirme o que escreveu.';
    }
    return null;
  }

  // ------------------------------------------------------------------ chat

  /// 1 a 1.000 caracteres. Vazia não envia (sem mensagem: o envio não faz
  /// nada); só devolve texto quando passa do limite.
  static String? mensagemChat(String? valor) =>
      _tamanho((valor ?? '').trim()) > maxMensagem
      ? 'A mensagem pode ter até 1.000 caracteres.'
      : null;

  // ---------------------------------------------------- avaliação e reporte

  /// Comentário da avaliação: opcional, com limite.
  static String? comentario(String? valor) =>
      _tamanho((valor ?? '').trim()) > maxComentario
      ? 'O comentário pode ter até $maxComentario caracteres.'
      : null;

  static String? estrelas(int? valor) => valor == null || valor < 1 || valor > 5
      ? 'Escolha de 1 a 5 estrelas.'
      : null;

  static String? reporteProblema(String? valor) {
    final t = (valor ?? '').trim();
    if (t.isEmpty) return 'Conte-nos o que aconteceu.';
    final n = _tamanho(t);
    if (n < minReporte) {
      return 'Escreva um pouco mais para percebermos o problema.';
    }
    if (n > maxReporte) {
      return 'A descrição pode ter até $maxReporte caracteres.';
    }
    return null;
  }
}
