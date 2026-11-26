String formatarMoeda(int centavos) {
  final negativo = centavos < 0;
  final valor = centavos.abs();
  final reais = (valor ~/ 100).toString();
  final buffer = StringBuffer();
  for (var i = 0; i < reais.length; i++) {
    if (i > 0 && (reais.length - i) % 3 == 0) buffer.write('.');
    buffer.write(reais[i]);
  }
  final parteDecimal = (valor % 100).toString().padLeft(2, '0');
  return 'R\$ ${negativo ? '-' : ''}${buffer.toString()},$parteDecimal';
}

String formatarData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/'
    '${data.year}';

String nomeMes(DateTime data) {
  const meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  return '${meses[data.month - 1]} ${data.year}';
}

int? lerValorEmCentavos(String entrada) {
  var texto = entrada.trim().replaceAll(RegExp(r'[^0-9,.-]'), '');
  if (texto.isEmpty) return null;
  final negativo = texto.startsWith('-');
  texto = texto.replaceAll('-', '');
  final temVirgula = texto.contains(',');
  final temPonto = texto.contains('.');
  String inteiro;
  String decimal;
  if (temVirgula) {
    final partes = texto.split(',');
    if (partes.length != 2) return null;
    inteiro = partes[0].replaceAll('.', '');
    decimal = partes[1];
  } else if (temPonto && texto.split('.').last.length <= 2) {
    final partes = texto.split('.');
    if (partes.length != 2) return null;
    inteiro = partes[0];
    decimal = partes[1];
  } else {
    inteiro = texto.replaceAll('.', '');
    decimal = '';
  }
  if (inteiro.isEmpty) inteiro = '0';
  if (decimal.length > 2 || int.tryParse(inteiro) == null) return null;
  final centavos = int.tryParse(decimal.padRight(2, '0')) ?? 0;
  final valor = (int.parse(inteiro) * 100 + centavos) * (negativo ? -1 : 1);
  return valor;
}
