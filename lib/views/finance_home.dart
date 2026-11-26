import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../models/perfil.dart';
import '../models/transacao.dart';
import '../utils/formatters.dart';
import '../viewmodels/finance_view_model.dart';
import 'joint_expenses_page.dart';
import 'transaction_form_sheet.dart';
import 'transaction_tile.dart';

class FinanceApp extends StatefulWidget {
  const FinanceApp({super.key});

  @override
  State<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends State<FinanceApp> {
  late final FinanceViewModel _model;

  @override
  void initState() {
    super.initState();
    _model = FinanceViewModel()..carregar();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF176B53);
    const fundo = Color(0xFFF5F7F4);
    return MaterialApp(
      title: 'Gestão Financeira',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: verde,
          primary: verde,
          surface: fundo,
        ),
        scaffoldBackgroundColor: fundo,
        appBarTheme: const AppBarTheme(
          backgroundColor: fundo,
          foregroundColor: Color(0xFF17342B),
          centerTitle: false,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4F6F3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFE1E7E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: verde, width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFDCEDE4),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 68,
        ),
      ),
      home: FinanceHome(model: _model),
    );
  }
}

class FinanceHome extends StatefulWidget {
  const FinanceHome({super.key, required this.model});
  final FinanceViewModel model;

  @override
  State<FinanceHome> createState() => _FinanceHomeState();
}

class _FinanceHomeState extends State<FinanceHome> {
  int _aba = 0;
  bool _mostrarRateio = false;

  String get _titulo => switch (_aba) {
        0 => 'Visão geral',
        1 => 'Lançamentos',
        _ => _mostrarRateio ? 'Despesas compartilhadas' : 'Seus contextos',
      };

  Future<void> _novoLancamento([Transacao? transacao]) async {
    if (widget.model.perfilSelecionado == null) return;
    await abrirFormularioTransacao(
      context,
      widget.model,
      transacao: transacao,
    );
  }

  Future<void> _novaDespesaConjunta() async {
    await abrirFormularioDespesaConjunta(context, widget.model);
  }

  Future<void> _excluir(Transacao transacao) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: Text('“${transacao.descricao}” será removido do histórico.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true || transacao.id == null) return;
    await widget.model.excluirTransacao(transacao.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lançamento excluído.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            leading: _aba == 2 && _mostrarRateio
                ? IconButton(
                    tooltip: 'Voltar aos contextos',
                    onPressed: () => setState(() => _mostrarRateio = false),
                    icon: const Icon(Icons.arrow_back_rounded),
                  )
                : null,
            title: Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEDE4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Color(0xFF176B53), size: 19),
                ),
                const SizedBox(width: 10),
                Text(_titulo,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Atualizar dados',
                onPressed: widget.model.carregando ? null : widget.model.carregar,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _corpo(),
          floatingActionButton: widget.model.carregando || (_aba == 2 && !_mostrarRateio)
              ? null
              : FloatingActionButton.extended(
                  onPressed: _aba == 2 ? _novaDespesaConjunta : () => _novoLancamento(),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(_aba == 2 ? 'Dividir despesa' : 'Novo lançamento'),
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _aba,
            onDestinationSelected: (indice) => setState(() {
              _aba = indice;
              _mostrarRateio = false;
            }),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard_rounded),
                label: 'Resumo',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Movimentos',
              ),
              NavigationDestination(
                icon: Icon(Icons.layers_outlined),
                selectedIcon: Icon(Icons.layers_rounded),
                label: 'Contextos',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _corpo() {
    if (widget.model.carregando && widget.model.perfis.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.model.erro != null && widget.model.perfis.isEmpty) {
      return _ErroCarregamento(
        mensagem: widget.model.erro!,
        aoTentarNovamente: widget.model.carregar,
      );
    }
    return Column(
      children: [
        if (!(_aba == 2 && _mostrarRateio))
          _SeletorPerfil(
            perfis: widget.model.perfis,
            selecionado: widget.model.perfilSelecionado,
            aoSelecionar: widget.model.selecionarPerfil,
          ),
        if (widget.model.erro != null)
          MaterialBanner(
            content: const Text('Não foi possível atualizar os dados.'),
            actions: [
              TextButton(
                onPressed: widget.model.carregar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _aba == 2 && _mostrarRateio
                ? JointExpensesPage(
                    key: const ValueKey('rateio'),
                    model: widget.model,
                    aoAdicionar: _novaDespesaConjunta,
                  )
                : switch (_aba) {
              0 => _PainelResumo(
                  key: const ValueKey('resumo'),
                  model: widget.model,
                  aoEditar: _novoLancamento,
                  aoExcluir: _excluir,
                  aoVerTudo: () => setState(() => _aba = 1),
                ),
              1 => _ListaLancamentos(
                  key: const ValueKey('movimentos'),
                  model: widget.model,
                  aoEditar: _novoLancamento,
                  aoExcluir: _excluir,
                ),
              _ => _PainelContextos(
                  key: const ValueKey('contextos'),
                  model: widget.model,
                  aoAbrirRateio: () => setState(() => _mostrarRateio = true),
                ),
              },
          ),
        ),
        if (widget.model.carregando && widget.model.perfis.isNotEmpty)
          const LinearProgressIndicator(minHeight: 2),
      ],
    );
  }
}

class _SeletorPerfil extends StatelessWidget {
  const _SeletorPerfil({
    required this.perfis,
    required this.selecionado,
    required this.aoSelecionar,
  });

  final List<Perfil> perfis;
  final Perfil? selecionado;
  final ValueChanged<Perfil> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 63,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 7, 20, 8),
        scrollDirection: Axis.horizontal,
        itemCount: perfis.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final perfil = perfis[index];
          final ativo = selecionado?.id == perfil.id;
          return ChoiceChip(
            selected: ativo,
            onSelected: (_) => aoSelecionar(perfil),
            avatar: Icon(
              _iconePerfil(perfil.tipo),
              size: 17,
              color: ativo ? Colors.white : const Color(0xFF567267),
            ),
            label: Text(perfil.nome),
            selectedColor: const Color(0xFF176B53),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: ativo ? Colors.white : const Color(0xFF345148),
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide(
              color: ativo ? const Color(0xFF176B53) : const Color(0xFFE2E8E2),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class _PainelResumo extends StatelessWidget {
  const _PainelResumo({
    super.key,
    required this.model,
    required this.aoEditar,
    required this.aoExcluir,
    required this.aoVerTudo,
  });

  final FinanceViewModel model;
  final ValueChanged<Transacao> aoEditar;
  final ValueChanged<Transacao> aoExcluir;
  final VoidCallback aoVerTudo;

  @override
  Widget build(BuildContext context) {
    final perfil = model.perfilSelecionado;
    final recentes = model.transacoes.take(4).toList();
    return ListView(
      key: const ValueKey('painel-resumo-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      children: [
        Text(
          'Olá! 👋',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF17342B),
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Aqui está o resumo de ${nomeMes(model.inicioMes)}.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        _CartaoSaldo(
          titulo: 'Saldo do mês · ${perfil?.nome ?? 'Seu perfil'}',
          saldo: model.saldoMes,
          consolidado: model.resumoConsolidado.saldoCentavos,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _CartaoIndicador(
                titulo: 'Entradas',
                valor: model.resumoMes.receitasCentavos,
                icone: Icons.south_west_rounded,
                cor: const Color(0xFF14805E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CartaoIndicador(
                titulo: 'Saídas',
                valor: model.resumoMes.despesasCentavos,
                icone: Icons.north_east_rounded,
                cor: const Color(0xFFCC5E4B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
              child: Text('Recentes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
            ),
            TextButton(onPressed: aoVerTudo, child: const Text('Ver todos')),
          ],
        ),
        const SizedBox(height: 4),
        if (recentes.isEmpty)
          const _EstadoVazio(
            icone: Icons.receipt_long_rounded,
            titulo: 'Ainda sem lançamentos',
            mensagem: 'Toque em “Novo lançamento” para registrar sua primeira movimentação.',
          )
        else
          ...recentes.map(
            (transacao) => TransactionTile(
              transacao: transacao,
              categorias: model.categorias,
              onTap: () => aoEditar(transacao),
              onDelete: () => aoExcluir(transacao),
            ),
          ),
      ],
    );
  }
}

class _CartaoSaldo extends StatelessWidget {
  const _CartaoSaldo({
    required this.titulo,
    required this.saldo,
    required this.consolidado,
  });

  final String titulo;
  final int saldo;
  final int consolidado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF176B53), Color(0xFF0F4E40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Color(0x24176B53), blurRadius: 20, offset: Offset(0, 9)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(titulo,
                    style: const TextStyle(color: Color(0xFFD1E7DD), fontSize: 13)),
              ),
              const Icon(Icons.auto_graph_rounded, color: Color(0xFFA8D6C1)),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            formatarMoeda(saldo),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 31,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(Icons.layers_rounded, size: 16, color: Color(0xFFBFE3D0)),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text('Todos os contextos',
                      style: TextStyle(color: Color(0xFFD8ECE2), fontSize: 12)),
                ),
                Text(formatarMoeda(consolidado),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoIndicador extends StatelessWidget {
  const _CartaoIndicador({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  final String titulo;
  final int valor;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: cor, size: 17),
                const SizedBox(width: 6),
                Text(titulo,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatarMoeda(valor),
                style: TextStyle(
                  color: cor,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaLancamentos extends StatefulWidget {
  const _ListaLancamentos({
    super.key,
    required this.model,
    required this.aoEditar,
    required this.aoExcluir,
  });

  final FinanceViewModel model;
  final ValueChanged<Transacao> aoEditar;
  final ValueChanged<Transacao> aoExcluir;

  @override
  State<_ListaLancamentos> createState() => _ListaLancamentosState();
}

class _ListaLancamentosState extends State<_ListaLancamentos> {
  String _filtro = 'todos';

  @override
  Widget build(BuildContext context) {
    final filtradas = widget.model.transacoes.where((transacao) {
      return _filtro == 'todos' || transacao.tipo == _filtro;
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 9, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'todos', label: Text('Todos')),
                ButtonSegment(value: 'receita', label: Text('Entradas')),
                ButtonSegment(value: 'despesa', label: Text('Saídas')),
              ],
              selected: {_filtro},
              onSelectionChanged: (v) => setState(() => _filtro = v.first),
              showSelectedIcon: false,
            ),
          ),
        ),
        Expanded(
          child: filtradas.isEmpty
              ? const _EstadoVazio(
                  icone: Icons.search_off_rounded,
                  titulo: 'Nada por aqui',
                  mensagem: 'Os lançamentos deste contexto aparecem nesta lista.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 100),
                  itemCount: filtradas.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 58),
                  itemBuilder: (context, index) {
                    final transacao = filtradas[index];
                    return TransactionTile(
                      transacao: transacao,
                      categorias: widget.model.categorias,
                      onTap: () => widget.aoEditar(transacao),
                      onDelete: () => widget.aoExcluir(transacao),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PainelContextos extends StatelessWidget {
  const _PainelContextos({
    super.key,
    required this.model,
    required this.aoAbrirRateio,
  });
  final FinanceViewModel model;
  final VoidCallback aoAbrirRateio;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        Text(
          'Cada parte da sua vida financeira, no seu espaço.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 17),
        ...model.perfis.map((perfil) {
          final selecionado = model.perfilSelecionado?.id == perfil.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selecionado
                      ? const Color(0xFFDCEDE4)
                      : const Color(0xFFF1F4F0),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_iconePerfil(perfil.tipo), color: const Color(0xFF176B53)),
              ),
              title: Text(perfil.nome,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_descricaoPerfil(perfil.tipo)),
              ),
              trailing: selecionado
                  ? const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF176B53))
                  : const Icon(Icons.chevron_right_rounded),
              onTap: () => model.selecionarPerfil(perfil),
            ),
          );
        }),
        if (model.perfilSelecionado?.tipo == 'conjunto') ...[
          const SizedBox(height: 6),
          FilledButton.icon(
            onPressed: aoAbrirRateio,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Abrir divisão de despesas'),
          ),
        ],
        const SizedBox(height: 8),
        Card(
          color: const Color(0xFFEAF2ED),
          child: const Padding(
            padding: EdgeInsets.all(17),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.phone_android_rounded, color: Color(0xFF176B53)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Seus dados ficam salvos neste dispositivo. O app ainda não sincroniza com outros celulares.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({
    required this.icone,
    required this.titulo,
    required this.mensagem,
  });
  final IconData icone;
  final String titulo;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2ED),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: const Color(0xFF176B53)),
          ),
          const SizedBox(height: 12),
          Text(titulo,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 5),
          Text(mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              )),
        ],
      ),
    );
  }
}

class _ErroCarregamento extends StatelessWidget {
  const _ErroCarregamento({
    required this.mensagem,
    required this.aoTentarNovamente,
  });
  final String mensagem;
  final VoidCallback aoTentarNovamente;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: Color(0xFF176B53), size: 42),
              const SizedBox(height: 12),
              const Text('Não foi possível abrir seus dados',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 6),
              Text(mensagem,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: aoTentarNovamente,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
}

IconData _iconePerfil(String tipo) => switch (tipo) {
      'profissional' => Icons.work_outline_rounded,
      'conjunto' => Icons.people_outline_rounded,
      _ => Icons.person_outline_rounded,
    };

String _descricaoPerfil(String tipo) => switch (tipo) {
      'profissional' => 'Entradas e despesas do seu trabalho ou negócio.',
      'conjunto' => 'Movimentações da casa, família ou despesas compartilhadas.',
      _ => 'Seu dinheiro, seus planos e seus gastos pessoais.',
    };
