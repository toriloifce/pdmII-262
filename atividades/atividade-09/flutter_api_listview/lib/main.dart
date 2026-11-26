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
      title: 'Catálogo de Terror',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: const ListaFilmesTerrorScreen(),
    );
  }
}

// ============================================================================
// 1. MODELO DE DADOS (Conversão de JSON para Objeto FilmeTerror)
// ============================================================================
class FilmeTerror {
  final int id;
  final String titulo;
  final String posterUrl;
  final String imdbId;

  const FilmeTerror({
    required this.id,
    required this.titulo,
    required this.posterUrl,
    required this.imdbId,
  });

  factory FilmeTerror.fromJson(Map<String, dynamic> json) {
    final show = (json['show'] as Map<String, dynamic>?) ?? json;
    final image = show['image'] as Map<String, dynamic>?;
    final externals = show['externals'] as Map<String, dynamic>?;

    return FilmeTerror(
      id: (show['id'] as num?)?.toInt() ?? 0,
      titulo: (show['name'] as String?) ?? 'Título Desconhecido',
      posterUrl: (image?['medium'] as String?) ?? '',
      imdbId: (externals?['imdb'] as String?) ?? 'N/A',
    );
  }
}

// ============================================================================
// 2. CAMADA DE SERVIÇO (Requisição HTTP GET + Tratamento de Erros)
// ============================================================================
class FilmeTerrorService {
  static const String _baseUrl = 'https://api.tvmaze.com/search/shows?q=horror';

  Future<List<FilmeTerror>> buscarFilmes() async {
    try {
      final response = await http
          .get(
            Uri.parse(_baseUrl),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> dadosJson = jsonDecode(response.body);
        return dadosJson
            .map((json) => FilmeTerror.fromJson(json as Map<String, dynamic>))
            .where((filme) => filme.titulo.isNotEmpty)
            .toList();
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
class ListaFilmesTerrorScreen extends StatefulWidget {
  const ListaFilmesTerrorScreen({super.key});

  @override
  State<ListaFilmesTerrorScreen> createState() =>
      _ListaFilmesTerrorScreenState();
}

class _ListaFilmesTerrorScreenState extends State<ListaFilmesTerrorScreen> {
  final FilmeTerrorService _filmeService = FilmeTerrorService();
  late Future<List<FilmeTerror>> _futureFilmes;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    setState(() {
      _futureFilmes = _filmeService.buscarFilmes();
    });
  }

  Future<void> _recarregarLista() async {
    _carregarDados();
    await _futureFilmes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_movies, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Filmes de Terror',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F1A1A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar catálogo',
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.redAccent,
        onRefresh: _recarregarLista,
        child: FutureBuilder<List<FilmeTerror>>(
          future: _futureFilmes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.redAccent),
                    SizedBox(height: 16),
                    Text('Invocando filmes de terror da API...'),
                  ],
                ),
              );
            }

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
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Não foi possível carregar os filmes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mensagemErro,
                        style: TextStyle(color: Colors.grey[400]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red[900],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _carregarDados,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final filmes = snapshot.data ?? [];
            if (filmes.isEmpty) {
              return const Center(
                child: Text('Nenhum filme de terror encontrado.'),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: filmes.length,
              itemBuilder: (context, index) {
                final filme = filmes[index];
                return _FilmeCard(filme: filme);
              },
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// 4. WIDGET DE PÔSTER DO FILME COM FALLBACK SEGURO
// ============================================================================
class _PosterFilme extends StatelessWidget {
  final String posterUrl;
  final double largura;
  final double altura;

  const _PosterFilme({
    required this.posterUrl,
    this.largura = 60,
    this.altura = 90,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: posterUrl.isEmpty
          ? _fallbackPoster()
          : Image.network(
              posterUrl,
              width: largura,
              height: altura,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: largura,
                  height: altura,
                  color: const Color(0xFF2A2424),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => _fallbackPoster(),
            ),
    );
  }

  Widget _fallbackPoster() {
    return Container(
      width: largura,
      height: altura,
      color: const Color(0xFF2C1515),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_filter, color: Colors.redAccent, size: 28),
          SizedBox(height: 4),
          Text(
            'TERROR',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. WIDGET PERSONALIZADO PARA CADA FILME DA LISTA
// ============================================================================
class _FilmeCard extends StatelessWidget {
  final FilmeTerror filme;

  const _FilmeCard({required this.filme});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF1A1717),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PosterFilme(
                      posterUrl: filme.posterUrl,
                      largura: 130,
                      altura: 195,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      filme.titulo,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      avatar: const Icon(
                        Icons.local_fire_department,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      label: const Text('Gênero: Terror / Horror'),
                      backgroundColor: const Color(0xFF2E1A1A),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(Icons.tag, color: Colors.redAccent),
                      title: const Text('ID no Catálogo'),
                      subtitle: Text('#${filme.id}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.movie, color: Colors.redAccent),
                      title: const Text('Código IMDb'),
                      subtitle: Text(filme.imdbId),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              _PosterFilme(posterUrl: filme.posterUrl, largura: 62, altura: 92),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filme.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Text(
                            'TERROR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.confirmation_number_outlined,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'IMDb: ${filme.imdbId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}