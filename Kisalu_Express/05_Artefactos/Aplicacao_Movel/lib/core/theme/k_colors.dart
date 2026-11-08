import 'package:flutter/material.dart';

/// Paleta Kisalu Express — Mobile App Style Guide, cap. 02 e 11.
/// Nunca usar cores fora desta classe nos widgets.
abstract final class KColors {
  // Marca
  static const laranja = Color(
    0xFFC8460A,
  ); // primary: botão primário, ativo, links
  static const brasa = Color(
    0xFF9A3508,
  ); // primary premido; texto sobre tom claro
  static const laranjaVivo = Color(0xFFF26A24); // só sobre Ébano / modo escuro
  static const laranjaClaro = Color(0xFFD75314); // círculo grande do login
  static const laranjaEscuro = Color(0xFFB8410A); // círculo pequeno do login
  static const tomClaro = Color(0xFFFBE3D3); // fundo de ícones, seleção, foco
  static const ouro = Color(0xFFFFC21A); // estrelas e selos. NUNCA como texto
  static const ebano = Color(0xFF1C1512); // texto principal, fundos escuros

  // Neutros quentes
  static const neutro700 = Color(0xFF4A3F37); // texto secundário
  static const neutro500 = Color(0xFF7A6C60); // legendas, placeholders
  static const areia400 = Color(0xFF978776); // bordas de campos e chips
  static const areia300 = Color(
    0xFFD3C5B3,
  ); // decorativo apenas (falha como texto/borda)
  static const areia200 = Color(0xFFE6DACA); // divisores, desativado
  static const areia100 = Color(0xFFF3EADD); // superfícies alternativas
  static const areia50 = Color(0xFFFBF6EE); // fundo da app
  static const branco = Color(0xFFFFFFFF); // cartões

  // Semânticas (sempre com ícone + texto)
  static const sucesso = Color(0xFF2F7D4F);
  static const sucessoFundo = Color(0xFFE3F1E8);
  static const erro = Color(0xFFB3261E);
  static const erroFundo = Color(0xFFF9E1DF);
  static const erroPremido = Color(0xFF8C1D17); // destrutivo premido
  static const avisoTexto = Color(0xFF5C4300);
  static const avisoFundo = Color(0xFFFFF3CC);

  // Sombra de cartão: 0/4/14 a 6 %
  static const sombra = Color(0x0F1C1512);
}
