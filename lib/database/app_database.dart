import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _nomeBanco = 'financas.db';
  static const _versao = 2;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _abrir();
    return _db!;
  }

  Future<Database> _abrir() async {
    final pasta = await getDatabasesPath();
    final caminho = join(pasta, _nomeBanco);

    return openDatabase(
      caminho,
      version: _versao,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE perfil (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        nome  TEXT NOT NULL,
        tipo  TEXT NOT NULL
              CHECK (tipo IN ('pessoal', 'profissional', 'conjunto')),
        cor   TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categoria (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        nome  TEXT NOT NULL,
        tipo  TEXT NOT NULL
              CHECK (tipo IN ('receita', 'despesa'))
      )
    ''');

    await db.execute('''
      CREATE TABLE transacao (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        perfil_id       INTEGER NOT NULL,
        categoria_id    INTEGER NOT NULL,
        descricao       TEXT NOT NULL,
        valor_centavos  INTEGER NOT NULL CHECK (valor_centavos > 0),
        tipo            TEXT NOT NULL
                        CHECK (tipo IN ('receita', 'despesa')),
        data            TEXT NOT NULL,
        FOREIGN KEY (perfil_id)    REFERENCES perfil (id) ON DELETE CASCADE,
        FOREIGN KEY (categoria_id) REFERENCES categoria (id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_transacao_perfil_data ON transacao (perfil_id, data)',
    );

    await _criarTabelaDespesasCompartilhadas(db);

    await _inserirDadosIniciais(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _criarTabelaDespesasCompartilhadas(db);
    }
  }

  Future<void> _criarTabelaDespesasCompartilhadas(Database db) async {
    await db.execute('''
      CREATE TABLE despesa_compartilhada (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        perfil_id       INTEGER NOT NULL,
        descricao       TEXT NOT NULL,
        valor_centavos  INTEGER NOT NULL CHECK (valor_centavos > 0),
        pago_por        TEXT NOT NULL,
        data            TEXT NOT NULL,
        FOREIGN KEY (perfil_id) REFERENCES perfil (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_despesa_compartilhada_perfil_data ON despesa_compartilhada (perfil_id, data)',
    );
  }

  Future<void> _inserirDadosIniciais(Database db) async {
    await db.insert('perfil', {'nome': 'Pessoal', 'tipo': 'pessoal', 'cor': '#2E7D32'});
    await db.insert('perfil', {'nome': 'Profissional', 'tipo': 'profissional', 'cor': '#1565C0'});
    await db.insert('perfil', {'nome': 'Conjunto', 'tipo': 'conjunto', 'cor': '#EF6C00'});

    const despesas = [
      'Alimentação',
      'Moradia',
      'Transporte',
      'Saúde',
      'Lazer',
      'Custos operacionais',
    ];
    const receitas = ['Salário', 'Vendas', 'Outras receitas'];

    for (final nome in despesas) {
      await db.insert('categoria', {'nome': nome, 'tipo': 'despesa'});
    }
    for (final nome in receitas) {
      await db.insert('categoria', {'nome': nome, 'tipo': 'receita'});
    }
  }
}
