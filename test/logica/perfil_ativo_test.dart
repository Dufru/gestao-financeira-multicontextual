// Ajuste o import abaixo para o nome do pacote no seu pubspec.yaml.
import 'package:flutter_test/flutter_test.dart';
import 'package:financas_app/logica/logica.dart';

void main() {
  const contas = [
    Conta(id: 'p', nome: 'Pessoal', perfil: Perfil.pessoal),
    Conta(id: 'pr', nome: 'PJ', perfil: Perfil.profissional),
    Conta(id: 'c', nome: 'Casa', perfil: Perfil.conjunto),
  ];
  final txs = [
    Transacao(
        id: '1',
        contaId: 'p',
        tipo: TipoTransacao.despesa,
        valor: 100,
        data: DateTime(2026, 1, 1)),
    Transacao(
        id: '2',
        contaId: 'pr',
        tipo: TipoTransacao.transferencia,
        valor: 500,
        data: DateTime(2026, 1, 2),
        contaDestinoId: 'p'),
    Transacao(
        id: '3',
        contaId: 'c',
        tipo: TipoTransacao.receita,
        valor: 900,
        data: DateTime(2026, 1, 3)),
  ];

  test('começa em Pessoal por padrão', () {
    expect(PerfilAtivoController().ativo, Perfil.pessoal);
  });

  test('selecionar troca o perfil e notifica uma vez', () {
    final c = PerfilAtivoController();
    var chamadas = 0;
    c.addListener(() => chamadas++);

    c.selecionar(Perfil.conjunto);
    expect(c.ativo, Perfil.conjunto);
    expect(chamadas, 1);
  });

  test('selecionar o mesmo perfil não notifica', () {
    final c = PerfilAtivoController(inicial: Perfil.profissional);
    var chamadas = 0;
    c.addListener(() => chamadas++);
    c.selecionar(Perfil.profissional);
    expect(chamadas, 0);
  });

  test('contasVisiveis mostra só as do perfil ativo', () {
    final c = PerfilAtivoController(inicial: Perfil.profissional);
    expect(c.contasVisiveis(contas).map((x) => x.id), ['pr']);
    c.selecionar(Perfil.conjunto);
    expect(c.contasVisiveis(contas).map((x) => x.id), ['c']);
  });

  test('transacoesVisiveis inclui transferência pela origem e pelo destino', () {
    final c = PerfilAtivoController(inicial: Perfil.pessoal);
    expect(c.transacoesVisiveis(contas, txs).map((t) => t.id), ['1', '2']);

    c.selecionar(Perfil.profissional);
    expect(c.transacoesVisiveis(contas, txs).map((t) => t.id), ['2']);

    c.selecionar(Perfil.conjunto);
    expect(c.transacoesVisiveis(contas, txs).map((t) => t.id), ['3']);
  });
}
