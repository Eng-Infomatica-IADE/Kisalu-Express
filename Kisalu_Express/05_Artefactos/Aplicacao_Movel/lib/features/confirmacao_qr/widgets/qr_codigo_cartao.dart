import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/confirmar_servico_controller.dart';

/// Cartão central do ecrã 05: QR com o token opaco, nome do profissional e
/// código numérico alternativo (P13). O QR só existe em memória.
class QrCodigoCartao extends StatelessWidget {
  const QrCodigoCartao({super.key, required this.servico, this.onTocarQr});

  final ServicoParaConfirmar servico;

  /// Atalho de demonstração: abre a avaliação.
  final VoidCallback? onTocarQr;

  /// Sora 800 do código numérico (P13).
  static const _codigoTamanho = K.s24;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final kz = KFormat.kz(servico.valor);
    return KCard(
      padding: const EdgeInsets.all(K.s16 + K.s4 / 2),
      child: Column(
        children: [
          Semantics(
            image: true,
            label: 'Código QR para confirmar o serviço de $kz',
            child: GestureDetector(
              onTap: onTocarQr,
              child: Container(
                padding: const EdgeInsets.all(K.s8 + K.s4 / 2),
                decoration: BoxDecoration(
                  color: KColors.branco,
                  borderRadius: BorderRadius.circular(K.raioCategoria),
                  border: Border.all(
                    color: KColors.laranja,
                    width: K.qrMoldura,
                  ),
                ),
                child: ExcludeSemantics(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      QrImageView(
                        data: servico.codigo.token,
                        size: K.qrTamanho,
                        padding: EdgeInsets.zero,
                        backgroundColor: KColors.branco,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        gapless: true,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: KColors.ebano,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: KColors.ebano,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(K.s4),
                        color: KColors.branco,
                        child: const KisaluMark(
                          largura: K.icone16 + K.s4 / 2,
                          altura: K.icone24 + K.s4 / 2,
                          cor: KColors.laranja,
                          corLetra: KColors.branco,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: K.s8 + 1),
          Text(
            servico.profissional,
            textAlign: TextAlign.center,
            style: text.titleSmall,
          ),
          const SizedBox(height: K.s8),
          Text(
            '${servico.categoria} · $kz',
            textAlign: TextAlign.center,
            style: text.bodyMedium!.copyWith(color: KColors.neutro700),
          ),
          const SizedBox(height: K.s8 + K.s4 / 2),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: K.s8 - 1),
            padding: const EdgeInsets.symmetric(
              horizontal: K.s8,
              vertical: K.s8 + K.s4 - 1,
            ),
            decoration: BoxDecoration(
              color: KColors.areia50,
              borderRadius: BorderRadius.circular(K.raioBotao),
            ),
            child: Column(
              children: [
                Text(
                  'Se a leitura falhar, diga este código:',
                  textAlign: TextAlign.center,
                  style: text.bodySmall,
                ),
                Semantics(
                  label: 'Código ${KFormat.codigo(servico.codigo.codigo)}',
                  excludeSemantics: true,
                  child: Text(
                    KFormat.codigo(servico.codigo.codigo),
                    textAlign: TextAlign.center,
                    style: KTypography.preco(size: _codigoTamanho)
                        .copyWith(color: KColors.ebano, letterSpacing: K.s4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
