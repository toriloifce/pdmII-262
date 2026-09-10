import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// 1 & 2. Função para criar/abrir o banco 'alunos.db' na raiz e criar a tabela 'tb_alunos'
Future<Database> inicializarBanco() async {
  // Inicializa o suporte a SQLite para ambiente Linux / Desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Define o caminho para criar o arquivo alunos.db na raiz do projeto
  String caminhoBanco = join(Directory.current.path, 'alunos.db');

  return await openDatabase(
    caminhoBanco,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE tb_alunos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          idade INTEGER NOT NULL
        )
      ''');
      print('--> Banco "alunos.db" e tabela "tb_alunos" criados com sucesso!');
    },
  );
}

// 3. Função para incluir 3 alunos APENAS se a tabela estiver vazia
Future<void> inserirAlunosSeVazio(Database db) async {
  // Consulta quantos registros existem na tabela tb_alunos
  List<Map<String, dynamic>> registros = await db.query('tb_alunos');

  if (registros.isEmpty) {
    await db.insert('tb_alunos', {'nome': 'Ana Silva', 'idade': 20});
    await db.insert('tb_alunos', {'nome': 'Carlos Souza', 'idade': 22});
    await db.insert('tb_alunos', {'nome': 'Mariana Lima', 'idade': 21});
    print('--> Tabela estava vazia. 3 alunos foram inseridos com sucesso!');
  } else {
    print('--> A tabela já contém dados (${registros.length} registros). Nenhuma inserção foi realizada.');
  }
}

// 4. Função para listar o conteúdo da tabela
Future<void> listarAlunos(Database db) async {
  List<Map<String, dynamic>> alunos = await db.query('tb_alunos');

  if (alunos.isEmpty) {
    print('Nenhum aluno encontrado na tabela.');
    return;
  }

  print('\n--- CONTEÚDO DA TABELA tb_alunos ---');
  for (var aluno in alunos) {
    print('ID: ${aluno['id']} | Nome: ${aluno['nome']} | Idade: ${aluno['idade']}');
  }
  print('-----------------------------------\n');
}

void main() async {
  Database? db;

  // Tratamento de Exceções cobrindo todas as operações
  try {
    print('1. Inicializando conexao com o banco de dados...');
    db = await inicializarBanco();

    print('2. Verificando/Inserindo alunos na tabela...');
    await inserirAlunosSeVazio(db);

    print('3. Listando alunos da tabela...');
    await listarAlunos(db);

  } on DatabaseException catch (e) {
    // Trata exceções do banco de dados SQLite
    print('\n[EXCEÇÃO DE BANCO DE DADOS]: $e');
  } catch (e) {
    // Trata exceções gerais do sistema
    print('\n[EXCEÇÃO GERAL]: $e');
  } finally {
    // Fecha a conexão com o banco ao finalizar
    if (db != null && db.isOpen) {
      await db.close();
      print('Conexão com o banco de dados encerrada com segurança.');
    }
  }
}