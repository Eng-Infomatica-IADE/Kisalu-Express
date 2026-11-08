import 'package:flutter/material.dart';

/// Mostra uma mensagem curta em SnackBar ("Em breve", "Avaliação enviada.
/// Obrigado!", "Proposta aceite. O Joaquim já foi avisado." com "Desfazer").
/// Substitui a anterior, para não empilhar.
void mostrarKSnack(
  BuildContext context,
  String mensagem, {
  String? rotuloAcao,
  VoidCallback? onAcao,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(mensagem),
        action: rotuloAcao == null
            ? null
            : SnackBarAction(label: rotuloAcao, onPressed: onAcao ?? () {}),
      ),
    );
}
