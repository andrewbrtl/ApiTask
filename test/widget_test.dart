import 'package:apitask/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CEP incompleto mostra validação antes de consultar a rede', (
    tester,
  ) async {
    await tester.pumpWidget(const ApiTaskApp());
    await tester.enterText(find.byType(TextFormField), '123');
    await tester.tap(find.text('Buscar endereço'));
    await tester.pump();
    expect(find.text('Digite um CEP com 8 dígitos.'), findsOneWidget);
    expect(find.text('Endereço encontrado'), findsNothing);
  });
}
