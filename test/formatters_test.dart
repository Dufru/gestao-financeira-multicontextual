import 'package:flutter_test/flutter_test.dart';
import 'package:financas_app/utils/formatters.dart';

void main() {
  test('formata centavos em moeda brasileira', () {
    expect(formatarMoeda(1050), 'R\$ 10,50');
    expect(formatarMoeda(123456789), 'R\$ 1.234.567,89');
    expect(formatarMoeda(-5), 'R\$ -0,05');
  });

  test('interpreta valores brasileiros e decimais digitados', () {
    expect(lerValorEmCentavos('10,50'), 1050);
    expect(lerValorEmCentavos('1.234,56'), 123456);
    expect(lerValorEmCentavos('12.50'), 1250);
    expect(lerValorEmCentavos(',5'), 50);
    expect(lerValorEmCentavos('inválido'), isNull);
  });
}
