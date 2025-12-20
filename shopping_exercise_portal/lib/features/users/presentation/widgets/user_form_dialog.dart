import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/users_cubit.dart';

class UserFormDialog extends StatefulWidget {
  final User user;

  const UserFormDialog({super.key, required this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late String _role;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phone);
    _role = widget.user.role;
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final userData = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'phone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
        'role': _role,
        'is_active': _isActive,
      };

      context.read<UsersCubit>().updateUser(widget.user.id, userData);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = widget.user.email == 'julioleon2004@gmail.com';

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUser =
            authState is AuthAuthenticated ? authState.user : null;
        final canEditRole = currentUser != null && currentUser.isSuperAdmin;

        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Editar Usuario',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email (readonly)
                            TextField(
                              controller: TextEditingController(text: widget.user.email),
                              decoration: const InputDecoration(labelText: 'Email'),
                              enabled: false,
                            ),
                            const SizedBox(height: 16),
                            
                            // First Name
                            TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(labelText: 'Nombre'),
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            // Last Name
                            TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(labelText: 'Apellido'),
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            // Phone
                            TextFormField(
                              controller: _phoneController,
                              decoration:
                                  const InputDecoration(labelText: 'Teléfono (opcional)'),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            
                            // Role
                            if (canEditRole && !isSuperAdmin)
                              DropdownButtonFormField<String>(
                                initialValue: _role,
                                decoration: const InputDecoration(labelText: 'Rol'),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'user',
                                    child: Text('Usuario'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'admin',
                                    child: Text('Admin'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'superadmin',
                                    child: Text('Super Admin'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _role = value!;
                                  });
                                },
                              ),
                            if (!canEditRole || isSuperAdmin) ...[
                              TextField(
                                controller: TextEditingController(
                                  text: _role.toUpperCase(),
                                ),
                                decoration: const InputDecoration(labelText: 'Rol'),
                                enabled: false,
                              ),
                              if (isSuperAdmin)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    '⚠️ El superadmin no puede ser modificado',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 16),
                            
                            // Active
                            if (!isSuperAdmin)
                              SwitchListTile(
                                title: const Text('Usuario activo'),
                                value: _isActive,
                                onChanged: (value) {
                                  setState(() {
                                    _isActive = value;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSuperAdmin && currentUser?.email != widget.user.email
                              ? null
                              : _submit,
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

