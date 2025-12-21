import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../services/order_service.dart';
import '../config/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'order_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController(text: 'México');
  final _notesController = TextEditingController();

  String _paymentMethod = 'credit_card';
  bool _isProcessing = false;

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Compra'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final cart = cartProvider.cart;

          if (cart == null || cart.items.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Carrito vacío',
              message: 'No hay productos en el carrito',
              action: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            );
          }

          final subtotal = cart.subtotal;
          final tax = subtotal * 0.16; // 16% IVA
          final shipping = subtotal > 500 ? 0.0 : 50.0; // Envío gratis > $500
          final total = subtotal + tax + shipping;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resumen de la orden
                  Text(
                    'Resumen de la orden',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            'Subtotal',
                            priceFormat.format(subtotal),
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'IVA (16%)',
                            priceFormat.format(tax),
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Envío',
                            shipping == 0
                                ? 'GRATIS'
                                : priceFormat.format(shipping),
                            isShipping: true,
                          ),
                          const Divider(height: 24),
                          _buildSummaryRow(
                            'Total',
                            priceFormat.format(total),
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dirección de envío
                  Text(
                    'Dirección de envío',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _streetController,
                    decoration: const InputDecoration(
                      labelText: 'Calle y número',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'Ciudad',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _zipController,
                          decoration: const InputDecoration(
                            labelText: 'Código postal',
                            prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                            labelText: 'País',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Méto do de pago
                  Text(
                    'Método de pago',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentMethod(
                    'credit_card',
                    'Tarjeta de crédito',
                    Icons.credit_card,
                  ),
                  _buildPaymentMethod(
                    'debit_card',
                    'Tarjeta de débito',
                    Icons.credit_card_outlined,
                  ),
                  _buildPaymentMethod(
                    'paypal',
                    'PayPal',
                    Icons.account_balance_wallet,
                  ),
                  const SizedBox(height: 24),

                  // Notas adicionales
                  Text(
                    'Notas adicionales (opcional)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Instrucciones de entrega, etc.',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Botón de pago
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('Pagar ${priceFormat.format(total)}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Al hacer clic en "Pagar", aceptas nuestros términos y condiciones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false, bool isShipping = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppTheme.navyBlue : AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isShipping && value == 'GRATIS'
                ? AppTheme.success
                : (isTotal ? AppTheme.navyBlue : AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(String value, String label, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _paymentMethod,
      onChanged: (newValue) {
        setState(() {
          _paymentMethod = newValue!;
        });
      },
      title: Text(label),
      secondary: Icon(icon, color: AppTheme.navyBlue),
      activeColor: AppTheme.navyBlue,
    );
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final apiService = context.read<ApiService>();
      final orderService = OrderService(apiService);

      // Crear la orden
      final order = await orderService.createOrder(
        paymentMethod: _paymentMethod,
        shippingAddress: {
          'street': _streetController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'zip': _zipController.text,
          'country': _countryController.text,
        },
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      // Simular el pago
      final paymentResult = await orderService.simulatePayment(order.id);

      // Recargar el carrito (debería estar vacío ahora)
      await context.read<CartProvider>().loadCart();

      if (mounted) {
        // Mostrar resultado
        if (paymentResult['payment_status'] == 'paid') {
          _showSuccessDialog(order.id);
        } else {
          _showErrorDialog(
              'El pago no pudo ser procesado. Por favor, intenta nuevamente.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('¡Pago exitoso!'),
            ),
          ],
        ),
        content: const Text(
          'Tu orden ha sido procesada correctamente. Recibirás un correo con los detalles.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Cerrar diálogo
              Navigator.pop(context);
              // Volver al inicio
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Ir al inicio'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo
              
              try {
                final apiService = context.read<ApiService>();
                final orderService = OrderService(apiService);
                final order = await orderService.getOrderById(orderId);
                
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailScreen(order: order),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cargar orden: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              }
            },
            child: const Text('Ver orden'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.error, size: 32),
            SizedBox(width: 12),
            Text('Error en el pago'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

