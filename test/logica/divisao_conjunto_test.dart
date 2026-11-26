// Ajuste o import abaixo para o nome do pacote no seu pubspec.yaml.
import 'package:flutter_test/flutter_test.dart';
import 'package:financas_app/logica/logica.dart';

void main() {
  int soma(Map<String, int> m) => m.values.fold(0, (a, b) => a + b);

  group('ratear', () {
    test('divide exato quando possível', () {
      expect(ratear(1000, {'a': 7000, 'b': 3000}), {'a': 700, 'b': 300});
    });

    test('centavo que sobra vai para o maior resto, depois para o primeiro', () {
      expect(ratear(100, {'a': 1, 'b': 1, 'c': 1}), {'a': 34, 'b': 33, 'c': 33});
      expect(ratear(10, {'a': 1, 'b': 2}), {'a': 3, 'b': 7});
      expect(ratear(1, {'a': 1, 'b': 1}), {'a': 1, 'b': 0});
    });

    test('a soma do rateio é sempre o valor original', () {
      for (final v in [0, 1, 7, 99, 10001, 123456789]) {
        final r = ratear(v, {'a': 3, 'b': 5, 'c': 11, 'd': 1});
        expect(soma(r), v, reason: 'valor $v');
      }
    });

    test('valor negativo mantém o sinal e a soma', () {
      final r = ratear(-100, {'a': 1, 'b': 1, 'c': 1});
      expect(r, {'a': -34, 'b': -33, 'c': -33});
      expect(soma(r), -100);
    });

    test('participante com peso zero recebe zero', () {
      expect(ratear(100, {'a': 1, 'b': 0}), {'a': 100, 'b': 0});
    });

    test('pesos inválidos são rejeitados', () {
      expect(() => ratear(100, {}), throwsArgumentError);
      expect(() => ratear(100, {'a': 0, 'b': 0}), throwsArgumentError);
      expect(() => ratear(100, {'a': -1, 'b': 2}), throwsArgumentError);
    });
  });

  group('DivisaoConjunto', () {
    test('igualitária 50/50', () {
      final d = DivisaoConjunto.igualitaria(['ana', 'bob']);
      expect(d.ratear(10000), {'ana': 5000, 'bob': 5000});
    });

    test('igualitária com 3 pessoas não perde centavo', () {
      final d = DivisaoConjunto.igualitaria(['a', 'b', 'c']);
      final r = d.ratear(10000);
      expect(r, {'a': 3334, 'b': 3333, 'c': 3333});
      expect(soma(r), 10000);
    });

    test('percentuais devem somar 100', () {
      expect(() => DivisaoConjunto.percentuais({'a': 60, 'b': 30}),
          throwsArgumentError);
      final d = DivisaoConjunto.percentuais({'a': 60, 'b': 40});
      expect(d.ratear(10000), {'a': 6000, 'b': 4000});
    });

    test('proporcional à renda', () {
      final d = DivisaoConjunto.proporcionalARenda({'ana': 300000, 'bob': 100000});
      expect(d.ratear(10000), {'ana': 7500, 'bob': 2500});
    });
  });

  group('calcularAcerto', () {
    DespesaCompartilhada desp(String id, String quem, int valor) =>
        DespesaCompartilhada(
            id: id, pagoPor: quem, valor: valor, data: DateTime(2026, 1, 1));

    test('dois participantes 50/50', () {
      final r = calcularAcerto(
        [desp('d1', 'ana', 30000), desp('d2', 'bob', 10000), desp('d3', 'ana', 20000)],
        DivisaoConjunto.igualitaria(['ana', 'bob']),
      );
      expect(r.pago, {'ana': 50000, 'bob': 10000});
      expect(r.devido, {'ana': 30000, 'bob': 30000});
      expect(r.saldoLiquido, {'ana': 20000, 'bob': -20000});
      expect(r.acertos.length, 1);
      expect(r.acertos.first.de, 'bob');
      expect(r.acertos.first.para, 'ana');
      expect(r.acertos.first.valor, 20000);
    });

    test('três participantes: dois devedores pagam a quem adiantou', () {
      final r = calcularAcerto(
        [desp('d1', 'ana', 90000)],
        DivisaoConjunto.igualitaria(['ana', 'bob', 'cris']),
      );
      expect(r.saldoLiquido, {'ana': 60000, 'bob': -30000, 'cris': -30000});
      expect(soma(r.saldoLiquido), 0);
      expect(r.acertos.map((a) => '${a.de}>${a.para}:${a.valor}').toList(),
          ['bob>ana:30000', 'cris>ana:30000']);
    });

    test('divisão 60/40 com centavo ímpar fecha a conta', () {
      final r = calcularAcerto(
        [desp('d1', 'ana', 10001)],
        DivisaoConjunto.percentuais({'ana': 60, 'bob': 40}),
      );
      expect(r.devido, {'ana': 6001, 'bob': 4000});
      expect(r.saldoLiquido, {'ana': 4000, 'bob': -4000});
      expect(r.acertos.single.valor, 4000);
    });

    test('quem já está quite não gera acerto', () {
      final r = calcularAcerto(
        [desp('d1', 'ana', 30000), desp('d2', 'bob', 30000)],
        DivisaoConjunto.igualitaria(['ana', 'bob']),
      );
      expect(r.acertos, isEmpty);
    });

    test('sem despesas, sem acertos', () {
      final r = calcularAcerto([], DivisaoConjunto.igualitaria(['ana', 'bob']));
      expect(r.acertos, isEmpty);
      expect(r.saldoLiquido, {'ana': 0, 'bob': 0});
    });

    test('despesa repetida (mesmo id) conta uma vez', () {
      final r = calcularAcerto(
        [desp('d1', 'ana', 30000), desp('d1', 'ana', 30000)],
        DivisaoConjunto.igualitaria(['ana', 'bob']),
      );
      expect(r.pago['ana'], 30000);
    });

    test('pagador fora da divisão é erro', () {
      expect(
        () => calcularAcerto(
            [desp('d1', 'intruso', 100)], DivisaoConjunto.igualitaria(['ana', 'bob'])),
        throwsArgumentError,
      );
    });
  });
}
