import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Crear instancia única de ApiService
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        // Proveer ApiService para que todos puedan acceder
        Provider<ApiService>.value(value: apiService),
        
        // AuthProvider (gestiona autenticación y usuario)
        ChangeNotifierProvider(
          create: (context) => AuthProvider(apiService),
        ),
        
        // CartProvider (gestiona carrito de compras)
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (context) => CartProvider(apiService),
          update: (context, auth, previous) {
            // Cuando cambia la autenticación, recargar el carrito
            if (auth.isAuthenticated && previous != null) {
              previous.loadCart();
            }
            return previous ?? CartProvider(apiService);
          },
        ),
        
        // ProductProvider (gestiona productos y categorías)
        ChangeNotifierProvider(
          create: (context) => ProductProvider(apiService),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Videos Shop',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            
            // Mostrar splash mientras se inicializa
            home: authProvider.isInitialized
                ? const HomeScreen()
                : const SplashScreen(),
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o icono de la app
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.gold,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gold.withValues(alpha:0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_circle_outline,
                size: 64,
                color: AppTheme.navyBlue,
              ),
            ),
            const SizedBox(height: 32),
            
            // Título de la app
            const Text(
              'Videos Shop',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.gold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            
            const Text(
              'Tus videos favoritos',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            
            // Loading indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
