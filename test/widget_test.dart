import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financas_app/models/despesa_compartilhada.dart';
import 'package:financas_app/models/perfil.dart';
import 'package:financas_app/models/transacao.dart';
import 'package:financas_app/viewmodels/finance_view_model.dart';
import 'package:financas_app/views/finance_home.dart';

void main() {
  FinanceViewModel criarViewModelInicial() {
    return FinanceViewModel()
      ..perfis = const [
        Perfil(id: 1, nome: 'Pessoal', tipo: 'pessoal', cor: '#2E7D32'),
        Perfil(id: 2, nome: 'Profissional', tipo: 'profissional'),
        Perfil(id: 3, nome: 'Conjunto', tipo: 'conjunto'),
      ]
      ..perfilSelecionado = const Perfil(
        id: 1,
        nome: 'Pessoal',
        tipo: 'pessoal',
        cor: '#2E7D32',
      )
      ..carregando = false;
  }

  testWidgets('mostra o resumo, movimentos e permite abrir a tela de contextos',
      (tester) async {
    final model = criarViewModelInicial()
      ..transacoes = [
        Transacao(
          id: 1,
          perfilId: 1,
          categoriaId: 1,
          descricao: 'Supermercado',
          valorCentavos: 15000,
          tipo: 'despesa',
          data: DateTime(2026, 11, 10),
        ),
      ];
    addTearDown(model.dispose);

    await tester.pumpWidget(MaterialApp(home: FinanceHome(model: model)));
    await tester.pumpAndSettle();

    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Saldo do mês · Pessoal'), findsOneWidget);
    expect(find.text('Supermercado'), findsOneWidget);

    await tester.tap(find.text('Movimentos'));
    await tester.pumpAndSettle();

    expect(find.text('Lançamentos'), findsOneWidget);
    expect(find.text('Supermercado'), findsOneWidget);

    await tester.tap(find.text('Contextos'));
    await tester.pumpAndSettle();

    expect(find.text('Seus contextos'), findsOneWidget);
    expect(find.text('Profissional'), findsWidgets);
    expect(find.text('Conjunto'), findsWidgets);
  });

  testWidgets('exibe divisao de despesas no contexto Conjunto', (tester) async {
    final model = criarViewModelInicial()
      ..perfilSelecionado = const Perfil(
        id: 3,
        nome: 'Conjunto',
        tipo: 'conjunto',
      )
      ..despesasCompartilhadas = [
        DespesaCompartilhada(
          id: 1,
          perfilId: 3,
          descricao: 'Conta de energia',
          valorCentavos: 20000,
          pagoPor: 'Você',
          data: DateTime(2026, 11, 15),
        ),
      ];
    addTearDown(model.dispose);

    await tester.pumpWidget(MaterialApp(home: FinanceHome(model: model)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contextos'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir divisão de despesas'));
    await tester.pumpAndSettle();

    expect(find.text('Despesas compartilhadas'), findsOneWidget);
    expect(find.text('Acerto pendente'), findsOneWidget);
    expect(find.text('Outra pessoa deve R\$ 100,00 a Você.'), findsOneWidget);
    expect(find.text('Conta de energia'), findsOneWidget);
  });
}
