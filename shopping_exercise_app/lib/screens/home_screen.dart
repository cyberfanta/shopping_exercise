import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/common_widgets.dart';
import '../config/app_theme.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      final cartProvider = context.read<CartProvider>();
      
      productProvider.loadProducts(refresh: true);
      productProvider.loadCategories();
      cartProvider.loadCart();
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<ProductProvider>().loadProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _currentIndex == 0 ? _buildProductsView() : const OrdersScreen(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Videos Shop'),
      actions: [
        // Botón de usuario/login
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.user;
            final isPublicUser = user?.email == 'user@ejemplo.com';

            return PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: AppTheme.gold,
                radius: 16,
                child: Icon(
                  isPublicUser ? Icons.person_outline : Icons.person,
                  color: AppTheme.navyBlue,
                  size: 20,
                ),
              ),
              tooltip: user != null ? user.email : 'Usuario',
              onSelected: (value) {
                if (value == 'logout') {
                  _showLogoutDialog(context);
                } else if (value == 'login') {
                  _showLoginDialog(context);
                }
              },
              itemBuilder: (context) {
                if (isPublicUser) {
                  return [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Usuario Público',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'login',
                      child: Row(
                        children: [
                          Icon(Icons.login, size: 20),
                          SizedBox(width: 12),
                          Text('Iniciar sesión'),
                        ],
                      ),
                    ),
                  ];
                } else {
                  return [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Usuario',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 12),
                          Text('Cerrar sesión'),
                        ],
                      ),
                    ),
                  ];
                }
              },
            );
          },
        ),
        const SizedBox(width: 8),
        Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            final itemCount = cartProvider.itemCount;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
                if (itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.gold,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        itemCount > 99 ? '99+' : itemCount.toString(),
                        style: const TextStyle(
                          color: AppTheme.navyBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Pedidos',
        ),
      ],
    );
  }

  Widget _buildProductsView() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return Column(
          children: [
            _buildSearchBar(productProvider),
            _buildCategoryFilter(productProvider),
            Expanded(
              child: _buildProductList(productProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(ProductProvider productProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar videos...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    productProvider.setSearchQuery(null);
                  },
                )
              : null,
        ),
        onSubmitted: (value) {
          productProvider.setSearchQuery(value.isEmpty ? null : value);
        },
      ),
    );
  }

  Widget _buildCategoryFilter(ProductProvider productProvider) {
    if (productProvider.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: productProvider.categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Todos'),
                selected: productProvider.selectedCategoryId == null,
                onSelected: (_) {
                  productProvider.setCategory(null);
                },
              ),
            );
          }

          final category = productProvider.categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category.name),
              selected: productProvider.selectedCategoryId == category.id,
              onSelected: (_) {
                productProvider.setCategory(category.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList(ProductProvider productProvider) {
    if (productProvider.isLoading && productProvider.products.isEmpty) {
      return const LoadingIndicator(size: 48);
    }

    if (productProvider.error != null && productProvider.products.isEmpty) {
      return ErrorDisplay(
        message: productProvider.error!,
        onRetry: () => productProvider.loadProducts(refresh: true),
      );
    }

    if (productProvider.products.isEmpty) {
      return EmptyState(
        icon: Icons.video_library_outlined,
        title: 'No hay videos',
        message: 'No se encontraron videos con los filtros seleccionados',
        action: ElevatedButton(
          onPressed: () => productProvider.clearFilters(),
          child: const Text('Limpiar filtros'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => productProvider.loadProducts(refresh: true),
      color: AppTheme.gold,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calcular cuántas columnas caben según el ancho disponible
          // Ancho mínimo por tarjeta: 160px + espaciado
          const double minCardWidth = 160.0;
          const double spacing = 12.0;
          final double availableWidth = constraints.maxWidth - (spacing * 2);
          final int crossAxisCount = (availableWidth / (minCardWidth + spacing)).floor().clamp(2, 6);
          
          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.75, // Relación ancho/alto de cada tarjeta
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: productProvider.products.length +
                (productProvider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == productProvider.products.length) {
                return const Center(child: LoadingIndicator());
              }

              final product = productProvider.products[index];
              return _buildProductCard(context, product);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return ProductCard(
      product: product,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      onAddToCart: () async {
        try {
          await context.read<CartProvider>().addToCart(product.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} agregado al carrito'),
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
                content: Text('Error: $e'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?\n\nSe volverá a iniciar sesión automáticamente con el usuario público.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sesión cerrada. Usuario público activado.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                // Recargar datos
                context.read<CartProvider>().loadCart();
                context.read<ProductProvider>().loadProducts(refresh: true);
              }
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool isRegisterMode = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isRegisterMode ? 'Crear Cuenta' : 'Iniciar Sesión'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isRegisterMode) ...[
                    TextFormField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Apellido',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu apellido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono (opcional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu email';
                      }
                      if (!value.contains('@')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: isRegisterMode
                          ? 'Contraseña (mín. 6 caracteres)'
                          : 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outlined),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      if (isRegisterMode && value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  if (!isRegisterMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Usuario de prueba:\nuser@ejemplo.com / User123!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                setState(() {
                  isRegisterMode = !isRegisterMode;
                  // Limpiar campos al cambiar de modo
                  emailController.clear();
                  passwordController.clear();
                  firstNameController.clear();
                  lastNameController.clear();
                  phoneController.clear();
                  formKey.currentState?.reset();
                });
              },
              child: Text(isRegisterMode ? 'Ya tengo cuenta' : 'Crear cuenta'),
            ),
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setState(() => isLoading = true);

                      try {
                        if (isRegisterMode) {
                          // Registro
                          await context.read<AuthProvider>().register(
                            email: emailController.text.trim(),
                            password: passwordController.text,
                            firstName: firstNameController.text.trim(),
                            lastName: lastNameController.text.trim(),
                            phone: phoneController.text
                                .trim()
                                .isEmpty
                                ? null
                                : phoneController.text.trim(),
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cuenta creada exitosamente'),
                                backgroundColor: AppTheme.success,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            // Recargar datos
                            context.read<CartProvider>().loadCart();
                            context
                                .read<ProductProvider>()
                                .loadProducts(refresh: true);
                          }
                        } else {
                          // Login
                          await context.read<AuthProvider>().login(
                            emailController.text.trim(),
                            passwordController.text,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Inicio de sesión exitoso'),
                                backgroundColor: AppTheme.success,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            // Recargar datos
                            context.read<CartProvider>().loadCart();
                            context
                                .read<ProductProvider>()
                                .loadProducts(refresh: true);
                          }
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(isRegisterMode ? 'Crear cuenta' : 'Iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

