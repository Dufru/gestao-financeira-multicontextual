class ResumoFinanceiro {
  final int receitasCentavos;
  final int despesasCentavos;

  const ResumoFinanceiro({
    required this.receitasCentavos,
    required this.despesasCentavos,
  });

  int get saldoCentavos => receitasCentavos - despesasCentavos;
}