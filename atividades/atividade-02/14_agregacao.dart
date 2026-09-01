// 14-agregacao.dart  
// Agregação e Composição
import 'dart:convert'; // serve pra converter para json

class Dependente {
  late String _nome;

  Dependente(String nome) {
    this._nome = nome;
  }
  // Método para converter o objeto em um Map (necessário para o JSON)
  Map<String, dynamic> toMap() {
    return {
      'nome': _nome,
    };
  }
}

class Funcionario {
  late String _nome;
  late List<Dependente> _dependentes;

  Funcionario(String nome, List<Dependente> dependentes) {
    this._nome = nome;
    this._dependentes = dependentes;
  }
  Map<String, dynamic> toMap() {
    return {
      'nome': _nome,
      'dependentes': _dependentes.map((d) => d.toMap()).toList(),
    };
  }
}

class EquipeProjeto {
  late String _nomeProjeto;
  late List<Funcionario> _funcionarios;

  EquipeProjeto(String nomeprojeto, List<Funcionario> funcionarios) {
    _nomeProjeto = nomeprojeto;
    _funcionarios = funcionarios;
  }
  Map<String, dynamic> toMap() {
    return {
      'nomeProjeto': _nomeProjeto,
      'funcionarios': _funcionarios.map((f) => f.toMap()).toList(),
    };
  }
}

void main() {
  // 1. Criar varios objetos Dependentes
  var dep1 = Dependente("Henk");
  var dep2 = Dependente("Ângelo");
  var dep3 = Dependente("Pedro");

  // 2. Criar varios objetos Funcionario
  // 3. Associar os Dependentes criados aos respectivos funcionarios
  var func1 = Funcionario("Caio", [dep1, dep2]);
  var func2 = Funcionario("Daniel", [dep3]);
  var func3 = Funcionario("Rocha", []);

  // 4. Criar uma lista de Funcionarios
  List<Funcionario> listaFuncionarios = [func1, func2, func3];  

  // 5. criar um objeto Equipe Projeto chamando o metodo construtor que da nome ao projeto e insere uma coleção de funcionario
  var equipe = EquipeProjeto("Sistema de Vendas", listaFuncionarios);

  // 6. Printar no formato JSON o objeto Equipe Projeto.
  String jsonEquipe = JsonEncoder.withIndent('  ').convert(equipe.toMap());
  print(jsonEquipe);
}
