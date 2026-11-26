import 'divisao_conjunto.dart';
import 'modelos.dart';
import 'perfil.dart';

/// Totais de um período para um escopo de contas (um perfil ou todos).
///
/// Transferências entre contas DENTRO do escopo são ignoradas (se anulam).
/// Só aparecem como [transferenciasEntrada]/[transferenciasSaida] as que
/// cruzam a fronteira do escopo.
class ResumoPeriodo {
  final int receitas;
  final int despesas;
  final int transferenciasEntrada;
  final int transferenciasSaida;

  const ResumoPeriodo({
    required this.receitas,
    required this.despesas,
    required this.transferenciasEntrada,
    required this.transferenciasSaida,
  });

  /// Variação líquida do saldo no período.
  int get variacao =>
      receitas - despesas + transferenciasEntrada - transferenciasSaida;
}

class CalculadoraSaldo {
  final Map<String, Conta> _contas;
  final List<Transacao> _transacoes;

  /// Contas e transações são deduplicadas por [id]: se a mesma conta ou
  /// transação vier duas vezes (ex.: listada em duas telas), conta uma só vez.
  CalculadoraSaldo({
    required Iterable<Conta> contas,
    required Iterable<Transacao> transacoes,
  })  : _contas = {for (final c in contas) c.id: c},
        _transacoes = {for (final t in transacoes) t.id: t}.values.toList() {
    for (final t in _transacoes) {
      for (final id in [t.contaId, if (t.contaDestinoId != null) t.contaDestinoId!]) {
        if (!_contas.containsKey(id)) {
          throw ArgumentError(
              'Transação ${t.id} referencia conta inexistente: $id');
        }
      }
    }
  }

  /// Efeito de uma transação no saldo de uma conta específica.
  static int _efeito(Transacao t, String contaId) {
    switch (t.tipo) {
      case TipoTransacao.receita:
        return t.contaId == contaId ? t.valor : 0;
      case TipoTransacao.despesa:
        return t.contaId == contaId ? -t.valor : 0;
      case TipoTransacao.transferencia:
        if (t.contaId == contaId) return -t.valor;
        if (t.contaDestinoId == contaId) return t.valor;
        return 0;
    }
  }

  int saldoConta(String contaId) {
    final conta = _contas[contaId];
    if (conta == null) throw ArgumentError('Conta inexistente: $contaId');
    return _transacoes.fold(
        conta.saldoInicial, (soma, t) => soma + _efeito(t, contaId));
  }

  Iterable<Conta> _contasDoEscopo(Perfil? perfil) =>
      _contas.values.where((c) => perfil == null || c.perfil == perfil);

  /// Saldo das contas de UM perfil (sem contas dos outros).
  int saldoDoPerfil(Perfil perfil) => _contasDoEscopo(perfil)
      .fold(0, (soma, c) => soma + saldoConta(c.id));

  /// Saldo consolidado: cada conta entra UMA vez. Transferências internas
  /// não alteram o total, pois uma ponta debita e a outra credita.
  int saldoConsolidado() =>
      _contasDoEscopo(null).fold(0, (soma, c) => soma + saldoConta(c.id));

  /// Patrimônio do usuário: pessoal + profissional + a PARTE dele no conjunto.
  /// Diferente do consolidado, que soma o conjunto inteiro.
  int patrimonioDoUsuario(String usuarioId, DivisaoConjunto divisao) {
    final parte = divisao.ratear(saldoDoPerfil(Perfil.conjunto))[usuarioId];
    if (parte == null) {
      throw ArgumentError('Usuário $usuarioId não participa da divisão');
    }
    return saldoDoPerfil(Perfil.pessoal) +
        saldoDoPerfil(Perfil.profissional) +
        parte;
  }

  /// Totais do período [inicio, fim) para um perfil, ou todos se [perfil]
  /// for nulo. Limites nulos significam "sem limite".
  ResumoPeriodo resumo({Perfil? perfil, DateTime? inicio, DateTime? fim}) {
    final ids = _contasDoEscopo(perfil).map((c) => c.id).toSet();
    var receitas = 0, despesas = 0, entrada = 0, saida = 0;

    for (final t in _transacoes) {
      if (inicio != null && t.data.isBefore(inicio)) continue;
      if (fim != null && !t.data.isBefore(fim)) continue;

      final origemDentro = ids.contains(t.contaId);
      switch (t.tipo) {
        case TipoTransacao.receita:
          if (origemDentro) receitas += t.valor;
        case TipoTransacao.despesa:
          if (origemDentro) despesas += t.valor;
        case TipoTransacao.transferencia:
          final destinoDentro = ids.contains(t.contaDestinoId);
          if (origemDentro && !destinoDentro) saida += t.valor;
          if (!origemDentro && destinoDentro) entrada += t.valor;
      }
    }
    return ResumoPeriodo(
      receitas: receitas,
      despesas: despesas,
      transferenciasEntrada: entrada,
      transferenciasSaida: saida,
    );
  }
}
