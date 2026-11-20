import '../database/app_database.dart';
import '../models/resumo_financeiro.dart';

class SaldoRepository {
  Future<ResumoFinanceiro> resumoDoPerfil(int perfilId) async {
    final db = await AppDatabase.instance.database;

    final resultado = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN tipo = 'receita' THEN valor_centavos ELSE 0 END), 0) AS receitas,
        COALESCE(SUM(CASE WHEN tipo = 'despesa' THEN valor_centavos ELSE 0 END), 0) AS despesas
      FROM transacao
      WHERE perfil_id = ?
    ''', [perfilId]);

    final linha = resultado.first;
    return ResumoFinanceiro(
      receitasCentavos: linha['receitas'] as int,
      despesasCentavos: linha['despesas'] as int,
    );
  }

  Future<ResumoFinanceiro> resumoConsolidado() async {
    final db = await AppDatabase.instance.database;

    final resultado = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN tipo = 'receita' THEN valor_centavos ELSE 0 END), 0) AS receitas,
        COALESCE(SUM(CASE WHEN tipo = 'despesa' THEN valor_centavos ELSE 0 END), 0) AS despesas
      FROM transacao
    ''');

    final linha = resultado.first;
    return ResumoFinanceiro(
      receitasCentavos: linha['receitas'] as int,
      despesasCentavos: linha['despesas'] as int,
    );
  }
}