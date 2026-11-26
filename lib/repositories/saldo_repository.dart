import '../database/app_database.dart';
import '../models/resumo_financeiro.dart';

class SaldoRepository {
  Future<ResumoFinanceiro> resumoDoPerfil(
    int perfilId, {
    DateTime? inicio,
    DateTime? fim,
  }) async {
    final db = await AppDatabase.instance.database;
    final filtros = <String>['perfil_id = ?'];
    final argumentos = <Object?>[perfilId];
    if (inicio != null) {
      filtros.add('data >= ?');
      argumentos.add(_dataSql(inicio));
    }
    if (fim != null) {
      filtros.add('data < ?');
      argumentos.add(_dataSql(fim));
    }

    final resultado = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN tipo = 'receita' THEN valor_centavos ELSE 0 END), 0) AS receitas,
        COALESCE(SUM(CASE WHEN tipo = 'despesa' THEN valor_centavos ELSE 0 END), 0) AS despesas
      FROM transacao
      WHERE ${filtros.join(' AND ')}
    ''', argumentos);

    final linha = resultado.first;
    return ResumoFinanceiro(
      receitasCentavos: linha['receitas'] as int,
      despesasCentavos: linha['despesas'] as int,
    );
  }

  Future<ResumoFinanceiro> resumoConsolidado({
    DateTime? inicio,
    DateTime? fim,
  }) async {
    final db = await AppDatabase.instance.database;
    final filtros = <String>[];
    final argumentos = <Object?>[];
    if (inicio != null) {
      filtros.add('data >= ?');
      argumentos.add(_dataSql(inicio));
    }
    if (fim != null) {
      filtros.add('data < ?');
      argumentos.add(_dataSql(fim));
    }

    final resultado = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN tipo = 'receita' THEN valor_centavos ELSE 0 END), 0) AS receitas,
        COALESCE(SUM(CASE WHEN tipo = 'despesa' THEN valor_centavos ELSE 0 END), 0) AS despesas
      FROM transacao
      ${filtros.isEmpty ? '' : 'WHERE ${filtros.join(' AND ')}'}
    ''', argumentos);

    final linha = resultado.first;
    return ResumoFinanceiro(
      receitasCentavos: linha['receitas'] as int,
      despesasCentavos: linha['despesas'] as int,
    );
  }

  String _dataSql(DateTime data) =>
      '${data.year.toString().padLeft(4, '0')}-'
      '${data.month.toString().padLeft(2, '0')}-'
      '${data.day.toString().padLeft(2, '0')}';
}
