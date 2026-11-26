import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:financas_app/database/app_database.dart';
import 'package:financas_app/models/despesa_compartilhada.dart';
import 'package:financas_app/models/transacao.dart';
import 'package:financas_app/repositories/categoria_repository.dart';
import 'package:financas_app/repositories/despesa_compartilhada_repository.dart';
import 'package:financas_app/repositories/perfil_repository.dart';
import 'package:financas_app/repositories/saldo_repository.dart';
import 'package:financas_app/repositories/transacao_repository.dart';

void main() {
  late Database db;
  final repo = TransacaoRepository();
  final saldoRepo = SaldoRepository();
  final perfilRepo = PerfilRepository();
  final categoriaRepo = CategoriaRepository();
  final despesaCompartilhadaRepo = DespesaCompartilhadaRepository();

  Future<int> novoPerfil(String nome) {
    return db.insert('perfil', {'nome': nome, 'tipo': 'pessoal'});
  }

  Future<void> lancar(int perfilId, String tipo, int valor) {
    return repo.inserir(Transacao(
      perfilId: perfilId,
      categoriaId: tipo == 'receita' ? 7 : 1,
      descricao: 'Lancamento de teste',
      valorCentavos: valor,
      tipo: tipo,
      data: DateTime(2026, 11, 8),
    ));
  }

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final caminho = join(await getDatabasesPath(), 'financas.db');
    await deleteDatabase(caminho);

    db = await AppDatabase.instance.database;
  });

  group('Estrutura do banco', () {
    test('cria os 3 perfis iniciais', () async {
      final perfis = await db.query('perfil');
      expect(perfis.length, 3);
      expect(perfis.map((p) => p['tipo']),
          containsAll(['pessoal', 'profissional', 'conjunto']));
    });

    test('cria as 9 categorias iniciais', () async {
      final categorias = await db.query('categoria');
      expect(categorias.length, 9);
    });

    test('cria a tabela de despesas compartilhadas', () async {
      final tabelas = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      expect(tabelas.map((linha) => linha['name']),
          contains('despesa_compartilhada'));
    });

    test('despesa compartilhada aceita apenas valores positivos', () async {
      await db.insert('despesa_compartilhada', {
        'perfil_id': 3,
        'descricao': 'Conta de luz',
        'valor_centavos': 15990,
        'pago_por': 'Você',
        'data': '2026-11-25',
      });
      expect(
        () => db.insert('despesa_compartilhada', {
          'perfil_id': 3,
          'descricao': 'Valor inválido',
          'valor_centavos': 0,
          'pago_por': 'Você',
          'data': '2026-11-25',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('aceita uma transacao valida', () async {
      final id = await db.insert('transacao', {
        'perfil_id': 1,
        'categoria_id': 1,
        'descricao': 'Mercado',
        'valor_centavos': 2590,
        'tipo': 'despesa',
        'data': '2026-11-07',
      });
      expect(id, greaterThan(0));
    });

    test('rejeita transacao com perfil inexistente (chave estrangeira)',
        () async {
      expect(
        () => db.insert('transacao', {
          'perfil_id': 999,
          'categoria_id': 1,
          'descricao': 'Teste',
          'valor_centavos': 1000,
          'tipo': 'despesa',
          'data': '2026-11-07',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rejeita valor negativo (CHECK)', () async {
      expect(
        () => db.insert('transacao', {
          'perfil_id': 1,
          'categoria_id': 1,
          'descricao': 'Teste',
          'valor_centavos': -500,
          'tipo': 'despesa',
          'data': '2026-11-07',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rejeita tipo invalido (CHECK)', () async {
      expect(
        () => db.insert('transacao', {
          'perfil_id': 1,
          'categoria_id': 1,
          'descricao': 'Teste',
          'valor_centavos': 500,
          'tipo': 'emprestimo',
          'data': '2026-11-07',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('Perfis e categorias', () {
    test('lista os 3 perfis iniciais com nome, tipo e cor', () async {
      final perfis = await perfilRepo.listar();

      expect(perfis[0].nome, 'Pessoal');
      expect(perfis[0].tipo, 'pessoal');
      expect(perfis[0].cor, '#2E7D32');
      expect(perfis[1].nome, 'Profissional');
      expect(perfis[2].nome, 'Conjunto');
    });

    test('lista as 6 categorias de despesa', () async {
      final despesas = await categoriaRepo.listar(tipo: 'despesa');

      expect(despesas.length, 6);
      expect(despesas.every((c) => c.tipo == 'despesa'), isTrue);
      expect(despesas.map((c) => c.nome),
          containsAll(['Alimentação', 'Moradia', 'Custos operacionais']));
    });

    test('lista as 3 categorias de receita', () async {
      final receitas = await categoriaRepo.listar(tipo: 'receita');

      expect(receitas.length, 3);
      expect(receitas.every((c) => c.tipo == 'receita'), isTrue);
      expect(receitas.map((c) => c.nome), containsAll(['Salário', 'Vendas']));
    });

    test('sem filtro, lista as 9 categorias', () async {
      final todas = await categoriaRepo.listar();

      expect(todas.length, 9);
    });

    test('usa os ids buscados no banco para gravar uma transacao', () async {
      final perfis = await perfilRepo.listar();
      final profissional = perfis.firstWhere((p) => p.tipo == 'profissional');
      final receitas = await categoriaRepo.listar(tipo: 'receita');
      final salario = receitas.firstWhere((c) => c.nome == 'Salário');

      final id = await repo.inserir(Transacao(
        perfilId: profissional.id,
        categoriaId: salario.id,
        descricao: 'Pagamento recebido',
        valorCentavos: 120000,
        tipo: 'receita',
        data: DateTime(2026, 11, 9),
      ));

      final lista = await repo.listarPorPerfil(profissional.id);
      expect(
        lista.any((t) => t.id == id && t.categoriaId == salario.id),
        isTrue,
      );
    });
  });

  group('Repositorio de transacoes', () {
    test('insere e lista uma transacao no perfil correto', () async {
      final id = await repo.inserir(Transacao(
        perfilId: 2,
        categoriaId: 7,
        descricao: 'Venda de servico',
        valorCentavos: 35000,
        tipo: 'receita',
        data: DateTime(2026, 11, 7),
      ));

      final lista = await repo.listarPorPerfil(2);
      final encontrada = lista.firstWhere((t) => t.id == id);

      expect(encontrada.descricao, 'Venda de servico');
      expect(encontrada.valorCentavos, 35000);
      expect(encontrada.tipo, 'receita');
      expect(encontrada.data, DateTime(2026, 11, 7));
    });

    test('isola as transacoes por perfil', () async {
      await repo.inserir(Transacao(
        perfilId: 2,
        categoriaId: 6,
        descricao: 'Custo do negocio',
        valorCentavos: 8000,
        tipo: 'despesa',
        data: DateTime(2026, 11, 8),
      ));

      final doConjunto = await repo.listarPorPerfil(3);
      final doProfissional = await repo.listarPorPerfil(2);

      expect(doConjunto, isEmpty);
      expect(
        doProfissional.any((t) => t.descricao == 'Custo do negocio'),
        isTrue,
      );
    });

    test('atualiza uma transacao', () async {
      final id = await repo.inserir(Transacao(
        perfilId: 1,
        categoriaId: 2,
        descricao: 'Aluguel',
        valorCentavos: 100000,
        tipo: 'despesa',
        data: DateTime(2026, 11, 5),
      ));

      await repo.atualizar(Transacao(
        id: id,
        perfilId: 1,
        categoriaId: 2,
        descricao: 'Aluguel corrigido',
        valorCentavos: 150000,
        tipo: 'despesa',
        data: DateTime(2026, 11, 5),
      ));

      final lista = await repo.listarPorPerfil(1);
      final atualizada = lista.firstWhere((t) => t.id == id);

      expect(atualizada.descricao, 'Aluguel corrigido');
      expect(atualizada.valorCentavos, 150000);
    });

    test('exclui uma transacao', () async {
      final id = await repo.inserir(Transacao(
        perfilId: 1,
        categoriaId: 5,
        descricao: 'Cinema',
        valorCentavos: 4000,
        tipo: 'despesa',
        data: DateTime(2026, 11, 6),
      ));

      await repo.excluir(id);

      final lista = await repo.listarPorPerfil(1);
      expect(lista.where((t) => t.id == id), isEmpty);
    });
  });

  group('Saldo por perfil', () {
    test('perfil sem transacoes tem tudo zerado', () async {
      final perfil = await novoPerfil('Vazio');

      final resumo = await saldoRepo.resumoDoPerfil(perfil);

      expect(resumo.receitasCentavos, 0);
      expect(resumo.despesasCentavos, 0);
      expect(resumo.saldoCentavos, 0);
    });

    test('soma receitas e despesas e calcula o saldo', () async {
      final perfil = await novoPerfil('Com movimento');
      await lancar(perfil, 'receita', 500000);
      await lancar(perfil, 'despesa', 120000);
      await lancar(perfil, 'despesa', 30050);

      final resumo = await saldoRepo.resumoDoPerfil(perfil);

      expect(resumo.receitasCentavos, 500000);
      expect(resumo.despesasCentavos, 150050);
      expect(resumo.saldoCentavos, 349950);
    });

    test('saldo pode ficar negativo', () async {
      final perfil = await novoPerfil('Negativo');
      await lancar(perfil, 'despesa', 10000);

      final resumo = await saldoRepo.resumoDoPerfil(perfil);

      expect(resumo.saldoCentavos, -10000);
    });

    test('nao mistura o saldo de perfis diferentes', () async {
      final perfilA = await novoPerfil('Perfil A');
      final perfilB = await novoPerfil('Perfil B');
      await lancar(perfilA, 'receita', 100000);
      await lancar(perfilB, 'receita', 20000);

      final resumoA = await saldoRepo.resumoDoPerfil(perfilA);
      final resumoB = await saldoRepo.resumoDoPerfil(perfilB);

      expect(resumoA.saldoCentavos, 100000);
      expect(resumoB.saldoCentavos, 20000);
    });
  });

  group('Saldo consolidado', () {
    test('soma as transacoes dos tres perfis', () async {
      final antes = await saldoRepo.resumoConsolidado();

      await lancar(1, 'receita', 200000);
      await lancar(2, 'receita', 80000);
      await lancar(3, 'despesa', 50000);

      final depois = await saldoRepo.resumoConsolidado();

      expect(depois.receitasCentavos - antes.receitasCentavos, 280000);
      expect(depois.despesasCentavos - antes.despesasCentavos, 50000);
      expect(depois.saldoCentavos - antes.saldoCentavos, 230000);
    });

    test('bate com a soma dos saldos de todos os perfis', () async {
      final perfis = await db.query('perfil');

      var somaDosSaldos = 0;
      for (final perfil in perfis) {
        final resumo = await saldoRepo.resumoDoPerfil(perfil['id'] as int);
        somaDosSaldos += resumo.saldoCentavos;
      }

      final consolidado = await saldoRepo.resumoConsolidado();

      expect(consolidado.saldoCentavos, somaDosSaldos);
    });
  });

  group('Repositorio de despesas compartilhadas', () {
    test('insere, lista e exclui uma despesa compartilhada', () async {
      final id = await despesaCompartilhadaRepo.inserir(
        DespesaCompartilhada(
          perfilId: 3,
          descricao: 'Internet residencial',
          valorCentavos: 12000,
          pagoPor: 'Você',
          data: DateTime(2026, 11, 10),
        ),
      );

      final lista = await despesaCompartilhadaRepo.listar(3);
      final encontrada = lista.firstWhere((d) => d.id == id);

      expect(encontrada.descricao, 'Internet residencial');
      expect(encontrada.valorCentavos, 12000);
      expect(encontrada.pagoPor, 'Você');

      await despesaCompartilhadaRepo.excluir(id);

      final aposExclusao = await despesaCompartilhadaRepo.listar(3);
      expect(aposExclusao.where((d) => d.id == id), isEmpty);
    });
  });
}
