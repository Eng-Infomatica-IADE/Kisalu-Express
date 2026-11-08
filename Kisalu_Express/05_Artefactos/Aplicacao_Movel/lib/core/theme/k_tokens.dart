import 'package:flutter/material.dart';

import 'k_colors.dart';

/// Espaçamento, raios, alvos e elevação — Style Guide, cap. 04 e 11.
/// Base de 4 dp. Não usar valores soltos nos widgets.
abstract final class K {
  // Espaçamento
  static const s4 = 4.0; // ícone ↔ texto
  static const s8 = 8.0; // entre alvos
  static const s12 = 12.0; // dentro de cartões
  static const s16 = 16.0; // margem · padding
  static const s24 = 24.0; // entre blocos
  static const s32 = 32.0; // entre secções

  static const margem = 16.0; // margem lateral do ecrã (20 a partir de 390 dp)
  static const alvoMinimo = 48.0;

  // Componentes
  static const botaoAltura = 52.0;
  static const campoAltura = 52.0;
  static const appBar = 64.0;
  static const navAltura = 93.0;
  static const qrBotao = 56.0; // círculo do QR na barra inferior
  static const botaoIcone = 44.0; // quadrado visível de voltar/⋯/sino (alvo 48)
  static const chipAltura = 34.0; // pílula visível (alvo de toque 48)
  // Entre linhas de chips: os alvos de 48 dp sobrepõem-se na zona transparente.
  static const chipEntreLinhas = s8 - (alvoMinimo - chipAltura) + 1;
  static const categoriaTile = 64.0; // quadrado das categorias do Início
  static const estadoVazioCirculo = 120.0;
  static const sucessoCirculo = 80.0; // círculo do "Serviço confirmado" (06)
  static const markLargura = 59.0;
  static const markAltura = 85.0;
  static const qrTamanho = 146.0; // código QR do ecrã 05
  static const qrMoldura = 2.0; // borda laranja do QR
  static const passoCirculo = 28.0; // círculo numerado dos passos (05)
  static const miniaturaAltura = 84.0; // "Trabalhos feitos" (03)
  static const iconeQuadrado = 48.0; // quadrado de ícone no histórico (07)

  // Avatares (círculo tom claro com iniciais)
  static const avatarPequeno = 32.0; // avaliações
  static const avatarAvaliar = 40.0; // cartão "Como correu" (06)
  static const avatarMedio = 44.0; // cartões de proposta (04)
  static const avatarCartao = 48.0; // cartões de profissional (02)
  static const avatarPerfil = 64.0; // registo (12) e perfil do utilizador (20)
  static const avatarGrande = 88.0; // perfil do profissional

  // Raios
  static const raioMiniatura = 12.0; // mapa, miniaturas, ícones de pedido
  static const raioInclui = 10.0; // caixa "Inclui"
  static const raioBotao = 14.0; // botões, campos, botões de ícone
  static const raioCategoria = 16.0; // categorias, banner, pesquisa
  static const raioCartao = 20.0;
  static const raioFolha = 24.0; // bottom sheets
  static const raioPilula = 999.0; // chips, badges

  // Ícones
  static const icone16 = 16.0; // dentro de chips
  static const icone20 = 20.0; // campos, botões
  static const icone24 = 24.0; // padrão
  static const icone32 = 32.0; // categorias
  static const icone40 = 40.0; // círculo do estado vazio

  /// Elevação nível 1 (cartões). Nunca combinar com contorno.
  static const sombraCartao = [
    BoxShadow(color: KColors.sombra, offset: Offset(0, 4), blurRadius: 14),
  ];

  /// Largura a partir da qual a margem passa a 20 dp (frames v2: 390 dp).
  static const larguraMargemGrande = 390.0;

  /// Margem lateral responsiva: 16 dp, 20 dp a partir de 390 dp.
  static double margemPara(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= larguraMargemGrande ? 20.0 : margem;
}
