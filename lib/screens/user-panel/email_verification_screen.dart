import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart' as routes;

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String purpose; // 'password_reset' or 'signup'
  final Map<String, dynamic>? signupData; // Only needed for signup

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.purpose,
    this.signupData,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _codeControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  String? _errorMessage;
  bool _isCodeSent = false;
  int _resendCountdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sendVerificationCode();
  }

  @override
  void dispose() {
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Check if the email exists for password reset
      if (widget.purpose == 'password_reset') {
        final userExists = await authProvider.checkUserExists(widget.email);
        if (!userExists) {
          throw Exception('No account found with this email address');
        }
        await authProvider.sendVerificationCode(widget.email,
            isPasswordReset: true);
      } else {
        await authProvider.sendVerificationCode(widget.email,
            isPasswordReset: false);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isCodeSent = true;
          _resendCountdown = 60; // 60 seconds countdown
        });

        // Start countdown timer
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_resendCountdown > 0) {
            setState(() {
              _resendCountdown--;
            });
          } else {
            timer.cancel();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    final message = error.toString();
    if (message.contains('No account found')) {
      return 'No account found with this email address';
    } else if (message.contains('already exists')) {
      return 'An account already exists with this email address';
    }
    return 'Error: ${message.replaceAll('Exception: ', '')}';
  }

  Future<void> _verifyCode() async {
    final enteredCode = _codeControllers.map((c) => c.text).join();

    if (enteredCode.length != 4) {
      setState(() {
        _errorMessage = 'Please enter all 4 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool isValid = await authProvider.verifyCode(widget.email, enteredCode);

      if (!isValid) {
        throw Exception('Invalid verification code');
      }

      if (mounted) {
        if (widget.purpose == 'password_reset') {
          // Navigate to reset password screen with email
          Navigator.pushReplacementNamed(
            context,
            routes.AppRoutes.resetPassword,
            arguments: widget.email,
          );
        } else if (widget.purpose == 'signup' && widget.signupData != null) {
          // Complete signup with verification
          final data = widget.signupData!;
          await authProvider.signUpWithVerification(
            widget.email,
            data['password'] as String,
            data['name'] as String,
          );
          Navigator.pushReplacementNamed(context, routes.AppRoutes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  Future<void> _resendVerificationEmail(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Email Verification'),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get Your Code',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter the 4 digit code that we sent to your email address ${widget.email}.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),

              // 4-digit input fields with reduced spacing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => Container(
                      width: 70,
                      height: 70,
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _errorMessage != null
                              ? Colors.red
                              : Colors.deepOrange.withOpacity(0.3),
                          width: 1.5,
                        ),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: _codeControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            // Move to next field
                            if (index < 3) {
                              _focusNodes[index + 1].requestFocus();
                            } else {
                              // Last field, hide keyboard
                              FocusScope.of(context).unfocus();
                              // Auto-verify when all fields are filled
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                _verifyCode,
                              );
                            }
                          }
                        },
                        onTap: () {
                          // Clear on tap
                          _codeControllers[index].selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _codeControllers[index].text.length,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Resend code
              Center(
                child: TextButton(
                  onPressed:
                      _resendCountdown == 0 ? _sendVerificationCode : null,
                  child: Text(
                    _resendCountdown > 0
                        ? 'Resend code in $_resendCountdown seconds'
                        : 'Resend',
                    style: TextStyle(
                      color: _resendCountdown > 0
                          ? Colors.grey
                          : Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    disabledBackgroundColor: Colors.deepOrange.withOpacity(0.6),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Verify and Proceed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _resendVerificationEmail(context),
                child: const Text('Resend Verification Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
