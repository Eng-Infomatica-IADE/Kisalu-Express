import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Um valor de texto guardado no aparelho. Interface para os testes
/// injetarem a versão em memória ([ValorEmMemoria]).
abstract interface class ValorGuardado {
  Future<String?> ler();
  Future<void> guardar(String valor);
  Future<void> apagar();
}

/// Token de sessão (RF01 "sessão mantida", SEGURANCA.md STORAGE-1): no
/// Keystore (Android), Keychain (iOS) ou cifrado com WebCrypto (web).
typedef TokenStorage = ValorGuardado;

/// Rascunho do novo pedido em JSON (RM07). Não é segredo: preferências
/// simples.
typedef RascunhoStorage = ValorGuardado;

class TokenSeguro implements ValorGuardado {
  TokenSeguro([FlutterSecureStorage? armazenamento])
    : _armazenamento =
          armazenamento ??
          const FlutterSecureStorage(
            // iOS: o token não migra para outro aparelho por backup.
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const _chave = 'kisalu_token';
  final FlutterSecureStorage _armazenamento;

  @override
  Future<String?> ler() => _armazenamento.read(key: _chave);

  @override
  Future<void> guardar(String valor) =>
      _armazenamento.write(key: _chave, value: valor);

  @override
  Future<void> apagar() => _armazenamento.delete(key: _chave);
}

class RascunhoEmPreferencias implements ValorGuardado {
  static const _chave = 'kisalu_rascunho_pedido';

  @override
  Future<String?> ler() async =>
      (await SharedPreferences.getInstance()).getString(_chave);

  @override
  Future<void> guardar(String valor) async =>
      (await SharedPreferences.getInstance()).setString(_chave, valor);

  @override
  Future<void> apagar() async =>
      (await SharedPreferences.getInstance()).remove(_chave);
}

/// Só em memória: testes e arranque sem armazenamento.
class ValorEmMemoria implements ValorGuardado {
  ValorEmMemoria([this.valor]);

  String? valor;

  @override
  Future<String?> ler() async => valor;

  @override
  Future<void> guardar(String valor) async => this.valor = valor;

  @override
  Future<void> apagar() async => valor = null;
}
