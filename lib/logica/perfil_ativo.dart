import 'package:flutter/foundation.dart';

import 'modelos.dart';
import 'perfil.dart';

/// Guarda qual perfil está ativo e filtra o que a tela deve mostrar.
/// Use com `ListenableBuilder(listenable: controller, ...)`.
class PerfilAtivoController extends ChangeNotifier {
  Perfil _ativo;

  PerfilAtivoController({Perfil inicial = Perfil.pessoal}) : _ativo = inicial;

  Perfil get ativo => _ativo;

  /// Troca o perfil; só notifica se realmente mudou.
  void selecionar(Perfil perfil) {
    if (perfil == _ativo) return;
    _ativo = perfil;
    notifyListeners();
  }

  /// Contas visíveis no perfil ativo.
  List<Conta> contasVisiveis(Iterable<Conta> contas) =>
      contas.where((c) => c.perfil == _ativo).toList();

  /// Transações que tocam alguma conta do perfil ativo (origem ou destino).
  /// Uma transferência entre perfis aparece nos dois, mas isso é só
  /// exibição: o saldo consolidado vem de CalculadoraSaldo, que não soma
  /// transações e sim contas.
  List<Transacao> transacoesVisiveis(
    Iterable<Conta> contas,
    Iterable<Transacao> transacoes,
  ) {
    final ids = contasVisiveis(contas).map((c) => c.id).toSet();
    return transacoes
        .where((t) =>
            ids.contains(t.contaId) ||
            (t.contaDestinoId != null && ids.contains(t.contaDestinoId)))
        .toList();
  }
}
