import 'dart:async';
import 'dart:convert';

import 'package:apitask/viacep_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('consulta GET e converte endereço JSON preservando acentos', () async {
    final service = ViaCepService(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://viacep.com.br/ws/01001000/json/',
        );
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'cep': '01001-000',
              'logradouro': 'Praça da Sé',
              'bairro': 'Sé',
              'localidade': 'São Paulo',
              'uf': 'SP',
            }),
          ),
          200,
        );
      }),
    );
    addTearDown(service.close);
    final endereco = await service.buscar('01001000');
    expect(endereco.logradouro, 'Praça da Sé');
    expect(endereco.cidade, 'São Paulo');
    expect(endereco.complemento, '');
  });

  test('rejeita CEP inválido sem acessar a rede', () async {
    final service = ViaCepService(
      client: MockClient((_) async {
        fail('Não deve fazer requisição');
      }),
    );
    addTearDown(service.close);
    await expectLater(service.buscar('123'), throwsA(isA<CepException>()));
  });

  for (final erro in [true, 'true']) {
    test('trata CEP inexistente com erro $erro', () async {
      final service = ViaCepService(
        client: MockClient(
          (_) async => http.Response(jsonEncode({'erro': erro}), 200),
        ),
      );
      addTearDown(service.close);
      await expectLater(
        service.buscar('99999999'),
        throwsA(
          isA<CepException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('não encontrado'),
          ),
        ),
      );
    });
  }

  test('trata falha HTTP', () async {
    final service = ViaCepService(
      client: MockClient((_) async => http.Response('Indisponível', 503)),
    );
    addTearDown(service.close);
    await expectLater(
      service.buscar('01001000'),
      throwsA(
        isA<CepException>().having(
          (e) => e.mensagem,
          'mensagem',
          contains('indisponível'),
        ),
      ),
    );
  });

  for (final body in ['<html>Erro</html>', '[]', '{}']) {
    test('trata resposta inválida: $body', () async {
      final service = ViaCepService(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      addTearDown(service.close);
      await expectLater(
        service.buscar('01001000'),
        throwsA(
          isA<CepException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('Resposta inválida'),
          ),
        ),
      );
    });
  }

  test('trata conexão indisponível', () async {
    final service = ViaCepService(
      client: MockClient((_) async {
        throw http.ClientException('Sem rede');
      }),
    );
    addTearDown(service.close);
    await expectLater(
      service.buscar('01001000'),
      throwsA(
        isA<CepException>().having(
          (e) => e.mensagem,
          'mensagem',
          contains('conexão'),
        ),
      ),
    );
  });

  test('encerra espera quando excede o tempo limite', () async {
    final service = ViaCepService(
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    addTearDown(service.close);
    await expectLater(
      service.buscar('01001000'),
      throwsA(
        isA<CepException>().having(
          (e) => e.mensagem,
          'mensagem',
          contains('demorou'),
        ),
      ),
    );
  });
}
