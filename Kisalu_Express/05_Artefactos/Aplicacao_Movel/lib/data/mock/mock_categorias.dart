import '../../models/categoria.dart';

/// As 13 categorias do Style Guide. As 8 primeiras formam a grelha do
/// Início (ecrã 02); as restantes aparecem em "Ver todos".
abstract final class MockCategorias {
  static const todas = <Categoria>[
    Categoria(
      id: CategoriaId.eletricista,
      nome: 'Eletricista',
      plural: 'eletricistas',
      emDestaque: true,
    ),
    Categoria(
      id: CategoriaId.canalizador,
      nome: 'Canalizador',
      plural: 'canalizadores',
      emDestaque: true,
    ),
    Categoria(
      id: CategoriaId.mecanico,
      nome: 'Mecânico',
      plural: 'mecânicos',
      emDestaque: true,
    ),
    Categoria(
      id: CategoriaId.pedreiro,
      nome: 'Pedreiro',
      plural: 'pedreiros',
      emDestaque: true,
    ),
    Categoria(
      id: CategoriaId.arCond,
      nome: 'Ar condicionado',
      plural: 'técnicos de ar condicionado',
      emDestaque: true,
    ),
    Categoria(
      id: CategoriaId.cabeleireira,
      nome: 'Cabeleireira',
      plural: 'cabeleireiras',
      emDestaque: true,
    ),
    Categoria(
      id: CategoriaId.pintor,
      nome: 'Pintor',
      plural: 'pintores',
      emDestaque: true,
    ),
    Categoria(
      id: CategoriaId.limpeza,
      nome: 'Limpeza',
      plural: 'profissionais de limpeza',
      emDestaque: true,
    ),
    Categoria(
      id: CategoriaId.carpinteiro,
      nome: 'Carpinteiro',
      plural: 'carpinteiros',
    ),
    Categoria(
      id: CategoriaId.jardinagem,
      nome: 'Jardinagem',
      plural: 'jardineiros',
    ),
    Categoria(
      id: CategoriaId.informatica,
      nome: 'Informática',
      plural: 'técnicos de informática',
    ),
    Categoria(
      id: CategoriaId.serralharia,
      nome: 'Serralharia',
      plural: 'serralheiros',
    ),
    Categoria(
      id: CategoriaId.transporte,
      nome: 'Transporte',
      plural: 'transportadores',
    ),
  ];
}
