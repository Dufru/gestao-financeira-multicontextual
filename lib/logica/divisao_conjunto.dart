import 'dart:math' as math;

/// Rateia [valor] (centavos) proporcionalmente a [pesos], sem perder nem criar
/// centavos: a soma do resultado é SEMPRE igual a [valor].
/// Método do maior resto; empate resolvido pela ordem dos participantes.
/// Aceita valor negativo (o sinal é preservado).
Map<String, int> ratear(int valor, Map<String, int> pesos) {
  _validarPesos(pesos);
  final totalPesos = pesos.values.fold<int>(0, (a, b) => a + b);
  final absoluto = valor.abs();
  final chaves = pesos.keys.toList();

  final base = <String, int>{};
  final restos = <String, int>{};
  var distribuido = 0;
  for (final k in chaves) {
    final produto = absoluto * pesos[k]!;
    base[k] = produto ~/ totalPesos;
    restos[k] = produto % totalPesos;
    distribuido += base[k]!;
  }

  var faltam = absoluto - distribuido;
  final ordem = List<int>.generate(chaves.length, (i) => i)
    ..sort((a, b) {
      final c = restos[chaves[b]]!.compareTo(restos[chaves[a]]!);
      return c != 0 ? c : a.compareTo(b);
    });
  for (final i in ordem) {
    if (faltam == 0) break;
    base[chaves[i]] = base[chaves[i]]! + 1;
    faltam--;
  }

  final sinal = valor < 0 ? -1 : 1;
  return {for (final k in chaves) k: base[k]! * sinal};
}

void _validarPesos(Map<String, int> pesos) {
  if (pesos.isEmpty) throw ArgumentError('Informe ao menos um participante');
  if (pesos.values.any((p) => p < 0)) {
    throw ArgumentError('Pesos não podem ser negativos');
  }
  if (pesos.values.fold<int>(0, (a, b) => a + b) <= 0) {
    throw ArgumentError('A soma dos pesos deve ser maior que zero');
  }
}

/// Como o perfil Conjunto é dividido entre os participantes.
class DivisaoConjunto {
  final Map<String, int> pesos;

  DivisaoConjunto(Map<String, int> pesos) : pesos = Map.unmodifiable(pesos) {
    _validarPesos(pesos);
  }

  /// Partes iguais (50/50 com dois participantes).
  factory DivisaoConjunto.igualitaria(List<String> participantes) =>
      DivisaoConjunto({for (final p in participantes) p: 1});

  /// Percentuais explícitos; a soma deve ser exatamente 100.
  factory DivisaoConjunto.percentuais(Map<String, int> percentuais) {
    if (percentuais.values.fold<int>(0, (a, b) => a + b) != 100) {
      throw ArgumentError('Os percentuais devem somar 100');
    }
    return DivisaoConjunto(percentuais);
  }

  /// Proporcional à renda (em centavos) de cada participante.
  factory DivisaoConjunto.proporcionalARenda(Map<String, int> rendas) =>
      DivisaoConjunto(rendas);

  Iterable<String> get participantes => pesos.keys;

  Map<String, int> ratear(int valor) => _ratear(valor, pesos);
}

// Alias para evitar sombreamento do método com a função de topo.
Map<String, int> _ratear(int valor, Map<String, int> pesos) =>
    ratear(valor, pesos);

/// Despesa do conjunto paga do bolso de um participante (não saiu da conta
/// conjunta, então não altera nenhum saldo de conta; só gera acerto).
class DespesaCompartilhada {
  final String id;
  final String pagoPor;
  final int valor;
  final DateTime data;
  final String descricao;

  DespesaCompartilhada({
    required this.id,
    required this.pagoPor,
    required this.valor,
    required this.data,
    this.descricao = '',
  }) {
    if (valor <= 0) {
      throw ArgumentError.value(valor, 'valor', 'deve ser positivo');
    }
  }
}

/// "[de] deve [valor] centavos a [para]".
class Acerto {
  final String de;
  final String para;
  final int valor;
  const Acerto({required this.de, required this.para, required this.valor});

  @override
  String toString() => '$de -> $para: $valor';
}

class ResultadoAcerto {
  /// O que cada um pagou do próprio bolso.
  final Map<String, int> pago;

  /// A parte que cada um devia arcar, segundo a divisão.
  final Map<String, int> devido;

  /// pago - devido. Positivo = tem a receber; negativo = tem a pagar.
  /// A soma é sempre zero.
  final Map<String, int> saldoLiquido;

  /// Menor sequência simples de pagamentos que zera todos os saldos.
  final List<Acerto> acertos;

  const ResultadoAcerto({
    required this.pago,
    required this.devido,
    required this.saldoLiquido,
    required this.acertos,
  });
}

class _Posicao {
  final String nome;
  int valor;
  _Posicao(this.nome, this.valor);
}

/// Calcula quem deve quanto a quem. O total das despesas é rateado de uma vez
/// (não despesa a despesa) para o arredondamento não acumular.
ResultadoAcerto calcularAcerto(
  Iterable<DespesaCompartilhada> despesas,
  DivisaoConjunto divisao,
) {
  final unicas = {for (final d in despesas) d.id: d}.values;

  final pago = {for (final p in divisao.participantes) p: 0};
  for (final d in unicas) {
    if (!pago.containsKey(d.pagoPor)) {
      throw ArgumentError(
          'Despesa ${d.id} paga por quem não participa da divisão: ${d.pagoPor}');
    }
    pago[d.pagoPor] = pago[d.pagoPor]! + d.valor;
  }

  final total = pago.values.fold<int>(0, (a, b) => a + b);
  final devido = divisao.ratear(total);
  final saldo = {for (final p in pago.keys) p: pago[p]! - devido[p]!};

  return ResultadoAcerto(
    pago: pago,
    devido: devido,
    saldoLiquido: saldo,
    acertos: _simplificar(saldo),
  );
}

List<Acerto> _simplificar(Map<String, int> saldo) {
  int ordenar(_Posicao a, _Posicao b) {
    final c = b.valor.compareTo(a.valor);
    return c != 0 ? c : a.nome.compareTo(b.nome);
  }

  final devedores = [
    for (final e in saldo.entries)
      if (e.value < 0) _Posicao(e.key, -e.value)
  ]..sort(ordenar);
  final credores = [
    for (final e in saldo.entries)
      if (e.value > 0) _Posicao(e.key, e.value)
  ]..sort(ordenar);

  final acertos = <Acerto>[];
  var i = 0, j = 0;
  while (i < devedores.length && j < credores.length) {
    final d = devedores[i], c = credores[j];
    final v = math.min(d.valor, c.valor);
    acertos.add(Acerto(de: d.nome, para: c.nome, valor: v));
    d.valor -= v;
    c.valor -= v;
    if (d.valor == 0) i++;
    if (c.valor == 0) j++;
  }
  return acertos;
}
