class Categoria {
  final int id;
  final String nome;
  final String tipo;

  const Categoria({
    required this.id,
    required this.nome,
    required this.tipo,
  });

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as int,
      nome: map['nome'] as String,
      tipo: map['tipo'] as String,
    );
  }
}