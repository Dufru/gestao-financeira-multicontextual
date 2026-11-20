class Perfil {
  final int id;
  final String nome;
  final String tipo;
  final String? cor;

  const Perfil({
    required this.id,
    required this.nome,
    required this.tipo,
    this.cor,
  });

  factory Perfil.fromMap(Map<String, dynamic> map) {
    return Perfil(
      id: map['id'] as int,
      nome: map['nome'] as String,
      tipo: map['tipo'] as String,
      cor: map['cor'] as String?,
    );
  }
}