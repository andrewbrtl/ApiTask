import 'package:apitask/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra a tela inicial de busca', (tester) async {
    await tester.pumpWidget(const ApiTaskApp());
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Buscar endereço'), findsOneWidget);
  });
}
