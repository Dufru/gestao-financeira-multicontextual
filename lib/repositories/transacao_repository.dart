import '../database/app_database.dart';
import '../models/transacao.dart';

class TransacaoRepository {
  Future<int> inserir(Transacao transacao) async {
    final db = await AppDatabase.instance.database;
    final dados = transacao.toMap()..remove('id');
    return db.insert('transacao', dados);
  }

  Future<List<Transacao>> listarPorPerfil(int perfilId) async {
    final db = await AppDatabase.instance.database;
    final linhas = await db.query(
      'transacao',
      where: 'perfil_id = ?',
      whereArgs: [perfilId],
      orderBy: 'data DESC, id DESC',
    );
    return linhas.map(Transacao.fromMap).toList();
  }

  Future<int> atualizar(Transacao transacao) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'transacao',
      transacao.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [transacao.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete(
      'transacao',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}