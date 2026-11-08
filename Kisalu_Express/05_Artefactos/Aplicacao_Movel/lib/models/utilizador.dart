import 'json_leitura.dart';

/// Intenção escolhida no ecrã 01. O papel real é definido pelo servidor.
enum PerfilUtilizador {
  cliente('Sou cliente'),
  profissional('Sou profissional');

  const PerfilUtilizador(this.rotulo);

  final String rotulo;

  /// `perfil_ativo` da API; outro valor (ou admin) → [cliente].
  static PerfilUtilizador doServidor(Object? v) =>
      v == 'profissional' ? profissional : cliente;
}

/// Utilizador com sessão (cabeçalho do ecrã 02).
class Utilizador {
  const Utilizador({
    required this.nome,
    required this.zona,
    this.temNovidades = false,
    this.nomeCompleto = '',
    this.telemovel = '',
    this.moradasGuardadas = 0,
    this.favoritos = 0,
    this.registoProfissionalCompleto = true,
  });

  /// EuJSON (`GET /eu`). Uma conta nova pode ainda não ter nome.
  factory Utilizador.fromJson(Map<String, dynamic> j) {
    final nome = JsonLeitura.texto(j['nome']);
    final profissional = JsonLeitura.mapaOuNull(j['profissional']);
    return Utilizador(
      nome: nome.isEmpty ? '' : JsonLeitura.primeiroNome(nome),
      zona: JsonLeitura.texto(j['zona']),
      temNovidades: JsonLeitura.booleano(j['tem_novidades']),
      nomeCompleto: nome,
      telemovel: JsonLeitura.texto(j['telemovel']),
      moradasGuardadas: JsonLeitura.inteiro(j['moradas_guardadas']),
      favoritos: JsonLeitura.inteiro(j['favoritos']),
      registoProfissionalCompleto: JsonLeitura.booleano(
        profissional?['registo_completo'],
      ),
    );
  }

  /// Primeiro nome: "Maria".
  final String nome;

  /// "Talatona, Luanda"
  final String zona;

  /// Mostra o ponto vermelho no sino (P05).
  final bool temNovidades;

  /// "Maria Kiala" (ecrã 20).
  final String nomeCompleto;

  /// Número completo, só dígitos com indicativo: "+244923000000". O ecrã
  /// mostra-o mascarado (`KFormat.telemovelMascarado`).
  final String telemovel;
  final int moradasGuardadas;
  final int favoritos;

  /// Já fez o registo de profissional (ecrãs 12 e 13). Sem ele, "Mudar para
  /// profissional" abre o registo em vez do painel vazio.
  final bool registoProfissionalCompleto;
}
