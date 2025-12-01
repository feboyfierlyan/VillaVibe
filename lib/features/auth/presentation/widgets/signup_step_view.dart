import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class SignupStepView extends StatefulWidget {
  final String email;
  final Function(
          String firstName, String lastName, DateTime dob, String password)
      onSignup;
  final bool isLoading;
  final VoidCallback onBack;

  const SignupStepView({
    super.key,
    required this.email,
    required this.onSignup,
    required this.onBack,
    this.isLoading = false,
  });

  @override
  State<SignupStepView> createState() => _SignupStepViewState();
}

class _SignupStepViewState extends State<SignupStepView> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  bool _marketingAgreed = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      widget.onSignup(
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _selectedDate!,
        _passwordController.text.trim(),
      );
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your birthdate')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE31C5F),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 24,
              ),
              Expanded(
                child: Text(
                  'Finish signing up',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 24), // Balance back button
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Legal Name
          const Text(
            'Legal name',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First name on ID',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    style: const TextStyle(fontSize: 16),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                Divider(height: 1, color: Colors.grey[200]),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last name on ID',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    style: const TextStyle(fontSize: 16),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure this matches the name on your government ID.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),

          const SizedBox(height: 24),

          // Date of Birth
          const Text(
            'Date of birth',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Birthdate'
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      style: TextStyle(
                        color: _selectedDate == null
                            ? Colors.grey[600]
                            : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'To sign up, you need to be at least 18. Your birthday won\'t be shared with other people who use Airbnb.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),

          const SizedBox(height: 24),

          // Email (Read-only)
          const Text(
            'Email',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100], // Keep slightly grey for read-only
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextFormField(
              initialValue: widget.email,
              readOnly: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined, size: 20),
                prefixIconConstraints: BoxConstraints(minWidth: 40),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll email you trip confirmations and receipts.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),

          const SizedBox(height: 24),

          // Password
          const Text(
            'Password',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                suffixIcon: TextButton(
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                  child: Text(
                    _showPassword ? 'Hide' : 'Show',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              style: const TextStyle(fontSize: 16),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'By selecting Agree and continue, I agree to Airbnb\'s Terms of Service, Payments Terms of Service and Nondiscrimination Policy and acknowledge the Privacy Policy.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),

          const SizedBox(height: 24),

          // Agree and Continue Button
          ElevatedButton(
            onPressed: widget.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31C5F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Agree and continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Checkbox(
                value: _marketingAgreed,
                onChanged: (val) {
                  setState(() {
                    _marketingAgreed = val ?? false;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: const Color(0xFFE31C5F),
              ),
              Expanded(
                child: Text(
                  'I don\'t want to receive marketing messages from Airbnb.',
                  style: TextStyle(color: Colors.grey[800], fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
    );
  }
}
