import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pinput/pinput.dart';

class PhoneVerificationStepView extends StatefulWidget {
  final String phoneNumber;
  final Function(String otp) onVerify;
  final VoidCallback onResend;
  final VoidCallback onBack;
  final bool isLoading;

  const PhoneVerificationStepView({
    super.key,
    required this.phoneNumber,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
    this.isLoading = false,
  });

  @override
  State<PhoneVerificationStepView> createState() =>
      _PhoneVerificationStepViewState();
}

class _PhoneVerificationStepViewState extends State<PhoneVerificationStepView> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Color.fromRGBO(30, 60, 87, 1),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(234, 239, 243, 1)),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFFE31C5F)),
      borderRadius: BorderRadius.circular(12),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: const Color.fromRGBO(234, 239, 243, 1),
      ),
    );

    return Column(
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
                'Confirm your number',
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

        Text(
          'Enter the code we sent over SMS to ${widget.phoneNumber}:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 32),

        // Pinput
        Pinput(
          length: 6,
          controller: _otpController,
          focusNode: _focusNode,
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: focusedPinTheme,
          submittedPinTheme: submittedPinTheme,
          onCompleted: (pin) => widget.onVerify(pin),
          pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
          showCursor: true,
        ),

        const SizedBox(height: 32),

        // Verify Button
        ElevatedButton(
          onPressed: widget.isLoading
              ? null
              : () {
                  if (_otpController.text.length == 6) {
                    widget.onVerify(_otpController.text);
                  }
                },
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

        // Resend Code
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't get a code? ",
              style: TextStyle(color: Colors.grey[600]),
            ),
            TextButton(
              onPressed: widget.onResend,
              child: const Text(
                'Send again',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }
}
