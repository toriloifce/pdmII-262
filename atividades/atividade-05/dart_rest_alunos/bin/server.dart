import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// Modelo Aluno conforme os requisitos da Atividade 5: (id, nome, disciplina, media, faltas)
class Aluno {
  final int id;
  final String nome;
  final String disciplina;
  final double media;
  final int faltas;

  const Aluno({
    required this.id,
    required this.nome,
    required this.disciplina,
    required this.media,
    required this.faltas,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'disciplina': disciplina,
        'media': media,
        'faltas': faltas,
      };

  static Aluno fromJson(Map<String, dynamic> json) => Aluno(
        id: json['id'] as int,
        nome: json['nome'] as String,
        disciplina: json['disciplina'] as String,
        media: (json['media'] as num).toDouble(),
        faltas: json['faltas'] as int,
      );
}

// Lista de teste com alunos testando todas as condições de aprovação/reprovação
final List<Aluno> alunos = [
  const Aluno(
    id: 1,
    nome: 'Ana Souza',
    disciplina: 'Programação Móvel',
    media: 8.5,
    faltas: 10, // Aprovado
  ),
  const Aluno(
    id: 2,
    nome: 'Bruno Lima',
    disciplina: 'Banco de Dados',
    media: 5.0,
    faltas: 12, // Reprovado
  ),
  const Aluno(
    id: 3,
    nome: 'Carla Mendes',
    disciplina: 'Programação Móvel',
    media: 9.0,
    faltas: 25, // Reprovado por Faltas
  ),
  const Aluno(
    id: 4,
    nome: 'Diego Alves',
    disciplina: 'Sistemas Operacionais',
    media: 4.5,
    faltas: 22, // Reprovado por Faltas (Faltas > 20 se sobrepõe à Média < 6)
  ),
];

Response jsonResponse(Object body, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

Response _listarAlunos(Request request) {
  return jsonResponse({
    'total': alunos.length,
    'dados': alunos.map((aluno) => aluno.toJson()).toList(),
  });
}

Router createRouter() {
  final router = Router()..get('/api/alunos', _listarAlunos);
  return router;
}

Future<void> main() async {
  final port = 8080;
  final address = InternetAddress.anyIPv4;

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(createRouter().call);

  final server = await shelf_io.serve(handler, address, port);
  print('Servidor iniciado em http://localhost:${server.port}');
}