import 'package:flutter/foundation.dart';

import '../logica/logica.dart' as dominio;
import '../logica/divisao_conjunto.dart' as rateio;
import '../models/categoria.dart';
import '../models/despesa_compartilhada.dart' as persistencia;
import '../models/perfil.dart' as persistido;
import '../models/resumo_financeiro.dart';
import '../models/transacao.dart';
import '../repositories/categoria_repository.dart';
import '../repositories/despesa_compartilhada_repository.dart';
import '../repositories/perfil_repository.dart';
import '../repositories/saldo_repository.dart';
import '../repositories/transacao_repository.dart';

class FinanceViewModel extends ChangeNotifier {
  FinanceViewModel({
    PerfilRepository? perfilRepository,
    CategoriaRepository? categoriaRepository,
    DespesaCompartilhadaRepository? despesaCompartilhadaRepository,
    SaldoRepository? saldoRepository,
    TransacaoRepository? transacaoRepository,
  })  : _perfilRepository = perfilRepository ?? PerfilRepository(),
        _categoriaRepository = categoriaRepository ?? CategoriaRepository(),
        _despesaCompartilhadaRepository =
            despesaCompartilhadaRepository ?? DespesaCompartilhadaRepository(),
        _saldoRepository = saldoRepository ?? SaldoRepository(),
        _transacaoRepository = transacaoRepository ?? TransacaoRepository();

  final dominio.PerfilAtivoController controlePerfilAtivo =
      dominio.PerfilAtivoController();

  final PerfilRepository _perfilRepository;
  final CategoriaRepository _categoriaRepository;
  final DespesaCompartilhadaRepository _despesaCompartilhadaRepository;
  final SaldoRepository _saldoRepository;
  final TransacaoRepository _transacaoRepository;

  @override
  void dispose() {
    controlePerfilAtivo.dispose();
    super.dispose();
  }

  List<persistido.Perfil> perfis = [];
  List<Categoria> categorias = [];
  List<Transacao> transacoes = [];
  List<persistencia.DespesaCompartilhada> despesasCompartilhadas = [];
  persistido.Perfil? perfilSelecionado;
  ResumoFinanceiro resumoMes = const ResumoFinanceiro(
    receitasCentavos: 0,
    despesasCentavos: 0,
  );
  ResumoFinanceiro resumoConsolidado = const ResumoFinanceiro(
    receitasCentavos: 0,
    despesasCentavos: 0,
  );
  bool carregando = true;
  String? erro;

  DateTime get inicioMes {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month);
  }

  DateTime get inicioProximoMes =>
      DateTime(inicioMes.year, inicioMes.month + 1);

  int get saldoMes => resumoMes.saldoCentavos;

  static const participantesConjunto = ['Você', 'Outra pessoa'];

  rateio.ResultadoAcerto get resultadoAcerto => rateio.calcularAcerto(
        despesasCompartilhadas.map((despesa) => rateio.DespesaCompartilhada(
          id: '${despesa.id}',
          pagoPor: despesa.pagoPor,
          valor: despesa.valorCentavos,
          data: despesa.data,
          descricao: despesa.descricao,
        )),
        rateio.DivisaoConjunto.igualitaria(participantesConjunto),
      );

  dominio.Perfil get perfilDeDominio => controlePerfilAtivo.ativo;

  Future<void> carregar() async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      perfis = await _perfilRepository.listar();
      categorias = await _categoriaRepository.listar();
      if (perfis.isEmpty) {
        throw StateError('Os perfis iniciais não foram encontrados no banco.');
      }
      perfilSelecionado ??= perfis.firstWhere(
        (perfil) => perfil.tipo == 'pessoal',
        orElse: () => perfis.first,
      );
      controlePerfilAtivo.selecionar(_converterPerfil(perfilSelecionado!));
      final perfilConjunto = _perfilConjunto;
      if (perfilConjunto != null) {
        despesasCompartilhadas =
            await _despesaCompartilhadaRepository.listar(perfilConjunto.id);
      }
      await _carregarDadosDoPerfil();
    } catch (exception) {
      erro = exception.toString();
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> selecionarPerfil(persistido.Perfil perfil) async {
    if (perfil.id == perfilSelecionado?.id) return;
    perfilSelecionado = perfil;
    controlePerfilAtivo.selecionar(_converterPerfil(perfil));
    carregando = true;
    notifyListeners();
    try {
      await _carregarDadosDoPerfil();
      erro = null;
    } catch (exception) {
      erro = exception.toString();
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> salvarTransacao(Transacao transacao) async {
    final perfil = perfilSelecionado;
    if (perfil == null) throw StateError('Selecione um contexto financeiro.');
    final registro = Transacao(
      id: transacao.id,
      perfilId: perfil.id,
      categoriaId: transacao.categoriaId,
      descricao: transacao.descricao.trim(),
      valorCentavos: transacao.valorCentavos,
      tipo: transacao.tipo,
      data: transacao.data,
    );
    if (registro.id == null) {
      await _transacaoRepository.inserir(registro);
    } else {
      await _transacaoRepository.atualizar(registro);
    }
    await _carregarDadosDoPerfil();
    notifyListeners();
  }

  Future<void> excluirTransacao(int id) async {
    await _transacaoRepository.excluir(id);
    await _carregarDadosDoPerfil();
    notifyListeners();
  }

  Future<void> salvarDespesaCompartilhada({
    required String descricao,
    required int valorCentavos,
    required String pagoPor,
    required DateTime data,
  }) async {
    final perfil = _perfilConjunto;
    if (perfil == null) throw StateError('O contexto Conjunto não foi encontrado.');
    if (!participantesConjunto.contains(pagoPor)) {
      throw ArgumentError('Selecione quem pagou a despesa.');
    }
    await _despesaCompartilhadaRepository.inserir(
      persistencia.DespesaCompartilhada(
        perfilId: perfil.id,
        descricao: descricao.trim(),
        valorCentavos: valorCentavos,
        pagoPor: pagoPor,
        data: data,
      ),
    );
    despesasCompartilhadas =
        await _despesaCompartilhadaRepository.listar(perfil.id);
    notifyListeners();
  }

  Future<void> excluirDespesaCompartilhada(int id) async {
    await _despesaCompartilhadaRepository.excluir(id);
    final perfil = _perfilConjunto;
    if (perfil != null) {
      despesasCompartilhadas =
          await _despesaCompartilhadaRepository.listar(perfil.id);
    }
    notifyListeners();
  }

  persistido.Perfil? get _perfilConjunto {
    for (final perfil in perfis) {
      if (perfil.tipo == 'conjunto') return perfil;
    }
    return null;
  }

  dominio.Perfil _converterPerfil(persistido.Perfil perfil) => switch (perfil.tipo) {
        'profissional' => dominio.Perfil.profissional,
        'conjunto' => dominio.Perfil.conjunto,
        _ => dominio.Perfil.pessoal,
      };

  Future<void> _carregarDadosDoPerfil() async {
    final perfilId = perfilSelecionado?.id;
    if (perfilId == null) return;
    final resultados = await Future.wait([
      _transacaoRepository.listarPorPerfil(perfilId),
      _saldoRepository.resumoDoPerfil(
        perfilId,
        inicio: inicioMes,
        fim: inicioProximoMes,
      ),
      _saldoRepository.resumoConsolidado(
        inicio: inicioMes,
        fim: inicioProximoMes,
      ),
    ]);
    if (perfilSelecionado?.id != perfilId) return;
    transacoes = resultados[0] as List<Transacao>;
    resumoMes = resultados[1] as ResumoFinanceiro;
    resumoConsolidado = resultados[2] as ResumoFinanceiro;
  }
}
