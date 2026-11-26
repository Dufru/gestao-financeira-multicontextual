// Ajuste o import abaixo para o nome do pacote no seu pubspec.yaml.
import 'package:flutter_test/flutter_test.dart';
import 'package:financas_app/logica/logica.dart';

void main() {
  // Valores em centavos.
  const pessoal = Conta(
      id: 'pessoal', nome: 'Nubank', perfil: Perfil.pessoal, saldoInicial: 100000);
  const prof = Conta(
      id: 'prof', nome: 'PJ', perfil: Perfil.profissional, saldoInicial: 500000);
  const conj = Conta(
      id: 'conj', nome: 'Casa', perfil: Perfil.conjunto, saldoInicial: 200000);

  Transacao t(String id, TipoTransacao tipo, String conta, int valor, int dia,
          {String? destino}) =>
      Transacao(
        id: id,
        contaId: conta,
        tipo: tipo,
        valor: valor,
        data: DateTime(2026, 1, dia),
        contaDestinoId: destino,
      );

  final transacoes = [
    t('t1', TipoTransacao.receita, 'prof', 300000, 5),
    t('t2', TipoTransacao.despesa, 'pessoal', 25000, 10),
    t('t3', TipoTransacao.transferencia, 'prof', 100000, 15, destino: 'pessoal'),
    t('t4', TipoTransacao.transferencia, 'pessoal', 50000, 20, destino: 'conj'),
    t('t5', TipoTransacao.despesa, 'conj', 80000, 25),
  ];

  CalculadoraSaldo calc([List<Transacao>? txs]) => CalculadoraSaldo(
      contas: [pessoal, prof, conj], transacoes: txs ?? transacoes);

  group('saldo por conta e por perfil', () {
    test('aplica receita, despesa e as duas pontas da transferência', () {
      final c = calc();
      expect(c.saldoConta('pessoal'), 125000);
      expect(c.saldoConta('prof'), 700000);
      expect(c.saldoConta('conj'), 170000);
    });

    test('saldoDoPerfil soma só as contas do perfil', () {
      final c = calc();
      expect(c.saldoDoPerfil(Perfil.pessoal), 125000);
      expect(c.saldoDoPerfil(Perfil.profissional), 700000);
      expect(c.saldoDoPerfil(Perfil.conjunto), 170000);
    });

    test('perfil sem contas tem saldo zero', () {
      final c = CalculadoraSaldo(contas: [pessoal], transacoes: []);
      expect(c.saldoDoPerfil(Perfil.conjunto), 0);
    });
  });

  group('saldo consolidado (sem dupla contagem)', () {
    test('é a soma de cada conta uma vez', () {
      // 800000 iniciais + 300000 receita - 25000 - 80000 despesas
      expect(calc().saldoConsolidado(), 995000);
    });

    test('é igual à soma dos saldos dos três perfis', () {
      final c = calc();
      final soma = Perfil.values.fold(0, (s, p) => s + c.saldoDoPerfil(p));
      expect(c.saldoConsolidado(), soma);
    });

    test('transferências internas não alteram o consolidado', () {
      final semTransf = transacoes.where((x) => !x.ehTransferencia).toList();
      expect(calc(semTransf).saldoConsolidado(), calc().saldoConsolidado());
    });

    test('transação repetida (mesmo id) conta uma vez só', () {
      final duplicada = [...transacoes, ...transacoes];
      expect(calc(duplicada).saldoConsolidado(), 995000);
    });

    test('conta repetida (mesmo id) conta uma vez só', () {
      final c = CalculadoraSaldo(
          contas: [pessoal, prof, conj, conj], transacoes: transacoes);
      expect(c.saldoConsolidado(), 995000);
    });

    test('transação com conta inexistente é rejeitada', () {
      expect(
        () => CalculadoraSaldo(contas: [pessoal], transacoes: [
          t('x', TipoTransacao.despesa, 'fantasma', 100, 1),
        ]),
        throwsArgumentError,
      );
    });
  });

  group('patrimônio do usuário', () {
    test('pessoal + profissional + parte dele no conjunto', () {
      final div = DivisaoConjunto.percentuais({'ana': 60, 'bob': 40});
      // 125000 + 700000 + 60% de 170000 (102000)
      expect(calc().patrimonioDoUsuario('ana', div), 927000);
      // 125000 + 700000 + 40% de 170000 (68000)
      expect(calc().patrimonioDoUsuario('bob', div), 893000);
    });

    test('usuário fora da divisão é erro', () {
      final div = DivisaoConjunto.igualitaria(['ana', 'bob']);
      expect(() => calc().patrimonioDoUsuario('zé', div), throwsArgumentError);
    });
  });

  group('resumo do período', () {
    test('consolidado: transferências internas desaparecem', () {
      final r = calc().resumo();
      expect(r.receitas, 300000);
      expect(r.despesas, 105000);
      expect(r.transferenciasEntrada, 0);
      expect(r.transferenciasSaida, 0);
      expect(r.variacao, 195000); // 995000 - 800000
    });

    test('pessoal: transferências que cruzam o perfil aparecem', () {
      final r = calc().resumo(perfil: Perfil.pessoal);
      expect(r.despesas, 25000);
      expect(r.transferenciasEntrada, 100000);
      expect(r.transferenciasSaida, 50000);
      expect(r.variacao, 25000); // 125000 - 100000
    });

    test('profissional', () {
      final r = calc().resumo(perfil: Perfil.profissional);
      expect(r.receitas, 300000);
      expect(r.transferenciasSaida, 100000);
      expect(r.variacao, 200000); // 700000 - 500000
    });

    test('conjunto', () {
      final r = calc().resumo(perfil: Perfil.conjunto);
      expect(r.despesas, 80000);
      expect(r.transferenciasEntrada, 50000);
      expect(r.variacao, -30000); // 170000 - 200000
    });

    test('filtra por período [inicio, fim)', () {
      final r = calc().resumo(
        perfil: Perfil.pessoal,
        inicio: DateTime(2026, 1, 10),
        fim: DateTime(2026, 1, 20), // t4 (dia 20) fica de fora
      );
      expect(r.despesas, 25000);
      expect(r.transferenciasEntrada, 100000);
      expect(r.transferenciasSaida, 0);
      expect(r.variacao, 75000);
    });
  });

  group('validação de Transacao', () {
    test('valor deve ser positivo', () {
      expect(() => t('x', TipoTransacao.despesa, 'pessoal', 0, 1),
          throwsArgumentError);
    });
    test('transferência exige destino diferente da origem', () {
      expect(() => t('x', TipoTransacao.transferencia, 'pessoal', 1, 1),
          throwsArgumentError);
      expect(
          () => t('x', TipoTransacao.transferencia, 'pessoal', 1, 1,
              destino: 'pessoal'),
          throwsArgumentError);
    });
    test('destino só vale para transferência', () {
      expect(
          () => t('x', TipoTransacao.despesa, 'pessoal', 1, 1, destino: 'prof'),
          throwsArgumentError);
    });
  });
}
