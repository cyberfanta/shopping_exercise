import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../core/models/admin_cart.dart';
import '../cubit/admin_carts_cubit.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminCartsCubit()..loadCarts(),
      child: const _CartPageContent(),
    );
  }
}

class _CartPageContent extends StatefulWidget {
  const _CartPageContent();

  @override
  State<_CartPageContent> createState() => _CartPageContentState();
}

class _CartPageContentState extends State<_CartPageContent> {
  final PagingController<int, AdminCart> _pagingController = PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final cubit = context.read<AdminCartsCubit>();
      await cubit.loadCarts(page: pageKey, isLoadMore: pageKey > 1);

      final state = cubit.state;
      if (state is AdminCartsLoaded) {
        final pagination = state.pagination;
        final newItems = pageKey == 1 ? state.carts : state.carts.skip((pageKey - 1) * 20).toList();

        if (pagination['page'] < pagination['totalPages']) {
          _pagingController.appendPage(newItems, pageKey + 1);
        } else {
          _pagingController.appendLastPage(newItems);
        }
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  void _showCartDetails(AdminCart cart) {
    showDialog(
      context: context,
      builder: (context) => _CartDetailsDialog(cart: cart),
    );
  }

  void _clearCart(AdminCart cart) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vaciar Carrito'),
        content: Text(
          '¿Estás seguro de vaciar el carrito de ${cart.userName} (${cart.userEmail})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<AdminCartsCubit>().clearCart(cart.userId);
              Navigator.pop(dialogContext);
              _pagingController.refresh();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminCartsCubit, AdminCartsState>(
      listener: (context, state) {
        if (state is AdminCartsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final totalItems = state is AdminCartsLoaded ? state.pagination['totalItems'] : 0;
        final currentItems = state is AdminCartsLoaded ? state.carts.length : 0;

        return Scaffold(
            appBar: AppBar(
              title: const Text('Carritos de Todos los Usuarios'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _pagingController.refresh();
                  },
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: Column(
              children: [
                // Header with counter
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Carritos activos con items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$currentItems / $totalItems carritos',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Carts list with Infinite Scroll
                Expanded(
                  child: PagedListView<int, AdminCart>(
                    pagingController: _pagingController,
                    padding: const EdgeInsets.all(16),
                    builderDelegate: PagedChildBuilderDelegate<AdminCart>(
                      itemBuilder: (context, cart, index) {
                        return _CartCard(
                          cart: cart,
                          onViewDetails: () => _showCartDetails(cart),
                          onClear: () => _clearCart(cart),
                        );
                      },
                      noItemsFoundIndicatorBuilder: (_) => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No hay carritos activos'),
                          ],
                        ),
                      ),
                      firstPageErrorIndicatorBuilder: (_) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Error al cargar carritos'),
                            ElevatedButton(
                              onPressed: () => _pagingController.refresh(),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
  }
}

class _CartCard extends StatelessWidget {
  final AdminCart cart;
  final VoidCallback onViewDetails;
  final VoidCallback onClear;

  const _CartCard({
    required this.cart,
    required this.onViewDetails,
    required this.onClear,
  });

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'hace unos segundos';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    cart.userEmail[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cart.userName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        cart.userEmail,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cart info
            Row(
              children: [
                Icon(Icons.shopping_cart, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${cart.itemsCount} item${cart.itemsCount > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(width: 24),
                Icon(Icons.attach_money, size: 20, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  '\$${cart.subtotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Last updated
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Actualizado: ${_getTimeAgo(cart.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preview of items (first 3)
            if (cart.items.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Items en el carrito:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...cart.items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        if (item.youtubeThumbnail != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item.youtubeThumbnail!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported, size: 40),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.productName} (${item.quantity}x)',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '\$${item.subtotal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )),
              if (cart.items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '... y ${cart.items.length - 3} más',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                  ),
                ),
            ],

            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Ver Detalle'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Vaciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartDetailsDialog extends StatelessWidget {
  final AdminCart cart;

  const _CartDetailsDialog({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Detalle del Carrito',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${cart.userName} (${cart.userEmail})',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: cart.items.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return ListTile(
                      leading: item.youtubeThumbnail != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                item.youtubeThumbnail!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported, size: 60),
                              ),
                            )
                          : const Icon(Icons.videocam, size: 60),
                      title: Text(item.productName),
                      subtitle: Text('Precio: \$${item.price.toStringAsFixed(2)} x ${item.quantity}'),
                      trailing: Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '\$${cart.subtotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
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
