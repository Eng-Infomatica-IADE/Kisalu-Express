import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/avaliacao.dart';
import '../../../models/estado_pedido.dart';

/// Galeria dos componentes K* em todos os estados (só desenvolvimento).
/// Cada tarefa DS acrescenta aqui a sua secção.
class DevComponentsView extends StatelessWidget {
  const DevComponentsView({super.key});

  @override
  Widget build(BuildContext context) {
    void nada() {}
    return Scaffold(
      appBar: AppBar(title: const Text('Componentes (dev)')),
      body: ListView(
        padding: EdgeInsets.all(K.margemPara(context)),
        children: [
          const _Secao('Botão primário'),
          KPrimaryButton(rotulo: 'Pedir serviço', onPressed: nada),
          const SizedBox(height: K.s12),
          KPrimaryButton(
            rotulo: 'Mostrar QR',
            icone: KIcons.codigoQr,
            onPressed: nada,
          ),
          const SizedBox(height: K.s12),
          KPrimaryButton(
            rotulo: 'Pedir serviço',
            aCarregar: true,
            onPressed: nada,
          ),
          const SizedBox(height: K.s12),
          const KPrimaryButton(rotulo: 'A aguardar rede…', onPressed: null),
          const SizedBox(height: K.s12),
          KPrimaryButton(
            rotulo: 'Cancelar pedido',
            destrutivo: true,
            onPressed: nada,
          ),
          const _Secao('Botão secundário'),
          KSecondaryButton(rotulo: 'Criar conta', onPressed: nada),
          const SizedBox(height: K.s12),
          Wrap(
            spacing: K.s8,
            runSpacing: K.s8,
            children: [
              KSecondaryButton(
                rotulo: 'Ver os meus pedidos',
                larguraTotal: false,
                onPressed: nada,
              ),
              KSecondaryButton(
                rotulo: 'Ligar',
                icone: KIcons.telefone,
                compacto: true,
                larguraTotal: false,
                onPressed: nada,
              ),
            ],
          ),
          const SizedBox(height: K.s12),
          KSecondaryButton(
            rotulo: 'Ver perfil',
            aCarregar: true,
            onPressed: nada,
          ),
          const SizedBox(height: K.s12),
          const KSecondaryButton(rotulo: 'Ver perfil', onPressed: null),
          const _Secao('Ligação (terciário)'),
          Wrap(
            spacing: K.s8,
            runSpacing: K.s8,
            children: [
              KTextLink(rotulo: 'Avaliar mais tarde', onPressed: nada),
              KTextLink(
                rotulo: 'O trabalho tem um problema?',
                destrutivo: true,
                onPressed: nada,
              ),
              KTextLink(rotulo: 'Ver todos', pequeno: true, onPressed: nada),
              KTextLink(
                rotulo: 'Pedir de novo',
                icone: KIcons.pedirDeNovo,
                onPressed: nada,
              ),
              const KTextLink(rotulo: 'Mais tarde', onPressed: null),
            ],
          ),
          const _Secao('Cartões e categorias'),
          KCard(
            onTap: nada,
            rotuloSemantico: 'Joaquim Manuel, ver perfil',
            child: const Row(
              children: [
                KAvatar(nome: 'Joaquim Manuel'),
                SizedBox(width: K.s12),
                Expanded(child: Text('Cartão tocável inteiro')),
              ],
            ),
          ),
          const SizedBox(height: K.s12),
          const KCard(
            destacado: true,
            child: Text('Cartão destacado (proposta selecionada)'),
          ),
          const SizedBox(height: K.s16),
          Wrap(
            spacing: K.s16,
            runSpacing: K.s16,
            children: [
              for (final (icone, rotulo, selecionada) in [
                (KIcons.eletricista, 'Eletricista', false),
                (KIcons.canalizador, 'Canalizador', true),
                (KIcons.mecanico, 'Mecânico', false),
                (KIcons.pedreiro, 'Pedreiro', false),
                (KIcons.arCondicionado, 'Ar cond.', false),
                (KIcons.cabeleireira, 'Cabeleireira', false),
                (KIcons.pintor, 'Pintor', false),
                (KIcons.limpeza, 'Limpeza', false),
              ])
                KCategoryTile(
                  icone: icone,
                  rotulo: rotulo,
                  selecionada: selecionada,
                  onTap: nada,
                ),
            ],
          ),
          const _Secao('Feedback: alertas, vazio e passos'),
          const KStepProgress(total: 4, atual: 3, legenda: 'Rever o pedido'),
          const SizedBox(height: K.s16),
          const KInlineAlert(
            tipo: KAlertaTipo.erro,
            titulo: 'Sem ligação.',
            mensagem:
                'O seu pedido ficou guardado como rascunho e vamos tentar '
                'enviar outra vez automaticamente.',
          ),
          const SizedBox(height: K.s8),
          const KInlineAlert(
            tipo: KAlertaTipo.aviso,
            titulo: 'O Joaquim propôs mudar o preço para 14.000 Kz.',
            mensagem: 'Só muda se aceitar.',
            icone: KIcons.historico,
          ),
          const SizedBox(height: K.s8),
          const KInlineAlert(
            tipo: KAlertaTipo.sucesso,
            titulo: 'Pedido publicado.',
            mensagem: 'Já avisámos 8 canalizadores perto de si.',
          ),
          const SizedBox(height: K.s24),
          KEmptyState(
            icone: KIcons.codigoQr,
            titulo: 'Ainda não tem serviços para confirmar',
            mensagem:
                'Quando aceitar uma proposta, o código QR do serviço '
                'aparece aqui.',
            rotuloAcao: 'Ver os meus pedidos',
            onAcao: nada,
          ),
          const _Secao('Estados, avatar, avaliação e preço'),
          Wrap(
            spacing: K.s8,
            runSpacing: K.s8,
            children: [
              for (final e in EstadoPedido.values) KStatusBadge.estado(e),
              KStatusBadge.propostas(3),
              KStatusBadge.verificado(),
            ],
          ),
          const SizedBox(height: K.s16),
          const Row(
            children: [
              KAvatar(nome: 'Maria S.', tamanho: K.avatarPequeno),
              SizedBox(width: K.s12),
              KAvatar(nome: 'Joaquim Manuel'),
              SizedBox(width: K.s12),
              KAvatar(nome: 'Joaquim Manuel', tamanho: K.avatarGrande),
            ],
          ),
          const SizedBox(height: K.s16),
          const KRatingInline(valor: 4.8, numAvaliacoes: 126),
          const SizedBox(height: K.s8),
          const KRatingInline(valor: 4.8, sufixo: 'chega em 40 min'),
          const SizedBox(height: K.s16),
          const Wrap(
            spacing: K.s16,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              KPriceText(12500, tamanho: KPriceText.lista),
              KPriceText(12500),
              KPriceText(12500, tamanho: KPriceText.destaque),
              KPriceText(12500, tamanho: KPriceText.display),
            ],
          ),
          const _Secao('Chips e controlo segmentado'),
          const _DemoChips(),
          const _Secao('Campos'),
          const _DemoCampos(),
          const _Secao('Barra de topo e botões de ícone'),
          KTopBar(
            titulo: 'O meu pedido',
            onVoltar: nada,
            acao: KIconButton(
              icone: KIcons.mais,
              rotulo: 'Mais opções',
              onPressed: nada,
            ),
          ),
          KTopBar(titulo: 'Confirmar serviço', onVoltar: nada),
          Wrap(
            spacing: K.s8,
            children: [
              KBackButton(onPressed: nada),
              KIconButton(
                icone: KIcons.notificacoes,
                rotulo: 'Notificações',
                mostrarPonto: true,
                onPressed: nada,
              ),
              const KIconButton(
                icone: KIcons.mais,
                rotulo: 'Mais opções',
                onPressed: null,
              ),
              KBackButton(contorno: false, onPressed: nada),
            ],
          ),
          const _Secao('Barra inferior'),
          KBottomNavBar(indiceAtual: 0, onSelecionar: (_) {}),
          const SizedBox(height: K.s12),
          KBottomNavBar(
            indiceAtual: 2,
            qrDisponivel: false,
            onSelecionar: (_) {},
          ),
          const _Secao('Secção, linhas e caixa "Inclui"'),
          KSecaoTitulo(
            titulo: 'Trabalhos feitos',
            rotuloAcao: 'Ver todos (41)',
            onAcao: nada,
          ),
          const SizedBox(height: K.s12),
          const KLinhaIcone(icone: KIcons.localizacao, texto: 'Talatona'),
          const SizedBox(height: K.s8),
          const KLinhaIcone(icone: KIcons.calendario, texto: 'Hoje, 16:00'),
          const SizedBox(height: K.s12),
          const KLinhaChaveValor(
            rotulo: 'Profissional',
            valor: 'Joaquim Manuel ✓',
          ),
          const KLinhaChaveValor.preco(rotulo: 'Valor fechado', valor: 12500),
          const SizedBox(height: K.s12),
          const KIncluiBox(texto: 'mão de obra · material · deslocação'),
          const SizedBox(height: K.s8),
          const KIncluiBox(
            texto: 'mão de obra · deslocação',
            aviso: 'Material não incluído.',
          ),
          const _Secao('Estrelas'),
          const KEstrelas(valor: 5),
          const SizedBox(height: K.s12),
          const _DemoEstrelas(),
          const _Secao('Esqueletos'),
          const KSkeletonLista(itens: 2),
          const _Secao('Folha e SnackBar'),
          const _DemoFolha(),
          const _Secao('Marca'),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              KisaluMark(),
              SizedBox(width: K.s24),
              KisaluMark(cor: KColors.laranja, corLetra: KColors.branco),
            ],
          ),
          const SizedBox(height: K.s32),
        ],
      ),
    );
  }
}

/// Estrelas de escolha (06): 48 dp com 8 dp de intervalo.
class _DemoEstrelas extends StatefulWidget {
  const _DemoEstrelas();

  @override
  State<_DemoEstrelas> createState() => _DemoEstrelasState();
}

class _DemoEstrelasState extends State<_DemoEstrelas> {
  int _nota = 4;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      KEstrelas(valor: _nota, onAlterar: (n) => setState(() => _nota = n)),
      Text(
        EscalaAvaliacao.rotulo(_nota),
        style: Theme.of(context).textTheme.labelLarge!
            .copyWith(color: KColors.laranja),
      ),
    ],
  );
}

/// Folha inferior (08) e SnackBar com ação.
class _DemoFolha extends StatelessWidget {
  const _DemoFolha();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: K.s8,
    runSpacing: K.s8,
    children: [
      KSecondaryButton(
        rotulo: 'Abrir folha',
        larguraTotal: false,
        onPressed: () => mostrarKFolha<void>(
          context,
          builder: (ctx) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Confirmar a proposta?',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: K.s16),
              KPrimaryButton(
                rotulo: 'Confirmar proposta',
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
      KSecondaryButton(
        rotulo: 'Mostrar SnackBar',
        larguraTotal: false,
        onPressed: () => mostrarKSnack(
          context,
          'Proposta aceite. O Joaquim já foi avisado.',
          rotuloAcao: 'Desfazer',
        ),
      ),
    ],
  );
}

/// Filtro de escolha única, ordenação, etiquetas múltiplas e segmentado.
class _DemoChips extends StatefulWidget {
  const _DemoChips();

  @override
  State<_DemoChips> createState() => _DemoChipsState();
}

class _DemoChipsState extends State<_DemoChips> {
  String _filtro = 'Todos';
  String _ordem = 'Preço ↑';
  final _etiquetas = {'Pontual', 'Preço justo', 'Trabalho limpo'};
  bool _profissional = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSegmentedControl<bool>(
          opcoes: const [(false, 'Sou cliente'), (true, 'Sou profissional')],
          valor: _profissional,
          onMudar: (v) => setState(() => _profissional = v),
        ),
        const SizedBox(height: K.s12),
        Wrap(
          spacing: K.s8,
          children: [
            for (final f in ['Todos', 'Em curso', 'Concluídos'])
              KChip(
                rotulo: f,
                selecionado: _filtro == f,
                onSelecionar: (_) => setState(() => _filtro = f),
              ),
            const KChip(rotulo: 'Cancelados'),
          ],
        ),
        Wrap(
          spacing: K.s8,
          children: [
            for (final (o, icone) in [
              ('Preço ↑', null),
              ('Avaliação', KIcons.avaliacoes),
              ('Chegada', null),
            ])
              KChip(
                rotulo: o,
                icone: icone,
                selecionado: _ordem == o,
                onSelecionar: (_) => setState(() => _ordem = o),
              ),
          ],
        ),
        Wrap(
          spacing: K.s8,
          children: [
            for (final e in [
              'Pontual',
              'Preço justo',
              'Simpático',
              'Trabalho limpo',
              'Rápido',
            ])
              KChip(
                rotulo: e,
                variante: KChipVariante.etiqueta,
                selecionado: _etiquetas.contains(e),
                onSelecionar: (sel) => setState(
                  () => sel ? _etiquetas.add(e) : _etiquetas.remove(e),
                ),
              ),
          ],
        ),
        const Wrap(
          spacing: K.s8,
          children: [
            KChip(rotulo: 'Fugas de água', variante: KChipVariante.informativo),
            KChip(rotulo: 'Esquentadores', variante: KChipVariante.informativo),
          ],
        ),
      ],
    );
  }
}

/// Campos em todos os estados. O telemóvel valida ao sair do campo.
class _DemoCampos extends StatefulWidget {
  const _DemoCampos();

  @override
  State<_DemoCampos> createState() => _DemoCamposState();
}

class _DemoCamposState extends State<_DemoCampos> {
  final _telemovel = TextEditingController();
  final _codigo = TextEditingController(text: '4 8 2 1 7 3');
  final _descricao = TextEditingController(
    text: 'Cano a pingar debaixo do lava-loiça.',
  );
  final _referencia = TextEditingController(text: 'Perto da cantina do Sr. Zé');
  String? _erroTelemovel;

  void _validarTelemovel() {
    final digitos = _telemovel.text.replaceAll(RegExp(r'\D'), '');
    final nacionais = digitos.startsWith('244')
        ? digitos.substring(3)
        : digitos;
    final faltam = 9 - nacionais.length;
    setState(() {
      _erroTelemovel = nacionais.isEmpty || faltam == 0
          ? null
          : faltam > 0
          ? 'Faltam $faltam números. Um número angolano tem 9 dígitos.'
          : 'Sobram ${-faltam} números. Um número angolano tem 9 dígitos.';
    });
  }

  @override
  void dispose() {
    for (final c in [_telemovel, _codigo, _descricao, _referencia]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const espaco = SizedBox(height: K.s16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KTextField(
          rotulo: 'Telemóvel',
          controller: _telemovel,
          icone: KIcons.telefone,
          dica: '+244 9__ ___ ___',
          ajuda: 'Enviamos um código por SMS.',
          erro: _erroTelemovel,
          teclado: TextInputType.phone,
          onSaiu: _validarTelemovel,
        ),
        espaco,
        KTextField(
          rotulo: 'Código SMS',
          controller: _codigo,
          sucesso: 'Número confirmado.',
        ),
        espaco,
        const KTextField(
          rotulo: 'Morada',
          icone: KIcons.localizacao,
          dica: 'Ative a localização primeiro',
          ativo: false,
        ),
        espaco,
        KTextField(
          rotulo: 'Descreva o problema',
          controller: _descricao,
          linhas: 3,
          maxCaracteres: 300,
        ),
        espaco,
        KTextField(
          rotulo: 'Ponto de referência',
          controller: _referencia,
          icone: KIcons.localizacao,
          ajuda: 'Ajuda o profissional a encontrar a sua casa.',
        ),
        espaco,
        const KSearchField(),
      ],
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: K.s24, bottom: K.s12),
    child: Text(titulo, style: Theme.of(context).textTheme.titleLarge),
  );
}
