import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../../../core/models/user.dart';
import '../../data/user_service.dart';
import '../widgets/user_form_dialog.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _searchController = TextEditingController();
  final PagingController<int, User> _pagingController = PagingController(firstPageKey: 1);
  final UserService _userService = UserService();
  
  String? _selectedRole;
  int _totalItems = 0;
  int _currentItems = 0;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final result = await _userService.getUsers(
        page: pageKey,
        limit: 20,
        role: _selectedRole,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      final users = result['users'] as List<User>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      final isLastPage = pageKey >= pagination['totalPages'];

      setState(() {
        _totalItems = pagination['totalItems'];
        _currentItems = _pagingController.itemList?.length ?? 0;
      });

      if (isLastPage) {
        _pagingController.appendLastPage(users);
        setState(() {
          _currentItems = (_pagingController.itemList?.length ?? 0);
        });
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(users, nextPageKey);
        setState(() {
          _currentItems = (_pagingController.itemList?.length ?? 0);
        });
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void _refreshData() {
    _pagingController.refresh();
  }

  void _showUserForm(User user) {
    showDialog(
      context: context,
      builder: (dialogContext) => UserFormDialog(
        user: user,
        onSave: (userId, role, isActive) async {
          await _userService.updateUser(userId, {
            'role': role,
            'is_active': isActive,
          });
          _refreshData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
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
                                _refreshData();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (value) {
                      _refreshData();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String?>(
                  value: _selectedRole,
                  hint: const Text('Todos los roles'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos los roles')),
                    DropdownMenuItem(value: 'user', child: Text('Usuario')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'superadmin', child: Text('Super Admin')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                    _refreshData();
                  },
                ),
                const SizedBox(width: 16),
                // Counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_currentItems / $_totalItems',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Users list with infinite scroll
          Expanded(
            child: PagedListView<int, User>(
              pagingController: _pagingController,
              padding: const EdgeInsets.all(16),
              builderDelegate: PagedChildBuilderDelegate<User>(
                itemBuilder: (context, user, index) => _UserCard(
                  user: user,
                  onEdit: () => _showUserForm(user),
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Eliminar usuario'),
                        content: Text('¿Estás seguro de eliminar a ${user.fullName}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      try {
                        await _userService.deleteUser(user.id);
                        _refreshData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usuario eliminado'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
                firstPageErrorIndicatorBuilder: (context) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Error al cargar usuarios', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _refreshData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
                noItemsFoundIndicatorBuilder: (context) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No hay usuarios', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getRoleColor() {
    switch (user.role) {
      case 'superadmin':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor();
    final isSuperAdmin = user.role == 'superadmin';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: roleColor.withValues(alpha:0.2),
              child: Text(
                user.email[0].toUpperCase(),
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName : user.email,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (user.phone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.phone!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            
            // Actions
            if (!isSuperAdmin) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
                color: Theme.of(context).colorScheme.primary,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
