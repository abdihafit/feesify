import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../models/class_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state.dart';

class ClassSetupScreen extends StatefulWidget {
  const ClassSetupScreen({
    super.key,
    required this.schoolId,
    this.readOnly = false,
  });

  final String schoolId;
  final bool readOnly;

  @override
  State<ClassSetupScreen> createState() => _ClassSetupScreenState();
}

class _ClassSetupScreenState extends State<ClassSetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _streamController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedClass = AppConstants.schoolClassLevels.first;
  bool _isSubmitting = false;
  String? _editingClassId;
  String? _errorMessage;

  @override
  void dispose() {
    _streamController.dispose();
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
      if (_editingClassId == null) {
        await _firestoreService.createClassStream(
          schoolId: widget.schoolId,
          name: _selectedClass,
          stream: _streamController.text.trim(),
        );
      } else {
        await _firestoreService.updateClassStream(
          classId: _editingClassId!,
          schoolId: widget.schoolId,
          name: _selectedClass,
          stream: _streamController.text.trim(),
        );
      }

      _resetForm();
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

  void _startEditing(ClassModel classModel) {
    setState(() {
      _editingClassId = classModel.id;
      _selectedClass = classModel.name;
      _streamController.text = classModel.stream;
      _errorMessage = null;
    });
  }

  void _resetForm() {
    if (!mounted) {
      return;
    }

    setState(() {
      _editingClassId = null;
      _selectedClass = AppConstants.schoolClassLevels.first;
      _streamController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        DashboardCard(
          title: 'School Classes Setup',
          subtitle:
              widget.readOnly
                  ? 'View configured streams for each class level in this school.'
                  : 'Add and manage streams for each class level in this school.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: _selectedClass,
                  items:
                      AppConstants.schoolClassLevels
                          .map(
                            (classLevel) => DropdownMenuItem<String>(
                              value: classLevel,
                              child: Text(classLevel),
                            ),
                          )
                          .toList(),
                  onChanged:
                      widget.readOnly
                          ? null
                          : (value) {
                            if (value != null) {
                              setState(() => _selectedClass = value);
                            }
                          },
                  decoration: const InputDecoration(labelText: 'Class level'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _streamController,
                  enabled: !widget.readOnly,
                  validator:
                      (value) =>
                          Validators.requiredField(value, fieldName: 'Stream'),
                  decoration: const InputDecoration(
                    labelText: 'Stream name',
                    hintText: 'East, West, North',
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
                if (widget.readOnly)
                  const Text(
                    'Read-only mode: principals can review class streams here, while bursars handle day-to-day updates.',
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: Text(
                          _isSubmitting
                              ? 'Saving...'
                              : _editingClassId == null
                              ? 'Add Stream'
                              : 'Update Stream',
                        ),
                      ),
                      if (_editingClassId != null)
                        OutlinedButton(
                          onPressed: _isSubmitting ? null : _resetForm,
                          child: const Text('Cancel Edit'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Class Streams', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        StreamBuilder<List<ClassModel>>(
          stream: _firestoreService.streamClasses(widget.schoolId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final List<ClassModel> classes = snapshot.data ?? <ClassModel>[];
            if (classes.isEmpty) {
              return const EmptyState(
                icon: Icons.class_outlined,
                title: 'No classes configured',
                message:
                    'Add class streams like Form Three East or Grade 10 North to get started.',
              );
            }

            final Map<String, List<ClassModel>> groupedClasses =
                <String, List<ClassModel>>{};

            // Group each stream under its class level for a cleaner setup view.
            for (final ClassModel classModel in classes) {
              groupedClasses.putIfAbsent(classModel.name, () => <ClassModel>[]);
              groupedClasses[classModel.name]!.add(classModel);
            }

            return Column(
              children:
                  AppConstants.schoolClassLevels
                      .where(
                        (classLevel) => groupedClasses.containsKey(classLevel),
                      )
                      .map(
                        (classLevel) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DashboardCard(
                            title: classLevel,
                            subtitle:
                                '${groupedClasses[classLevel]!.length} stream(s) configured',
                            child: Column(
                              children:
                                  groupedClasses[classLevel]!
                                      .map(
                                        (classModel) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            '${classModel.name} ${classModel.stream}',
                                          ),
                                          subtitle: Text(
                                            'Stream: ${classModel.stream}',
                                          ),
                                          trailing:
                                              widget.readOnly
                                                  ? const Icon(
                                                    Icons.visibility_outlined,
                                                  )
                                                  : Wrap(
                                                    spacing: 8,
                                                    children: <Widget>[
                                                      IconButton(
                                                        tooltip: 'Edit stream',
                                                        onPressed:
                                                            () => _startEditing(
                                                              classModel,
                                                            ),
                                                        icon: const Icon(
                                                          Icons.edit_outlined,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip:
                                                            'Delete stream',
                                                        onPressed: () async {
                                                          await _firestoreService
                                                              .deleteClassStream(
                                                                classModel.id,
                                                              );

                                                          if (!context
                                                              .mounted) {
                                                            return;
                                                          }

                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                '${classModel.name} ${classModel.stream} deleted.',
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.delete_outline,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                        ),
                                      )
                                      .toList(),
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
