import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/repositories/kisalu_exception.dart';

/// Cliente HTTP da kisalu-api (docs/CONTRATO-API.md, secção 0).
///
/// - Endereço vindo de `--dart-define=KISALU_API=...` ([urlAmbiente]).
/// - O token de sessão segue em `Authorization: Bearer`; quem o guarda no
///   aparelho é o repositório (`TokenStorage`).
/// - As respostas chegam no envelope `{title, status, detail, instance,
///   data}`: devolve-se só `data`.
/// - Qualquer falha sai como [KisaluException]; o corpo bruto nunca sobe.
class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? cliente,
    this.timeout = const Duration(seconds: 15),
    this.aoExpirarSessao,
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _cliente = cliente ?? http.Client();

  /// Valor de `--dart-define=KISALU_API`; vazio → a app usa o mock.
  static const urlAmbiente = String.fromEnvironment('KISALU_API');

  /// Ex.: `http://10.0.2.2:3000/api` (sem barra no fim).
  final String baseUrl;
  final http.Client _cliente;

  /// Tempo máximo de cada pedido; passado isso conta como sem rede.
  final Duration timeout;

  /// Chamado quando a API responde 401 (o token já foi apagado).
  void Function()? aoExpirarSessao;

  String? _token;

  String? get token => _token;
  bool get temSessao => _token != null;

  void definirToken(String? token) => _token = token;

  void limparToken() => _token = null;

  Future<Object?> get(String caminho, {Map<String, String>? query}) =>
      _pedir('GET', caminho, query: query);

  Future<Object?> post(String caminho, [Object? corpo]) =>
      _pedir('POST', caminho, corpo: corpo);

  Future<Object?> put(String caminho, [Object? corpo]) =>
      _pedir('PUT', caminho, corpo: corpo);

  Future<Object?> patch(String caminho, [Object? corpo]) =>
      _pedir('PATCH', caminho, corpo: corpo);

  void fechar() => _cliente.close();

  Uri _uri(String caminho, Map<String, String>? query) {
    final uri = Uri.parse('$baseUrl$caminho');
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: query);
  }

  Future<Object?> _pedir(
    String metodo,
    String caminho, {
    Map<String, String>? query,
    Object? corpo,
  }) async {
    final pedido = http.Request(metodo, _uri(caminho, query))
      ..headers['Accept'] = 'application/json';
    final token = _token;
    if (token != null) pedido.headers['Authorization'] = 'Bearer $token';
    if (corpo != null) {
      pedido.headers['Content-Type'] = 'application/json; charset=utf-8';
      pedido.body = jsonEncode(corpo);
    }

    final http.Response resposta;
    try {
      resposta = await _enviar(pedido).timeout(timeout);
    } on TimeoutException {
      throw const SemRedeException();
    } on http.ClientException {
      throw const SemRedeException();
    } on Exception {
      // Falhas de transporte que não chegam como ClientException.
      throw const SemRedeException();
    }
    return _ler(resposta);
  }

  Future<http.Response> _enviar(http.BaseRequest pedido) async =>
      http.Response.fromStream(await _cliente.send(pedido));

  Object? _ler(http.Response resposta) {
    final envelope = _envelope(resposta);
    final status = resposta.statusCode;
    if (status >= 200 && status < 300) {
      if (envelope == null) return null;
      return envelope.containsKey('data') ? envelope['data'] : envelope;
    }
    final detalhe = switch (envelope?['detail']) {
      final String d when d.trim().isNotEmpty => d.trim(),
      _ => null,
    };
    switch (status) {
      case 401:
        _token = null;
        aoExpirarSessao?.call();
        throw const SessaoExpiradaException();
      case 403:
        throw detalhe == null
            ? const SemPermissaoException()
            : SemPermissaoException(detalhe);
      case 404:
        throw const NaoEncontradoException();
      case 400 || 409 || 422 || 429:
        throw ValidacaoException(
          detalhe ?? 'Não foi possível concluir. Confirme e tente outra vez.',
        );
      default:
        throw const ServidorException();
    }
  }

  /// Corpo como mapa JSON; null se vazio ou ilegível.
  Map<String, dynamic>? _envelope(http.Response resposta) {
    final texto = utf8.decode(resposta.bodyBytes, allowMalformed: true);
    if (texto.trim().isEmpty) return null;
    try {
      final json = jsonDecode(texto);
      return json is Map ? json.cast<String, dynamic>() : {'data': json};
    } on FormatException {
      return null;
    }
  }
}
