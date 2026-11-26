import 'perfil.dart';

/// Todos os valores monetários são inteiros em CENTAVOS (R$ 10,50 = 1050).
/// Evita erros de ponto flutuante nas somas e divisões.
enum TipoTransacao { receita, despesa, transferencia }

/// Uma conta pertence a exatamente UM perfil. É isso que garante que o saldo
/// consolidado nunca conte a mesma conta duas vezes.
class Conta {
  final String id;
  final String nome;
  final Perfil perfil;
  final int saldoInicial;

  const Conta({
    required this.id,
    required this.nome,
    required this.perfil,
    this.saldoInicial = 0,
  });
}

/// Movimentação em uma conta.
/// - receita: entra em [contaId]
/// - despesa: sai de [contaId]
/// - transferencia: sai de [contaId] e entra em [contaDestinoId]
///
/// [valor] é sempre positivo; o sentido vem do [tipo].
class Transacao {
  final String id;
  final String contaId;
  final TipoTransacao tipo;
  final int valor;
  final DateTime data;
  final String? contaDestinoId;

  Transacao({
    required this.id,
    required this.contaId,
    required this.tipo,
    required this.valor,
    required this.data,
    this.contaDestinoId,
  }) {
    if (valor <= 0) {
      throw ArgumentError.value(valor, 'valor', 'deve ser positivo');
    }
    if (tipo == TipoTransacao.transferencia) {
      if (contaDestinoId == null) {
        throw ArgumentError('transferência exige contaDestinoId');
      }
      if (contaDestinoId == contaId) {
        throw ArgumentError('origem e destino não podem ser a mesma conta');
      }
    } else if (contaDestinoId != null) {
      throw ArgumentError('contaDestinoId só vale para transferência');
    }
  }

  bool get ehTransferencia => tipo == TipoTransacao.transferencia;
}
