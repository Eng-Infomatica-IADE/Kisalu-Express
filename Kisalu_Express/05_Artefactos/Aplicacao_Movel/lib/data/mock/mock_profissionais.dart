import '../../models/avaliacao.dart';
import '../../models/profissional.dart';

/// Profissionais fictícios. Joaquim Manuel e Ana Cardoso vêm do Figma; os
/// restantes completam propostas e histórico (dados inventados).
abstract final class MockProfissionais {
  static const joaquim = Profissional(
    id: 'p1',
    nome: 'Joaquim Manuel',
    categoria: 'Canalizador',
    zona: 'Talatona, Luanda',
    distanciaKm: 1.2,
    rating: 4.8,
    numAvaliacoes: 126,
    servicosConfirmados: 126,
    anosExperiencia: 6,
    verificado: true,
    maoDeObraDesde: 8000,
    especialidades: [
      'Fugas de água',
      'Esquentadores',
      'Desentupimentos',
      'Loiças sanitárias',
    ],
    trabalhosFeitos: [
      TrabalhoFeito(id: 't1', legenda: 'Antes/depois'),
      TrabalhoFeito(id: 't2', legenda: 'Esquentador'),
      TrabalhoFeito(id: 't3', legenda: 'Loiça sanitária'),
    ],
    totalTrabalhosFeitos: 41,
    avaliacoes: [
      Avaliacao(
        autor: 'Maria S.',
        estrelas: 5,
        comentario: 'Chegou a horas e resolveu a fuga em 40 min. Recomendo!',
      ),
      Avaliacao(
        autor: 'Pedro K.',
        estrelas: 5,
        comentario: 'Trabalho limpo e preço igual ao combinado.',
      ),
    ],
  );

  static const ana = Profissional(
    id: 'p2',
    nome: 'Ana Cardoso',
    categoria: 'Cabeleireira',
    zona: 'Talatona, Luanda',
    distanciaKm: 2.0,
    rating: 4.9,
    numAvaliacoes: 88,
    servicosConfirmados: 41,
    anosExperiencia: 4,
    verificado: true,
    maoDeObraDesde: 5000,
    especialidades: ['Tranças', 'Penteados', 'Cortes'],
  );

  static const rui = Profissional(
    id: 'p3',
    nome: 'Rui Santos',
    categoria: 'Canalizador',
    zona: 'Kilamba, Luanda',
    distanciaKm: 3.4,
    rating: 4.6,
    numAvaliacoes: 54,
    servicosConfirmados: 60,
    anosExperiencia: 3,
    verificado: true,
    maoDeObraDesde: 9000,
  );

  static const paulo = Profissional(
    id: 'p4',
    nome: 'Paulo Neto',
    categoria: 'Canalizador',
    zona: 'Talatona, Luanda',
    distanciaKm: 0.8,
    rating: 4.9,
    numAvaliacoes: 97,
    servicosConfirmados: 110,
    anosExperiencia: 9,
    verificado: false,
    maoDeObraDesde: 10000,
  );

  static const carlos = Profissional(
    id: 'p5',
    nome: 'Carlos Dias',
    categoria: 'Eletricista',
    zona: 'Talatona, Luanda',
    distanciaKm: 1.9,
    rating: 4.7,
    numAvaliacoes: 73,
    servicosConfirmados: 80,
    anosExperiencia: 7,
    verificado: true,
    maoDeObraDesde: 5000,
  );

  static const nuno = Profissional(
    id: 'p6',
    nome: 'Nuno Ferreira',
    categoria: 'Ar condicionado',
    zona: 'Belas, Luanda',
    distanciaKm: 5.1,
    rating: 4.5,
    numAvaliacoes: 39,
    servicosConfirmados: 44,
    anosExperiencia: 5,
    verificado: true,
    maoDeObraDesde: 7000,
  );

  static const helder = Profissional(
    id: 'p7',
    nome: 'Hélder Tavares',
    categoria: 'Mecânico',
    zona: 'Viana, Luanda',
    distanciaKm: 8.3,
    rating: 4.4,
    numAvaliacoes: 28,
    servicosConfirmados: 31,
    anosExperiencia: 8,
    verificado: false,
    maoDeObraDesde: 8000,
  );

  static const todos = [joaquim, ana, rui, paulo, carlos, nuno, helder];

  /// "Perto de si" (ecrã 02): por distância, os do Figma.
  static const pertoDeSi = [joaquim, ana];
}
