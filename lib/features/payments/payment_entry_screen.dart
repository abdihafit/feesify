import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/validators.dart';
import '../../models/payment_model.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/receipt_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state.dart';

class PaymentEntryScreen extends StatefulWidget {
  const PaymentEntryScreen({
    super.key,
    required this.schoolId,
    required this.bursar,
    this.readOnly = false,
  });

  final String schoolId;
  final UserModel bursar;
  final bool readOnly;

  @override
  State<PaymentEntryScreen> createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends State<PaymentEntryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _admissionNumberController =
      TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _referenceNumberController =
      TextEditingController();
  final TextEditingController _receivedByController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final ReceiptService _receiptService = ReceiptService();

  DateTime _selectedDate = DateTime.now();
  String _selectedMethod = 'Cash';
  String _admissionQuery = '';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _receivedByController.text = widget.bursar.name;
    _amountPaidController.addListener(_refreshAmountPreview);
  }

  void _refreshAmountPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _amountPaidController.removeListener(_refreshAmountPreview);
    _dateController.dispose();
    _admissionNumberController.dispose();
    _amountPaidController.dispose();
    _referenceNumberController.dispose();
    _receivedByController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    });
  }

  double _enteredAmount() {
    return double.tryParse(_amountPaidController.text.trim()) ?? 0;
  }

  Future<void> _submit(StudentModel student) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double amountPaid = _enteredAmount();
    if (amountPaid <= 0) {
      setState(() {
        _errorMessage = 'Enter a valid amount paid.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final PaymentModel payment = await _firestoreService.recordPayment(
        student: student,
        schoolId: widget.schoolId,
        paymentDate: _selectedDate,
        method: _selectedMethod,
        amountPaid: amountPaid,
        referenceNumber: _referenceNumberController.text.trim(),
        receivedBy: _receivedByController.text.trim(),
      );

      final StudentModel updatedStudent = StudentModel(
        id: student.id,
        admissionNumber: student.admissionNumber,
        fullName: student.fullName,
        schoolId: student.schoolId,
        classId: student.classId,
        className: student.className,
        streamName: student.streamName,
        guardianName: student.guardianName,
        guardianPhone: student.guardianPhone,
        termFee: student.termFee,
        previousBalance: student.previousBalance,
        totalPaid: student.totalPaid + amountPaid,
        totalExpectedFee: student.totalExpectedFee,
        totalFees: student.totalFees,
        balance: payment.newBalance,
        createdAt: student.createdAt,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Payment Recorded'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Previous Balance: ${CurrencyFormatter.formatAmount(payment.previousBalance)}',
                  ),
                  Text(
                    'Amount Paid: ${CurrencyFormatter.formatAmount(payment.amount)}',
                  ),
                  Text(
                    'New Balance: ${CurrencyFormatter.formatAmount(payment.newBalance)}',
                  ),
                  Text('Receipt Number: ${payment.receiptNumber}'),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    await _receiptService.downloadReceipt(
                      payment: payment,
                      student: updatedStudent,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Download Receipt'),
                ),
                TextButton(
                  onPressed: () async {
                    await _receiptService.printReceipt(
                      payment: payment,
                      student: updatedStudent,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Print Receipt'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
      );

      _referenceNumberController.clear();
      _amountPaidController.clear();
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
          title: 'Payment Entry',
          subtitle:
              widget.readOnly
                  ? 'Review the bursar payment workflow, receipt confirmation, and balance impact without saving changes.'
                  : 'Record a student payment and automatically update the running balance.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _dateController,
                  enabled: !widget.readOnly,
                  readOnly: true,
                  onTap: widget.readOnly ? null : _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _admissionNumberController,
                  enabled: !widget.readOnly,
                  onChanged: (value) {
                    setState(() => _admissionQuery = value.trim());
                  },
                  validator:
                      (value) => Validators.requiredField(
                        value,
                        fieldName: 'Admission number',
                      ),
                  decoration: const InputDecoration(
                    labelText: 'Admission number',
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<StudentModel?>(
                  stream:
                      _admissionQuery.isEmpty
                          ? null
                          : _firestoreService.streamStudentByAdmissionNumber(
                            schoolId: widget.schoolId,
                            admissionNumber: _admissionQuery,
                          ),
                  builder: (context, snapshot) {
                    final StudentModel? student = snapshot.data;
                    final double amountPaid = _enteredAmount();
                    final double projectedBalance =
                        student == null
                            ? 0
                            : (student.balance - amountPaid).clamp(
                              0,
                              double.infinity,
                            );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_admissionQuery.isNotEmpty &&
                            snapshot.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: LinearProgressIndicator(),
                          ),
                        if (_admissionQuery.isNotEmpty &&
                            snapshot.connectionState !=
                                ConnectionState.waiting &&
                            student == null)
                          Text(
                            'Student not found for that admission number.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        if (student != null) ...<Widget>[
                          DashboardCard(
                            title: student.fullName,
                            subtitle:
                                '${student.className} ${student.streamName}',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _PaymentPreviewRow(
                                  label: 'Student auto-selected',
                                  value: student.fullName,
                                ),
                                _PaymentPreviewRow(
                                  label: 'Current balance',
                                  value: CurrencyFormatter.formatAmount(
                                    student.balance,
                                  ),
                                ),
                                if (amountPaid > 0)
                                  _PaymentPreviewRow(
                                    label: 'Projected new balance',
                                    value: CurrencyFormatter.formatAmount(
                                      projectedBalance.toDouble(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        DropdownButtonFormField<String>(
                          initialValue: _selectedMethod,
                          items:
                              const <String>['Cash', 'Bank', 'M-Pesa', 'Cheque']
                                  .map(
                                    (method) => DropdownMenuItem<String>(
                                      value: method,
                                      child: Text(method),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              widget.readOnly
                                  ? null
                                  : (value) {
                                    if (value != null) {
                                      setState(() => _selectedMethod = value);
                                    }
                                  },
                          decoration: const InputDecoration(
                            labelText: 'Payment method',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountPaidController,
                          enabled: !widget.readOnly,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator:
                              (value) => Validators.requiredField(
                                value,
                                fieldName: 'Amount paid',
                              ),
                          decoration: const InputDecoration(
                            labelText: 'Amount paid',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _referenceNumberController,
                          enabled: !widget.readOnly,
                          validator:
                              (value) => Validators.requiredField(
                                value,
                                fieldName: 'Reference number',
                              ),
                          decoration: const InputDecoration(
                            labelText: 'Reference number',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _receivedByController,
                          enabled: !widget.readOnly,
                          validator:
                              (value) => Validators.requiredField(
                                value,
                                fieldName: 'Received by',
                              ),
                          decoration: const InputDecoration(
                            labelText: 'Received by',
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
                            'Read-only mode: inspect the payment entry workflow here.',
                          )
                        else
                          FilledButton(
                            onPressed:
                                _isSubmitting || student == null
                                    ? null
                                    : () => _submit(student),
                            child: Text(
                              _isSubmitting
                                  ? 'Saving Payment...'
                                  : 'Save Payment',
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const EmptyState(
          icon: Icons.receipt_outlined,
          title: 'Receipt confirmation',
          message:
              'After saving a payment, the app will show previous balance, amount paid, new balance, receipt number, and receipt actions.',
        ),
      ],
    );
  }
}

class _PaymentPreviewRow extends StatelessWidget {
  const _PaymentPreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
