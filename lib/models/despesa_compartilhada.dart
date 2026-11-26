class DespesaCompartilhada {
  final int? id;
  final int perfilId;
  final String descricao;
  final int valorCentavos;
  final String pagoPor;
  final DateTime data;

  const DespesaCompartilhada({
    this.id,
    required this.perfilId,
    required this.descricao,
    required this.valorCentavos,
    required this.pagoPor,
    required this.data,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'perfil_id': perfilId,
        'descricao': descricao,
        'valor_centavos': valorCentavos,
        'pago_por': pagoPor,
        'data': '${data.year.toString().padLeft(4, '0')}-'
            '${data.month.toString().padLeft(2, '0')}-'
            '${data.day.toString().padLeft(2, '0')}',
      };

  factory DespesaCompartilhada.fromMap(Map<String, Object?> map) =>
      DespesaCompartilhada(
        id: map['id'] as int,
        perfilId: map['perfil_id'] as int,
        descricao: map['descricao'] as String,
        valorCentavos: map['valor_centavos'] as int,
        pagoPor: map['pago_por'] as String,
        data: DateTime.parse(map['data'] as String),
      );
}
