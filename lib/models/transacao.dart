class Transacao {
  final int? id;
  final int perfilId;
  final int categoriaId;
  final String descricao;
  final int valorCentavos;
  final String tipo;
  final DateTime data;

  Transacao({
    this.id,
    required this.perfilId,
    required this.categoriaId,
    required this.descricao,
    required this.valorCentavos,
    required this.tipo,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'perfil_id': perfilId,
      'categoria_id': categoriaId,
      'descricao': descricao,
      'valor_centavos': valorCentavos,
      'tipo': tipo,
      'data': data.toIso8601String().substring(0, 10),
    };
  }

  factory Transacao.fromMap(Map<String, dynamic> map) {
    return Transacao(
      id: map['id'] as int,
      perfilId: map['perfil_id'] as int,
      categoriaId: map['categoria_id'] as int,
      descricao: map['descricao'] as String,
      valorCentavos: map['valor_centavos'] as int,
      tipo: map['tipo'] as String,
      data: DateTime.parse(map['data'] as String),
    );
  }
}