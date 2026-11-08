import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/categoria.dart';

/// Ícones da app num só sítio. Os ícones do Figma v2 são os Lucide (traço
/// 2 px, arredondados); em release a fonte fica reduzida aos glifos usados
/// (tree shaking). Para trocar por SVG basta alterar esta classe.
abstract final class KIcons {
  // Interface (20)
  static const adicionar = LucideIcons.plus;
  static const avaliacoes = LucideIcons.star;
  static const calendario = LucideIcons.calendar;
  static const concluido = LucideIcons.circleCheck;
  static const conversa = LucideIcons.messageSquareText;
  static const definicoes = LucideIcons.slidersHorizontal;
  static const favorito = LucideIcons.heart;
  static const historico = LucideIcons.history;
  static const inicio = LucideIcons.house;
  static const localizacao = LucideIcons.mapPin;
  static const notificacoes = LucideIcons.bell;
  static const pagamento = LucideIcons.creditCard;
  static const pedidos = LucideIcons.clipboardList;
  static const perfil = LucideIcons.userRound;
  static const pesquisa = LucideIcons.search;
  static const propostas = LucideIcons.tag;
  static const codigoQr = LucideIcons.qrCode;
  static const telefone = LucideIcons.phone;
  static const verificado = LucideIcons.shieldCheck;
  static const voltar = LucideIcons.chevronLeft;
  static const avancar = LucideIcons.chevronRight;

  // Extra da interface
  static const mais = LucideIcons.ellipsis;
  static const fechar = LucideIcons.x;
  static const pedirDeNovo = LucideIcons.rotateCcw;
  static const aviso = LucideIcons.triangleAlert;
  static const foto = LucideIcons.camera;
  static const enviar = LucideIcons.send;
  static const sair = LucideIcons.logOut;
  static const editar = LucideIcons.pencil;
  static const recentrar = LucideIcons.locateFixed;
  static const ajuda = LucideIcons.circleQuestionMark;
  static const relogio = LucideIcons.clock;
  static const documento = LucideIcons.idCard;
  static const cadeado = LucideIcons.lock;
  static const menos = LucideIcons.minus;

  /// Estrela preenchida: a Lucide só tem contorno, usa-se a Material.
  static const estrela = Icons.star_rounded;

  // Serviços (13)
  static const arCondicionado = LucideIcons.airVent;
  static const cabeleireira = LucideIcons.scissors;
  static const canalizador = LucideIcons.droplet;
  static const carpinteiro = LucideIcons.hammer;
  static const eletricista = LucideIcons.zap;
  static const informatica = LucideIcons.laptop;
  static const jardinagem = LucideIcons.sprout;
  static const limpeza = LucideIcons.brushCleaning;
  static const mecanico = LucideIcons.carFront;
  static const pedreiro = LucideIcons.brickWall;
  static const pintor = LucideIcons.paintRoller;
  static const serralharia = LucideIcons.lock;
  static const transporte = LucideIcons.truck;

  /// Ícone de uma categoria pela chave de `CategoriaId` (o modelo não conhece
  /// ícones). Chave desconhecida → ícone genérico de pedido.
  static IconData categoria(String id) => switch (id) {
    CategoriaId.arCond => arCondicionado,
    CategoriaId.cabeleireira => cabeleireira,
    CategoriaId.canalizador => canalizador,
    CategoriaId.carpinteiro => carpinteiro,
    CategoriaId.eletricista => eletricista,
    CategoriaId.informatica => informatica,
    CategoriaId.jardinagem => jardinagem,
    CategoriaId.limpeza => limpeza,
    CategoriaId.mecanico => mecanico,
    CategoriaId.pedreiro => pedreiro,
    CategoriaId.pintor => pintor,
    CategoriaId.serralharia => serralharia,
    CategoriaId.transporte => transporte,
    _ => pedidos,
  };
}
