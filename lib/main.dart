import 'package:flutter/material.dart';

void main() => runApp(const ApiTaskApp());

class ApiTaskApp extends StatelessWidget {
  const ApiTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Busca CEP',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Busca CEP')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'CEP'),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: null,
                child: const Text('Buscar endereço'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
