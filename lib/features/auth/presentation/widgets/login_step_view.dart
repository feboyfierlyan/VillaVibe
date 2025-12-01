import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginStepView extends ConsumerStatefulWidget {
  final Function(String email) onContinue;
  final Function(String phoneNumber) onPhoneContinue;
  final VoidCallback onGoogleSignIn;

  final bool isLoading;

  const LoginStepView({
    super.key,
    required this.onContinue,
    required this.onPhoneContinue,
    required this.onGoogleSignIn,

    this.isLoading = false,
  });

  @override
  ConsumerState<LoginStepView> createState() => _LoginStepViewState();
}

class _LoginStepViewState extends ConsumerState<LoginStepView> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Country _selectedCountry = Country(
    phoneCode: '62',
    countryCode: 'ID',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Indonesia',
    example: '81234567890',
    displayName: 'Indonesia',
    displayNameNoCountryCode: 'Indonesia',
    e164Key: '',
  );

  bool _isPhoneAuth = true;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_isPhoneAuth) {
        String phoneNumber = _phoneController.text.trim();
        
        // Remove any non-digit characters (spaces, dashes, parens)
        // EXCEPT for the leading '+' if they typed it
        phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

        // If they typed the country code (starts with +), use it as is
        if (!phoneNumber.startsWith('+')) {
          // If it starts with '0', replace it with '+62' (Indonesia default)
          if (phoneNumber.startsWith('0')) {
            phoneNumber = '+62${phoneNumber.substring(1)}';
          } else {
            // If no leading 0 and no +, assume it's a local number without 0, prepend +62
            phoneNumber = '+62$phoneNumber';
          }
        }
        
        widget.onPhoneContinue(phoneNumber);
      } else {
        widget.onContinue(_emailController.text.trim());
      }
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isPhoneAuth = !_isPhoneAuth;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input Fields
          if (_isPhoneAuth) _buildPhoneInput() else _buildEmailInput(),

          const SizedBox(height: 16),

          // Disclaimer
          Text(
            _isPhoneAuth
                ? 'We\'ll call or text to confirm your number. Standard message and data rates apply.'
                : 'We\'ll email you to confirm your address.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
          ),

          const SizedBox(height: 24),

          // Continue Button
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
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),

          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('or', style: TextStyle(color: Colors.grey[600])),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 24),

          // Social Buttons
          _buildSocialButtons(),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: _phoneController,
        decoration: const InputDecoration(
          hintText: 'Phone number (e.g. 0812...)',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
          prefixIcon: Icon(Icons.phone_outlined, size: 20),
          prefixIconConstraints: BoxConstraints(minWidth: 40),
        ),
        keyboardType: TextInputType.phone,
        style: const TextStyle(fontSize: 16),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your phone number';
          }
          return null;
        },
        onFieldSubmitted: (_) => _submit(),
      ),
    );
  }

  Widget _buildEmailInput() {
    return Container(
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
        controller: _emailController,
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: const Icon(Icons.email_outlined, size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(fontSize: 16),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!value.contains('@')) {
            return 'Please enter a valid email';
          }
          return null;
        },
        onFieldSubmitted: (_) => _submit(),
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        if (_isPhoneAuth)
          _SocialButton(
            icon: Icons.email_outlined,
            label: 'Continue with email',
            onTap: _toggleAuthMode,
          )
        else
          _SocialButton(
            icon: Icons.phone_android,
            label: 'Continue with Phone',
            onTap: _toggleAuthMode,
          ),
        const SizedBox(height: 16),
        _SocialButton(
          icon: FontAwesomeIcons.google,
          label: 'Continue with Google',
          onTap: widget.onGoogleSignIn,
          iconColor: Colors.black,
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? Colors.black87),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 20), // Balance icon
          ],
        ),
      ),
    );
  }
}
