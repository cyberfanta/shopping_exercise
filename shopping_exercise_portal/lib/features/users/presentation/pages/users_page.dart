import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../core/models/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/users_cubit.dart';
import '../widgets/user_form_dialog.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _searchController = TextEditingController();
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    context.read<UsersCubit>().loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserForm(User user) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<UsersCubit>(),
        child: UserFormDialog(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsersCubit, UsersState>(
      listener: (context, state) {
        if (state is UsersError) {
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
            title: const Text('Gestión de Usuarios'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<UsersCubit>().loadUsers(
                        role: _selectedRole,
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
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar usuarios...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                    });
                                    context.read<UsersCubit>().loadUsers(
                                          role: _selectedRole,
                                        );
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: (value) {
                          context.read<UsersCubit>().loadUsers(
                                role: _selectedRole,
                                search: value,
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String?>(
                      value: _selectedRole,
                      hint: const Text('Todos los roles'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(value: 'user', child: Text('Usuario')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'superadmin', child: Text('SuperAdmin')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                        context.read<UsersCubit>().loadUsers(
                              role: value,
                              search: _searchController.text,
                            );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Users table
              Expanded(
                child: state is UsersLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state is UsersLoaded
                        ? state.users.isEmpty
                            ? const Center(child: Text('No hay usuarios'))
                            : BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, authState) {
                                  final currentUser = authState is AuthAuthenticated
                                      ? authState.user
                                      : null;
                                  
                                  return DataTable2(
                                    columnSpacing: 12,
                                    horizontalMargin: 12,
                                    minWidth: 600,
                                    columns: const [
                                      DataColumn2(label: Text('Email'), size: ColumnSize.L),
                                      DataColumn2(label: Text('Nombre')),
                                      DataColumn2(label: Text('Rol')),
                                      DataColumn2(label: Text('Estado')),
                                      DataColumn2(label: Text('Acciones'), fixedWidth: 120),
                                    ],
                                    rows: state.users.map((user) {
                                      final isSuperAdmin = user.email == 'julioleon2004@gmail.com';
                                      final canDelete = !isSuperAdmin &&
                                          currentUser != null &&
                                          currentUser.isSuperAdmin;

                                      return DataRow2(
                                        cells: [
                                          DataCell(
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor:
                                                      Theme.of(context).colorScheme.primary,
                                                  child: Text(
                                                    user.email[0].toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    user.email,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(Text(user.fullName.isNotEmpty
                                              ? user.fullName
                                              : '-')),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getRoleColor(context, user.role)
                                                    .withValues(alpha:0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _getRoleColor(context, user.role),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                _getRoleText(user.role),
                                                style: TextStyle(
                                                  color: _getRoleColor(context, user.role),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Icon(
                                              user.isActive
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color: user.isActive
                                                  ? Colors.green
                                                  : Colors.red,
                                              size: 20,
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, size: 18),
                                                  onPressed: () => _showUserForm(user),
                                                  tooltip: 'Editar',
                                                ),
                                                if (canDelete)
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, size: 18),
                                                    color: Theme.of(context).colorScheme.error,
                                                    onPressed: () => _confirmDelete(context, user),
                                                    tooltip: 'Eliminar',
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  );
                                },
                              )
                        : const Center(child: Text('Error al cargar usuarios')),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Estás seguro de eliminar a ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<UsersCubit>().deleteUser(user.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(BuildContext context, String role) {
    switch (role) {
      case 'superadmin':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'superadmin':
        return 'SUPER ADMIN';
      case 'admin':
        return 'ADMIN';
      default:
        return 'USUARIO';
    }
  }
}

