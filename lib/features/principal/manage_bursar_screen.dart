import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state.dart';

class ManageBursarScreen extends StatefulWidget {
  const ManageBursarScreen({super.key, required this.principal});

  final UserModel principal;

  @override
  State<ManageBursarScreen> createState() => _ManageBursarScreenState();
}

class _ManageBursarScreenState extends State<ManageBursarScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _temporaryPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _temporaryPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final credential = await _authService.createUserFromAdminContext(
        email: _emailController.text.trim(),
        password: _temporaryPasswordController.text.trim(),
      );

      await _firestoreService.saveBursarUser(
        userId: credential.user!.uid,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        schoolId: widget.principal.schoolId,
      );

      await _authService.sendEmailVerification(user: credential.user);

      if (!mounted) {
        return;
      }

      _formKey.currentState!.reset();
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _temporaryPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bursar account created. A verification email has been sent.',
          ),
        ),
      );
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        DashboardCard(
          title: 'Manage Bursar',
          subtitle:
              'Create bursar accounts for ${widget.principal.schoolId}. New bursars are saved as active users under this school only.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  validator:
                      (value) => Validators.requiredField(
                        value,
                        fieldName: 'Bursar name',
                      ),
                  decoration: const InputDecoration(labelText: 'Bursar name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  validator: Validators.kenyanPhoneNumber,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  validator: Validators.email,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _temporaryPasswordController,
                  validator: Validators.password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Temporary password',
                  ),
                ),
                if (_errorMessage != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(
                    _isSubmitting ? 'Creating bursar...' : 'Create bursar',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Active Bursars',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<UserModel>>(
          stream: _firestoreService.streamSchoolUsersByRole(
            schoolId: widget.principal.schoolId,
            role: 'bursar',
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final List<UserModel> bursars = snapshot.data ?? <UserModel>[];
            if (bursars.isEmpty) {
              return const EmptyState(
                icon: Icons.account_circle_outlined,
                title: 'No bursars added',
                message:
                    'Once you create bursar accounts, they will appear here for this school.',
              );
            }

            return Column(
              children:
                  bursars
                      .map(
                        (bursar) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DashboardCard(
                            title: bursar.name,
                            subtitle:
                                '${bursar.email} | ${bursar.phoneNumber ?? 'No phone'}',
                            trailing: Chip(
                              label: Text(bursar.status.toUpperCase()),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            );
          },
        ),
      ],
    );
  }
}
