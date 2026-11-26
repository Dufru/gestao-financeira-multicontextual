import 'package:flutter/material.dart';
import '../models/despesa_compartilhada.dart';
import '../utils/formatters.dart';
import '../viewmodels/finance_view_model.dart';

Future<void> abrirFormularioDespesaConjunta(
  BuildContext context,
  FinanceViewModel model,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _FormularioDespesaConjunta(model: model),
  );
}

class JointExpensesPage extends StatelessWidget {
  const JointExpensesPage({
    super.key,
    required this.model,
    required this.aoAdicionar,
  });

  final FinanceViewModel model;
  final VoidCallback aoAdicionar;

  Future<void> _excluir(BuildContext context, DespesaCompartilhada despesa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir despesa?'),
        content: Text('“${despesa.descricao}” será removida do rateio.'),
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
    if (confirmar == true && despesa.id != null) {
      await model.excluirDespesaCompartilhada(despesa.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultado = model.resultadoAcerto;
    final quitado = resultado.acertos.isEmpty;
    final acerto = resultado.acertos.isEmpty ? null : resultado.acertos.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: quitado ? const Color(0xFFEAF2ED) : const Color(0xFFFFF2DF),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    quitado ? Icons.check_circle_rounded : Icons.swap_horiz_rounded,
                    color: quitado ? const Color(0xFF176B53) : const Color(0xFFB06A11),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    quitado ? 'Tudo equilibrado' : 'Acerto pendente',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                quitado
                    ? 'Registre uma despesa paga por alguém para calcular a divisão meio a meio.'
                    : '${acerto!.de} deve ${formatarMoeda(acerto.valor)} a ${acerto.para}.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FinanceViewModel.participantesConjunto.map((nome) {
                  final saldo = resultado.saldoLiquido[nome] ?? 0;
                  return Chip(
                    avatar: Icon(
                      saldo > 0
                          ? Icons.south_west_rounded
                          : saldo < 0
                              ? Icons.north_east_rounded
                              : Icons.done_rounded,
                      size: 16,
                      color: saldo < 0
                          ? const Color(0xFFB06A11)
                          : const Color(0xFF176B53),
                    ),
                    label: Text(saldo == 0
                        ? '$nome · quite'
                        : '$nome · ${saldo > 0 ? 'recebe' : 'paga'} ${formatarMoeda(saldo.abs())}'),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text('Despesas registradas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
            ),
            Text('${model.despesasCompartilhadas.length}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 7),
        if (model.despesasCompartilhadas.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Text(
              'Quando alguém pagar uma conta compartilhada, registre aqui. O app calcula automaticamente quem deve acertar com quem.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.4),
            ),
          )
        else
          ...model.despesasCompartilhadas.map((despesa) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(despesa.descricao,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${despesa.pagoPor} pagou · ${formatarData(despesa.data)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatarMoeda(despesa.valorCentavos),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      PopupMenuButton<String>(
                        tooltip: 'Opções da despesa',
                        onSelected: (v) {
                          if (v == 'excluir') _excluir(context, despesa);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: aoAdicionar,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Registrar despesa compartilhada'),
        ),
        const SizedBox(height: 12),
        Text(
          'Divisão igualitária entre Você e Outra pessoa. O rateio usa centavos inteiros e não perde valores no arredondamento.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _FormularioDespesaConjunta extends StatefulWidget {
  const _FormularioDespesaConjunta({required this.model});
  final FinanceViewModel model;

  @override
  State<_FormularioDespesaConjunta> createState() =>
      _FormularioDespesaConjuntaState();
}

class _FormularioDespesaConjuntaState extends State<_FormularioDespesaConjunta> {
  final _form = GlobalKey<FormState>();
  final _descricao = TextEditingController();
  final _valor = TextEditingController();
  String _pagador = FinanceViewModel.participantesConjunto.first;
  DateTime _data = DateTime.now();
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    final centavos = lerValorEmCentavos(_valor.text);
    if (centavos == null) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.model.salvarDespesaCompartilhada(
        descricao: _descricao.text,
        valorCentavos: centavos,
        pagoPor: _pagador,
        data: _data,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _erro = 'Não foi possível salvar a despesa.';
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 15, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nova despesa compartilhada',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricao,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'O que foi pago?',
                  hintText: 'Ex.: conta de luz',
                ),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'Informe a descrição'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valor,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                ),
                validator: (v) {
                  final valor = lerValorEmCentavos(v ?? '');
                  return valor == null || valor <= 0
                      ? 'Informe um valor maior que zero'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _pagador,
                decoration: const InputDecoration(labelText: 'Quem pagou?'),
                items: FinanceViewModel.participantesConjunto
                    .map((nome) => DropdownMenuItem(value: nome, child: Text(nome)))
                    .toList(),
                onChanged: (nome) {
                  if (nome != null) setState(() => _pagador = nome);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_rounded),
                title: const Text('Data'),
                subtitle: Text(formatarData(_data)),
                onTap: () async {
                  final data = await showDatePicker(
                    context: context,
                    initialDate: _data,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(DateTime.now().year + 5),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (data != null) setState(() => _data = data);
                },
              ),
              if (_erro != null) Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                  label: Text(_salvando ? 'Salvando...' : 'Salvar despesa'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
