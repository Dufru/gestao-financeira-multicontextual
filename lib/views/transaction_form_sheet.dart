import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../models/transacao.dart';
import '../utils/formatters.dart';
import '../viewmodels/finance_view_model.dart';

Future<void> abrirFormularioTransacao(
  BuildContext context,
  FinanceViewModel model, {
  Transacao? transacao,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => TransactionFormSheet(model: model, transacao: transacao),
  );
}

class TransactionFormSheet extends StatefulWidget {
  const TransactionFormSheet({
    super.key,
    required this.model,
    this.transacao,
  });

  final FinanceViewModel model;
  final Transacao? transacao;

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricaoController;
  late final TextEditingController _valorController;
  late String _tipo;
  late DateTime _data;
  int? _categoriaId;
  bool _salvando = false;
  String? _erro;

  List<Categoria> get _categorias =>
      widget.model.categorias.where((c) => c.tipo == _tipo).toList();

  @override
  void initState() {
    super.initState();
    final transacao = widget.transacao;
    _descricaoController = TextEditingController(text: transacao?.descricao ?? '');
    _valorController = TextEditingController(
      text: transacao == null
          ? ''
          : '${(transacao.valorCentavos ~/ 100)},'
              '${(transacao.valorCentavos % 100).toString().padLeft(2, '0')}',
    );
    _tipo = transacao?.tipo ?? 'despesa';
    _data = transacao?.data ?? DateTime.now();
    _categoriaId = transacao?.categoriaId;
    if (_categorias.isNotEmpty &&
        !_categorias.any((categoria) => categoria.id == _categoriaId)) {
      _categoriaId = _categorias.first.id;
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final agora = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime(agora.year + 5),
      locale: const Locale('pt', 'BR'),
    );
    if (data != null) setState(() => _data = data);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final valor = lerValorEmCentavos(_valorController.text);
    if (valor == null || valor <= 0 || _categoriaId == null) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.model.salvarTransacao(Transacao(
        id: widget.transacao?.id,
        perfilId: widget.model.perfilSelecionado!.id,
        categoriaId: _categoriaId!,
        descricao: _descricaoController.text,
        valorCentavos: valor,
        tipo: _tipo,
        data: DateTime(_data.year, _data.month, _data.day),
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (exception) {
      if (mounted) {
        setState(() {
          _erro = 'Não foi possível salvar. Tente novamente.';
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cores.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                widget.transacao == null ? 'Novo lançamento' : 'Editar lançamento',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 18),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'despesa',
                    label: Text('Despesa'),
                    icon: Icon(Icons.arrow_upward_rounded),
                  ),
                  ButtonSegment(
                    value: 'receita',
                    label: Text('Receita'),
                    icon: Icon(Icons.arrow_downward_rounded),
                  ),
                ],
                selected: {_tipo},
                onSelectionChanged: (selecionado) {
                  setState(() {
                    _tipo = selecionado.first;
                    _categoriaId = _categorias.isEmpty ? null : _categorias.first.id;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                ),
                validator: (texto) {
                  final valor = lerValorEmCentavos(texto ?? '');
                  return valor == null || valor <= 0
                      ? 'Informe um valor maior que zero'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descricaoController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Ex.: mercado, salário, conta de luz',
                ),
                validator: (texto) => (texto?.trim().isEmpty ?? true)
                    ? 'Descreva o lançamento'
                    : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _categoriaId,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: _categorias
                    .map((categoria) => DropdownMenuItem(
                          value: categoria.id,
                          child: Text(categoria.nome),
                        ))
                    .toList(),
                onChanged: (id) => setState(() => _categoriaId = id),
                validator: (_) => _categoriaId == null
                    ? 'Nenhuma categoria disponível'
                    : null,
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_rounded),
                title: const Text('Data do lançamento'),
                subtitle: Text(formatarData(_data)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _selecionarData,
              ),
              if (_erro != null) ...[
                const SizedBox(height: 6),
                Text(_erro!, style: TextStyle(color: cores.error)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_salvando ? 'Salvando...' : 'Salvar lançamento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
