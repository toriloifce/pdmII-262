import 'dart:convert';
import 'package:http/http.dart' as http;

class Aluno {
  final int id;
  final String nome;
  final String disciplina;
  final double media;
  final int faltas;

  Aluno({
    required this.id,
    required this.nome,
    required this.disciplina,
    required this.media,
    required this.faltas,
  });

  factory Aluno.fromJson(Map<String, dynamic> json) {
    return Aluno(
      id: json['id'] as int,
      nome: json['nome'] as String,
      disciplina: json['disciplina'] as String,
      media: (json['media'] as num).toDouble(),
      faltas: json['faltas'] as int,
    );
  }

  // Avalia as condições de aprovação imprimindo uma única mensagem
  String obterMensagemStatus() {
    if (faltas > 20) {
      return "Reprovado por Faltas";
    } else if (media < 6.0) {
      return "Reprovado";
    } else {
      return "Aprovado";
    }
  }
}

Future<void> main() async {
  final url = Uri.parse('http://localhost:8080/api/alunos');

  try {
    print('Conectando ao Servidor Web...\n');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody = jsonDecode(response.body);
      final List<dynamic> dadosAlunos = jsonBody['dados'];

      final alunos = dadosAlunos.map((json) => Aluno.fromJson(json)).toList();

      // Formatação e alinhamento das colunas
      print(
        '${'ID'.padRight(4)} ${'NOME'.padRight(16)} ${'DISCIPLINA'.padRight(22)} ${'MEDIA'.padRight(8)} ${'FALTAS'.padRight(8)} MENSAGEM',
      );
      print('-' * 75);

      for (var aluno in alunos) {
        final mensagem = aluno.obterMensagemStatus();
        print(
          '${aluno.id.toString().padRight(4)} '
          '${aluno.nome.padRight(16)} '
          '${aluno.disciplina.padRight(22)} '
          '${aluno.media.toStringAsFixed(1).padRight(8)} '
          '${aluno.faltas.toString().padRight(8)} '
          '$mensagem',
        );
      }
    } else {
      print('Erro na requisição. Código de status: ${response.statusCode}');
    }
  } catch (e) {
    print('Erro de conexão: Certifique-se de que o servidor está rodando antes de executar o cliente!');
    print('Detalhes do erro: $e');
  }
}