/// Os três contextos financeiros do app.
enum Perfil {
  pessoal,
  profissional,
  conjunto;

  String get rotulo => switch (this) {
        Perfil.pessoal => 'Pessoal',
        Perfil.profissional => 'Profissional',
        Perfil.conjunto => 'Conjunto',
      };
}
