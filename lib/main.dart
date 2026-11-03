import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'viacep_service.dart';

void main() => runApp(const ApiTaskApp());

class ApiTaskApp extends StatelessWidget {
  const ApiTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Busca CEP',
      debugShowCheckedModeBanner: false,
      home: const CepPage(),
    );
  }
}

class CepPage extends StatefulWidget {
  const CepPage({super.key});

  @override
  State<CepPage> createState() => _CepPageState();
}

class _CepPageState extends State<CepPage> {
  final _formKey = GlobalKey<FormState>();
  final _cepController = TextEditingController();
  final _service = ViaCepService();
  Endereco? _endereco;
  String? _erro;
  bool _carregando = false;

  Future<void> _buscar() async {
    if (_carregando) return;
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _endereco = null;
        _erro = null;
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _endereco = null;
      _erro = null;
    });
    try {
      final endereco = await _service.buscar(_cepController.text);
      if (!mounted) return;
      setState(() => _endereco = endereco);
    } on CepException catch (erro) {
      if (!mounted) return;
      setState(() => _erro = erro.mensagem);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível consultar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  void dispose() {
    _cepController.dispose();
    _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final endereco = _endereco;
    return Scaffold(
      appBar: AppBar(title: const Text('Busca CEP')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _cepController,
              enabled: !_carregando,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.search,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(labelText: 'CEP'),
              validator: (value) => RegExp(r'^\d{8}$').hasMatch(value ?? '')
                  ? null
                  : 'Digite um CEP com 8 dígitos.',
              onChanged: (_) => setState(() {
                _endereco = null;
                _erro = null;
              }),
              onFieldSubmitted: (_) => _buscar(),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: _carregando ? null : _buscar,
              child: Text(_carregando ? 'Consultando...' : 'Buscar endereço'),
            ),
          ),
          const SizedBox(height: 16),
          if (_erro != null) Text(_erro!),
          if (endereco != null) ...[
            const Text('Endereço encontrado'),
            _campo('CEP', endereco.cep),
            _campo('Logradouro', endereco.logradouro),
            _campo('Bairro', endereco.bairro),
            _campo('Cidade', endereco.cidade),
            _campo('UF', endereco.uf),
            _campo('Complemento', endereco.complemento),
            _campo('DDD', endereco.ddd),
          ],
        ],
      ),
    );
  }

  Widget _campo(String titulo, String valor) {
    return Text('$titulo: ${valor.isEmpty ? 'Não informado' : valor}');
  }
}
