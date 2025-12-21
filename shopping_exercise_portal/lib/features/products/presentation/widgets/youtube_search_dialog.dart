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
  List<Map<String, dynamic>>? _filteredVideos;
  Set<int> _selectedIndices = {};
  bool _loading = false;
  
  // Filtros de YouTube
  String _order = 'relevance';
  String _duration = 'any';
  
  // Filtro local por canal
  String? _selectedChannelFilter;
  List<String> _availableChannels = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _loading = true;
      _selectedIndices.clear();
    });

    try {
      final videos = await context.read<ProductsCubit>().searchYoutubeVideos(
            _searchController.text,
            order: _order,
            videoDuration: _duration,
          );
      setState(() {
        _videos = videos;
        _filteredVideos = videos;
        _loading = false;
        
        // Extraer canales únicos
        _availableChannels = videos
            .map((v) => v['channelTitle'] as String)
            .toSet()
            .toList()
          ..sort();
        _selectedChannelFilter = null;
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

  void _filterByChannel(String? channelName) {
    setState(() {
      _selectedChannelFilter = channelName;
      if (channelName == null || _videos == null) {
        _filteredVideos = _videos;
      } else {
        _filteredVideos = _videos!
            .where((v) => v['channelTitle'] == channelName)
            .toList();
      }
      _selectedIndices.clear();
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_filteredVideos != null) {
        if (_selectedIndices.length == _filteredVideos!.length) {
          // Deseleccionar todos
          _selectedIndices.clear();
        } else {
          // Seleccionar todos los visibles
          _selectedIndices = Set.from(List.generate(_filteredVideos!.length, (i) => i));
        }
      }
    });
  }

  Future<void> _addSelectedVideos() async {
    if (_selectedIndices.isEmpty || _filteredVideos == null) return;

    final selectedVideos = _selectedIndices
        .map((index) => _filteredVideos![index])
        .toList();

    // Preparar productos para crear
    final products = selectedVideos.map((video) {
      return {
        'name': video['title'],
        'description': video['description'],
        'price': video['suggestedPrice'],
        'stock': 999,
        'youtube_video_id': video['videoId'],
        'youtube_channel_id': video['channelId'],
        'youtube_channel_name': video['channelTitle'],
        'youtube_thumbnail': video['thumbnail'],
        'youtube_duration': video['duration'],
      };
    }).toList();

    // Guardar referencias antes de modificar el árbol de widgets
    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final productsCubit = context.read<ProductsCubit>();

    // Cerrar el diálogo de búsqueda
    navigator.pop();

    // Mostrar loading usando el navigator raíz
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (loadingContext) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Agregando videos...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await productsCubit.createMultipleProducts(products);
      // Cerrar loading
      navigator.pop();
      // Mostrar mensaje de éxito
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${products.length} videos agregados exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Cerrar loading
      navigator.pop();
      // Mostrar error
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Buscar Videos de YouTube',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (_selectedIndices.isNotEmpty)
                    Chip(
                      label: Text('${_selectedIndices.length} seleccionados'),
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha:0.2),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar videos...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _search,
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 16),
              
              // Filters
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _order,
                      decoration: const InputDecoration(
                        labelText: 'Ordenar por',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'relevance', child: Text('Relevancia')),
                        DropdownMenuItem(value: 'date', child: Text('Fecha')),
                        DropdownMenuItem(value: 'viewCount', child: Text('Vistas')),
                        DropdownMenuItem(value: 'rating', child: Text('Calificación')),
                        DropdownMenuItem(value: 'title', child: Text('Título')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _order = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _duration,
                      decoration: const InputDecoration(
                        labelText: 'Duración',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'any', child: Text('Cualquiera')),
                        DropdownMenuItem(value: 'short', child: Text('Corto (< 4 min)')),
                        DropdownMenuItem(value: 'medium', child: Text('Medio (4-20 min)')),
                        DropdownMenuItem(value: 'long', child: Text('Largo (> 20 min)')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _duration = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Channel filter and select all
              if (_filteredVideos != null && _filteredVideos!.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedChannelFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por canal',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos los canales'),
                          ),
                          ..._availableChannels.map((channel) {
                            return DropdownMenuItem(
                              value: channel,
                              child: Text(channel),
                            );
                          }),
                        ],
                        onChanged: _filterByChannel,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _selectAll,
                      icon: Icon(
                        _selectedIndices.length == _filteredVideos!.length
                            ? Icons.deselect
                            : Icons.select_all,
                      ),
                      label: Text(
                        _selectedIndices.length == _filteredVideos!.length
                            ? 'Deseleccionar'
                            : 'Seleccionar todos',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha:0.2),
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Results
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredVideos == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.video_library_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Busca videos de YouTube',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : _filteredVideos!.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No se encontraron videos',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Prueba con otros filtros',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                            itemCount: _filteredVideos!.length,
                            itemBuilder: (context, index) {
                              final video = _filteredVideos![index];
                              final isSelected = _selectedIndices.contains(index);
                              final price = video['suggestedPrice'] ?? 0.0;
                              final views = video['viewCount'] ?? 0;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha:0.1)
                                    : null,
                                child: InkWell(
                                  onTap: () => _toggleSelection(index),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        // Checkbox
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (_) => _toggleSelection(index),
                                        ),
                                        const SizedBox(width: 8),
                                        
                                        // Thumbnail
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            video['thumbnail'],
                                            width: 120,
                                            height: 68,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 120,
                                              height: 68,
                                              color: Colors.grey.shade300,
                                              child: const Icon(Icons.error),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        
                                        // Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                video['title'],
                                                style: Theme.of(context).textTheme.titleSmall,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                video['channelTitle'],
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.visibility, size: 14, color: Colors.grey.shade600),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatViews(views),
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).colorScheme.primary.withValues(alpha:0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      '\$${price.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: Theme.of(context).colorScheme.primary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 16),
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectedIndices.isEmpty ? null : _addSelectedVideos,
                    icon: const Icon(Icons.add),
                    label: Text('Agregar (${_selectedIndices.length})'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M vistas';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K vistas';
    } else {
      return '$views vistas';
    }
  }
}
