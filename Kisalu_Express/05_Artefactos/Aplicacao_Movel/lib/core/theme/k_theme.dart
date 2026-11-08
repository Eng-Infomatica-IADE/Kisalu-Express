import 'package:flutter/material.dart';

import 'k_colors.dart';
import 'k_tokens.dart';
import 'k_typography.dart';

/// Tema Material 3 definido à mão (sem colorSchemeSeed) para garantir os
/// contrastes medidos no Style Guide.
abstract final class KTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: KColors.laranja,
      onPrimary: KColors.branco,
      primaryContainer: KColors.tomClaro,
      onPrimaryContainer: KColors.brasa,
      secondary: KColors.ebano,
      onSecondary: KColors.branco,
      surface: KColors.branco,
      onSurface: KColors.ebano,
      onSurfaceVariant: KColors.neutro700,
      surfaceContainerLowest: KColors.branco,
      surfaceContainerLow: KColors.areia50,
      surfaceContainer: KColors.areia100,
      outline: KColors.areia400,
      outlineVariant: KColors.areia200,
      error: KColors.erro,
      onError: KColors.branco,
      errorContainer: KColors.erroFundo,
      tertiary: KColors.ouro,
    );
    final text = KTypography.textTheme();

    final botaoForma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(K.raioBotao),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: KColors.areia50,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: KColors.areia50,
        foregroundColor: KColors.ebano,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: K.appBar,
        titleTextStyle: text.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(K.botaoAltura),
          padding: const EdgeInsets.symmetric(horizontal: K.s24),
          shape: botaoForma,
          textStyle: text.labelLarge,
          backgroundColor: KColors.laranja,
          foregroundColor: KColors.branco,
          disabledBackgroundColor: KColors.areia200,
          disabledForegroundColor: KColors.neutro500,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(K.alvoMinimo, K.alvoMinimo),
          padding: const EdgeInsets.symmetric(horizontal: K.s24),
          shape: botaoForma,
          textStyle: text.labelLarge,
          foregroundColor: KColors.laranja,
          side: const BorderSide(color: KColors.laranja, width: 1.5),
          backgroundColor: KColors.branco,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(K.alvoMinimo, K.alvoMinimo),
          shape: botaoForma,
          textStyle: text.labelLarge,
          foregroundColor: KColors.laranja,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KColors.branco,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: K.s16,
          vertical: K.s16,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: KColors.neutro500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.raioBotao),
          borderSide: const BorderSide(color: KColors.areia400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.raioBotao),
          borderSide: const BorderSide(color: KColors.areia400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.raioBotao),
          borderSide: const BorderSide(color: KColors.laranja, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.raioBotao),
          borderSide: const BorderSide(color: KColors.erro, width: 2),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: KColors.branco,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(K.raioFolha),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: KColors.ebano,
        actionTextColor: KColors.laranjaVivo,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: text.bodyMedium?.copyWith(color: KColors.branco),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(K.raioBotao),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: KColors.areia200,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
