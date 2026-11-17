import '../database/app_database.dart';
import '../models/categoria.dart';

class CategoriaRepository {
  Future<List<Categoria>> listar({String? tipo}) async {
    final db = await AppDatabase.instance.database;
    final linhas = await db.query(
      'categoria',
      where: tipo != null ? 'tipo = ?' : null,
      whereArgs: tipo != null ? [tipo] : null,
      orderBy: 'nome',
    );
    return linhas.map(Categoria.fromMap).toList();
  }
}