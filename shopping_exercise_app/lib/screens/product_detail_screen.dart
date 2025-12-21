import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../config/app_theme.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Video'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail del video
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.product.youtubeThumbnail != null)
                    CachedNetworkImage(
                      imageUrl: widget.product.youtubeThumbnail!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.video_library, size: 64),
                    ),
                  
                  // Botón de reproducir
                  if (widget.product.youtubeVideoId != null)
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha:0.7),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 48,
                          ),
                          onPressed: () => _openYouTube(),
                        ),
                      ),
                    ),

                  // Duración
                  if (widget.product.displayDuration.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha:0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.product.displayDuration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Información del producto
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría
                  if (widget.product.categoryName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGold,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.product.categoryName!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.navyBlue,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Título
                  Text(
                    widget.product.name,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 16),

                  // Precio
                  Row(
                    children: [
                      if (widget.product.discountPrice != null) ...[
                        Text(
                          priceFormat.format(widget.product.price),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${(((widget.product.price - widget.product.discountPrice!) / widget.product.price) * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    priceFormat.format(widget.product.effectivePrice),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navyBlue,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stock
                  Row(
                    children: [
                      Icon(
                        widget.product.stock > 0
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: widget.product.stock > 0
                            ? AppTheme.success
                            : AppTheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.product.stock > 0
                            ? '${widget.product.stock} disponibles'
                            : 'Sin stock',
                        style: TextStyle(
                          color: widget.product.stock > 0
                              ? AppTheme.success
                              : AppTheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Descripción
                  Text(
                    'Descripción',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),

                  // Selector de cantidad
                  if (widget.product.stock > 0) ...[
                    Text(
                      'Cantidad',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppTheme.navyBlue,
                          iconSize: 32,
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.navyBlue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _quantity.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _quantity < widget.product.stock
                              ? () => setState(() => _quantity++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppTheme.navyBlue,
                          iconSize: 32,
                        ),
                        const Spacer(),
                        Text(
                          'Total: ${priceFormat.format(widget.product.effectivePrice * _quantity)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navyBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.product.stock > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: () => _addToCart(context),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Agregar al carrito'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _openYouTube() async {
    if (widget.product.youtubeVideoId == null) return;

    final url = Uri.parse(
        'https://www.youtube.com/watch?v=${widget.product.youtubeVideoId}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el video'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _addToCart(BuildContext context) async {
    try {
      await context.read<CartProvider>().addToCart(
            widget.product.id,
            quantity: _quantity,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$_quantity ${widget.product.name} agregado(s) al carrito',
            ),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Ver carrito',
              textColor: AppTheme.gold,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CartScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar al carrito: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}

