import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'k_colors.dart';

/// Escala tipográfica — Style Guide, cap. 03 e 11, acertada pelas medidas das
/// imagens do Figma v2 (quando divergem, ganha a imagem).
/// Sora: títulos e números (preços). DM Sans: texto e interface, em ficheiro
/// local com o tamanho ótico 40 que o Figma usa.
/// Todos os tamanhos em sp (respeitam o texto do sistema).
abstract final class KTypography {
  static const _familiaDm = 'DMSans';

  static TextStyle _sora(double s, double h, FontWeight w, {double ls = 0}) =>
      GoogleFonts.sora(
        fontSize: s,
        height: h / s,
        fontWeight: w,
        letterSpacing: ls,
        color: KColors.ebano,
      );

  static TextStyle _dm(double s, double h, FontWeight w) => TextStyle(
    fontFamily: _familiaDm,
    fontSize: s,
    height: h / s,
    fontWeight: w,
    // Explícito: sem isto, o ThemeData funde o espaçamento do Material 3.
    letterSpacing: 0,
    color: KColors.ebano,
  );

  static TextTheme textTheme() => TextTheme(
    displaySmall: _sora(32, 40, FontWeight.w800), // Display
    headlineSmall: _sora(26, 32, FontWeight.w700), // Título 1: um por ecrã
    titleLarge: _sora(20, 26, FontWeight.w700), // Título 2: barra e cartões
    titleSmall: _sora(18, 24, FontWeight.w700), // Título de secção
    titleMedium: _sora(16, 22, FontWeight.w600), // Título 3: nome em cartões
    bodyLarge: _dm(16, 24, FontWeight.w400), // Campos
    bodyMedium: _dm(14, 20, FontWeight.w400), // Corpo S
    labelLarge: _dm(16, 20, FontWeight.w700), // Botão
    labelMedium: _dm(14, 20, FontWeight.w700), // Ligações
    bodySmall: _dm(12, 16, FontWeight.w500), // Legenda
    labelSmall: _sora(
      12,
      16,
      FontWeight.w700,
      ls: .72,
    ), // Etiqueta (MAIÚSCULAS)
  );

  /// "Kisalu Express" no cabeçalho do login.
  static TextStyle get marca => _sora(34, 42, FontWeight.w800);

  /// Saudação do Início.
  static TextStyle get titulo24 => _sora(24, 30, FontWeight.w700);

  /// Títulos de destaque: login, nome no perfil, sucesso e estado vazio.
  static TextStyle get titulo22 => _sora(22, 28, FontWeight.w700);

  /// Nome em linhas de lista: propostas (04) e histórico (07).
  static TextStyle get nomeLista => _sora(15, 22, FontWeight.w600);

  /// Etiqueta mais pequena e espaçada dos cartões do histórico (07).
  static TextStyle get etiquetaCompacta =>
      _sora(11, 16, FontWeight.w700, ls: 1);

  /// Slogan do login.
  static TextStyle get slogan => _dm(18, 24, FontWeight.w400);

  /// Texto de apoio maior: introdução do QR, comentário, estado vazio.
  static TextStyle get corpo15 => _dm(15, 22, FontWeight.w400);

  /// Metadados: ajuda dos campos, zona, chips, subtítulos.
  static TextStyle get corpo13 => _dm(13, 18, FontWeight.w400);

  /// Preço em cartões e folhas ("12.500 Kz"). Sora, sempre o elemento mais forte.
  static TextStyle preco({double size = 20}) =>
      _sora(size, size * 1.25, FontWeight.w800);
}
