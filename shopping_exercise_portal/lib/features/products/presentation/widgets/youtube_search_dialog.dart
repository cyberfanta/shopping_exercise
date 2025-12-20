import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/products_cubit.dart';

class YoutubeSearchDialog extends StatefulWidget {
  const YoutubeSearchDialog({super.key});

  @override
  State<YoutubeSearchDialog> createState() => _YoutubeSearchDialogState();
}

class _YoutubeSearchDialogState extends State<YoutubeSearchDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>>? _videos;
  bool _loading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _loading = true;
    });

    try {
      final videos = await context
          .read<ProductsCubit>()
          .searchYoutubeVideos(_searchController.text);
      setState(() {
        _videos = videos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _selectVideo(Map<String, dynamic> video) {
    Navigator.pop(context, video);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Buscar Video de YouTube',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar videos...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _search,
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _videos == null
                        ? const Center(child: Text('Busca videos de YouTube'))
                        : ListView.builder(
                            itemCount: _videos!.length,
                            itemBuilder: (context, index) {
                              final video = _videos![index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      video['thumbnail'],
                                      width: 80,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(
                                    video['title'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(video['channelTitle']),
                                  onTap: () => _selectVideo(video),
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

