import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/product.dart';
import '../cubit/products_cubit.dart';
import '../widgets/product_form_dialog.dart';
import '../widgets/youtube_search_dialog.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _searchController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductForm({Product? product}) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ProductsCubit>(),
        child: ProductFormDialog(product: product),
      ),
    );
  }

  void _showYoutubeSearch(BuildContext productContext) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: productContext.read<ProductsCubit>(),
        child: const YoutubeSearchDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductsCubit, ProductsState>(
      listener: (context, state) {
        if (state is ProductsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestión de Productos'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<ProductsCubit>().loadProducts(
                        categoryId: _selectedCategoryId,
                        search: _searchController.text,
                      );
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Column(
            children: [
              // Search and filters
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar productos...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                        });
                                        context.read<ProductsCubit>().loadProducts(
                                              categoryId: _selectedCategoryId,
                                            );
                                      },
                                    )
                                  : null,
                            ),
                            onSubmitted: (value) {
                              context.read<ProductsCubit>().loadProducts(
                                    categoryId: _selectedCategoryId,
                                    search: value,
                                  );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (state is ProductsLoaded) ...[
                          DropdownButton<String?>(
                            value: _selectedCategoryId,
                            hint: const Text('Todas las categorías'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Todas las categorías'),
                              ),
                              ...state.categories.map((category) {
                                return DropdownMenuItem(
                                  value: category.id,
                                  child: Text(category.name),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryId = value;
                              });
                              context.read<ProductsCubit>().loadProducts(
                                    categoryId: value,
                                    search: _searchController.text,
                                  );
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Products list
              Expanded(
                child: state is ProductsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state is ProductsLoaded
                        ? state.products.isEmpty
                            ? const Center(
                                child: Text('No hay productos'),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 300,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: state.products.length,
                                itemBuilder: (context, index) {
                                  final product = state.products[index];
                                  return _ProductCard(
                                    product: product,
                                    onEdit: () => _showProductForm(product: product),
                                    onDelete: () {
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) => AlertDialog(
                                          title: const Text('Eliminar producto'),
                                          content: Text(
                                            '¿Estás seguro de eliminar "${product.name}"?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dialogContext),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                context
                                                    .read<ProductsCubit>()
                                                    .deleteProduct(product.id);
                                                Navigator.pop(dialogContext);
                                              },
                                              child: const Text('Eliminar'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              )
                        : const Center(
                            child: Text('Error al cargar productos'),
                          ),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'youtube',
                onPressed: () => _showYoutubeSearch(context),
                icon: const Icon(Icons.video_library),
                label: const Text('YouTube'),
                backgroundColor: Colors.red,
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                heroTag: 'add',
                onPressed: () => _showProductForm(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Producto'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: product.thumbnail.isNotEmpty
                      ? Image.network(
                          product.thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_not_supported, size: 48);
                          },
                        )
                      : const Icon(Icons.image, size: 48),
                ),
                if (product.youtubeVideoId != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.finalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product.stock} unidades',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      color: Theme.of(context).colorScheme.error,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha:0.1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

