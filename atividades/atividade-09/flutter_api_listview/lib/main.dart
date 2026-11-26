import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consumo de API & ListView',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ListaUsuariosScreen(),
    );
  }
}

// ============================================================================
// 1. MODELO DE DADOS (Conversão de JSON para Objeto Dart)
// ============================================================================
class Usuario {
  final int id;
  final String nome;
  final String username;
  final String email;
  final String telefone;
  final String empresa;
  final String cidade;

  const Usuario({
    required this.id,
    required this.nome,
    required this.username,
    required this.email,
    required this.telefone,
    required this.empresa,
    required this.cidade,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nome: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      telefone: json['phone'] as String,
      empresa: (json['company']?['name'] as String?) ?? 'Não informada',
      cidade: (json['address']?['city'] as String?) ?? 'Não informada',
    );
  }
}

// ============================================================================
// 2. CAMADA DE SERVIÇO (Requisição HTTP GET + Tratamento de Erros)
// ============================================================================
class UsuarioService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com/users';

  Future<List<Usuario>> buscarUsuarios() async {
    try {
      final response = await http
          .get(
            Uri.parse(_baseUrl),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10)); // Evita travamento infinito

      if (response.statusCode == 200) {
        final List<dynamic> dadosJson = jsonDecode(response.body);
        return dadosJson.map((json) => Usuario.fromJson(json)).toList();
      } else {
        throw Exception(
          'Falha no servidor (Código HTTP: ${response.statusCode}).',
        );
      }
    } on SocketException {
      throw Exception('Sem conexão com a internet. Verifique sua rede.');
    } on TimeoutException {
      throw Exception('Tempo limite excedido. O servidor demorou a responder.');
    } on FormatException {
      throw Exception('Erro ao processar os dados recebidos (JSON inválido).');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }
}

// ============================================================================
// 3. TELA PRINCIPAL (Gerenciamento de Estado, ListView.builder e Pull-to-Refresh)
// ============================================================================
class ListaUsuariosScreen extends StatefulWidget {
  const ListaUsuariosScreen({super.key});

  @override
  State<ListaUsuariosScreen> createState() => _ListaUsuariosScreenState();
}

class _ListaUsuariosScreenState extends State<ListaUsuariosScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  late Future<List<Usuario>> _futureUsuarios;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // Atualiza o estado da tela disparando uma nova requisição
  void _carregarDados() {
    setState(() {
      _futureUsuarios = _usuarioService.buscarUsuarios();
    });
  }

  // Função acionada pelo gesto de puxar para baixo (Pull-to-Refresh)
  Future<void> _recarregarLista() async {
    _carregarDados();
    await _futureUsuarios;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diretório de Usuários'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar dados',
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _recarregarLista,
        child: FutureBuilder<List<Usuario>>(
          future: _futureUsuarios,
          builder: (context, snapshot) {
            // ESTADO 1: Aguardando resposta da API (Indicador de Progresso)
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Carregando usuários da API...'),
                  ],
                ),
              );
            }

            // ESTADO 2: Erro na requisição (Mensagem amigável + Botão Tentar Novamente)
            if (snapshot.hasError) {
              final mensagemErro = snapshot.error
                  .toString()
                  .replaceFirst('Exception: ', '');

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 64,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ops! Não foi possível carregar os dados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mensagemErro,
                        style: TextStyle(color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _carregarDados,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ESTADO 3: Lista vazia
            final usuarios = snapshot.data ?? [];
            if (usuarios.isEmpty) {
              return const Center(
                child: Text('Nenhum usuário encontrado.'),
              );
            }

            // ESTADO 4: Dados carregados com sucesso (ListView.builder otimizado)
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: usuarios.length,
              itemBuilder: (context, index) {
                final usuario = usuarios[index];
                return _UsuarioCard(usuario: usuario);
              },
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// 4. WIDGET PERSONALIZADO PARA CADA ITEM DA LISTA
// ============================================================================
class _UsuarioCard extends StatelessWidget {
  final Usuario usuario;

  const _UsuarioCard({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          child: Text(
            usuario.nome[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          usuario.nome,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    usuario.email,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.business_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${usuario.empresa} • ${usuario.cidade}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Exibe detalhes completos ao tocar no card
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nome,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '@${usuario.username}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('E-mail'),
                    subtitle: Text(usuario.email),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Telefone'),
                    subtitle: Text(usuario.telefone),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_city),
                    title: const Text('Cidade / Empresa'),
                    subtitle: Text('${usuario.cidade} - ${usuario.empresa}'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}