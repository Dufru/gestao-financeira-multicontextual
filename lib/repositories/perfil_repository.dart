import '../database/app_database.dart';
import '../models/perfil.dart';

class PerfilRepository {
  Future<List<Perfil>> listar() async {
    final db = await AppDatabase.instance.database;
    final linhas = await db.query('perfil', orderBy: 'id');
    return linhas.map(Perfil.fromMap).toList();
  }
}