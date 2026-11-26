import '../database/app_database.dart';
import '../models/despesa_compartilhada.dart';

class DespesaCompartilhadaRepository {
  Future<List<DespesaCompartilhada>> listar(int perfilId) async {
    final db = await AppDatabase.instance.database;
    final linhas = await db.query(
      'despesa_compartilhada',
      where: 'perfil_id = ?',
      whereArgs: [perfilId],
      orderBy: 'data DESC, id DESC',
    );
    return linhas.map(DespesaCompartilhada.fromMap).toList();
  }

  Future<int> inserir(DespesaCompartilhada despesa) async {
    final db = await AppDatabase.instance.database;
    return db.insert(
      'despesa_compartilhada',
      despesa.toMap()..remove('id'),
    );
  }

  Future<int> excluir(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete(
      'despesa_compartilhada',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
