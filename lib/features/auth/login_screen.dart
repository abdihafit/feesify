import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _countyController = TextEditingController();
  final TextEditingController _principalNameController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _loginIdentifierController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  AuthService get _authService => AuthService();
  FirestoreService get _firestoreService => FirestoreService();

  @override
  void dispose() {
    _schoolNameController.dispose();
    _countyController.dispose();
    _principalNameController.dispose();
    _phoneController.dispose();
    _loginIdentifierController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
      if (_isLoginMode) {
        final String? resolvedEmail = await _firestoreService
            .resolveEmailFromIdentifier(_loginIdentifierController.text);
        if (resolvedEmail == null) {
          throw Exception('No account was found for that email or phone number.');
        }

        await _authService.signIn(
          email: resolvedEmail,
          password: _passwordController.text,
        );
      } else {
        final credential = await _authService.register(
          email: _emailController.text,
          password: _passwordController.text,
        );

        await _firestoreService.createPrincipalRegistration(
          userId: credential.user!.uid,
          schoolName: _schoolNameController.text.trim(),
          county: _countyController.text.trim(),
          principalName: _principalNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          email: _emailController.text.trim(),
        );

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'School registration submitted. Email verification is optional and can be done later from the account area.',
            ),
          ),
        );
      }
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

  Future<void> _resetPassword() async {
    final String identifier = _loginIdentifierController.text.trim();
    final String? validationError = Validators.loginIdentifier(identifier);
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    final String? resolvedEmail = await _firestoreService
        .resolveEmailFromIdentifier(identifier);
    if (resolvedEmail == null) {
      setState(() {
        _errorMessage = 'No account was found for that email or phone number.';
      });
      return;
    }

    await _authService.sendPasswordResetEmail(resolvedEmail);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password reset email sent to $resolvedEmail.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/branding/school_finance_system.png',
                            width: 132,
                            height: 132,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage school fees, students, and reporting from one place.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (!_isLoginMode) ...<Widget>[
                        TextFormField(
                          controller: _schoolNameController,
                          validator:
                              (value) => Validators.requiredField(
                                value,
                                fieldName: 'School name',
                              ),
                          decoration: const InputDecoration(
                            labelText: 'School name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _countyController,
                          validator:
                              (value) => Validators.requiredField(
                                value,
                                fieldName: 'County',
                              ),
                          decoration: const InputDecoration(
                            labelText: 'County',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _principalNameController,
                          validator:
                              (value) => Validators.requiredField(
                                value,
                                fieldName: 'Principal name',
                              ),
                          decoration: const InputDecoration(
                            labelText: 'Principal name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          validator: Validators.kenyanPhoneNumber,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller:
                            _isLoginMode
                                ? _loginIdentifierController
                                : _emailController,
                        validator:
                            _isLoginMode
                                ? Validators.loginIdentifier
                                : Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText:
                              _isLoginMode ? 'Email or phone number' : 'Email',
                          helperText:
                              _isLoginMode
                                  ? 'Use your email or 07xxxxxxxx / 01xxxxxxxx.'
                                  : 'A verification link will be sent to this email.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        validator: Validators.password,
                        decoration: const InputDecoration(
                          labelText: 'Password',
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
                      const SizedBox(height: 24),
                      if (!_isLoginMode)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'New schools are registered as principal accounts and remain pending until admin approval.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: Text(
                          _isLoginMode
                              ? 'Sign in'
                              : 'Register school as principal',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed:
                            _isSubmitting
                                ? null
                                : () => setState(
                                  () => _isLoginMode = !_isLoginMode,
                                ),
                        child: Text(
                          _isLoginMode
                              ? 'Need an account? Register'
                              : 'Already have an account? Sign in',
                        ),
                      ),
                      if (_isLoginMode)
                        TextButton(
                          onPressed: _isSubmitting ? null : _resetPassword,
                          child: const Text('Forgot password?'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
