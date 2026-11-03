import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class Endereco {
  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
  final String ddd;

  Endereco.fromJson(Map<String, dynamic> json)
    : cep = json['cep'] as String? ?? '',
      logradouro = json['logradouro'] as String? ?? '',
      complemento = json['complemento'] as String? ?? '',
      bairro = json['bairro'] as String? ?? '',
      cidade = json['localidade'] as String? ?? '',
      uf = json['uf'] as String? ?? '',
      ddd = json['ddd'] as String? ?? '';
}

class CepException implements Exception {
  final String mensagem;
  const CepException(this.mensagem);
}

class ViaCepService {
  final http.Client _client;
  final Duration timeout;

  ViaCepService({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  Future<Endereco> buscar(String cep) async {
    if (!RegExp(r'^\d{8}$').hasMatch(cep)) {
      throw const CepException('Digite um CEP com 8 dígitos.');
    }
    final url = Uri.https('viacep.com.br', '/ws/$cep/json/');
    try {
      final resposta = await _client.get(url).timeout(timeout);
      if (resposta.statusCode != 200) {
        throw const CepException('Serviço indisponível. Tente novamente.');
      }
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (dados is! Map<String, dynamic>) {
        throw const FormatException('JSON inesperado');
      }
      if (dados['erro'] == true || dados['erro'] == 'true') {
        throw const CepException('CEP não encontrado. Confira os números.');
      }
      if (dados['cep'] is! String ||
          dados['localidade'] is! String ||
          dados['uf'] is! String) {
        throw const FormatException('Endereço incompleto');
      }
      return Endereco.fromJson(dados);
    } on TimeoutException {
      throw const CepException('A consulta demorou demais. Tente novamente.');
    } on http.ClientException {
      throw const CepException('Falha de conexão. Verifique sua internet.');
    } on FormatException {
      throw const CepException(
        'Resposta inválida do serviço. Tente novamente.',
      );
    } on TypeError {
      throw const CepException(
        'Resposta inválida do serviço. Tente novamente.',
      );
    }
  }

  void close() => _client.close();
}
