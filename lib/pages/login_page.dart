import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../styles/login_styles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AnimationController _floatController;
  late final AnimationController _cardController;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _cardScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _cardOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _cardController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _floatController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email is required';
    }

    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Login button clicked')));
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: LoginStyles.pageBackground,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final double t = _floatController.value * 2 * math.pi;

            return Stack(
              children: [
                _buildAnimatedGlow(
                  top: -90 + math.sin(t) * 35,
                  left: -80 + math.cos(t * 0.9) * 40,
                  size: 260,
                  color: LoginStyles.primaryColor.withOpacity(0.13),
                ),
                _buildAnimatedGlow(
                  top: 90 + math.cos(t * 1.2) * 30,
                  right: -120 + math.sin(t * 1.1) * 45,
                  size: 220,
                  color: LoginStyles.secondaryColor.withOpacity(0.10),
                ),
                _buildAnimatedGlow(
                  bottom: -120 + math.cos(t * 0.8) * 35,
                  right: -70 + math.sin(t * 1.4) * 30,
                  size: 300,
                  color: LoginStyles.accentPink.withOpacity(0.09),
                ),
                _buildAnimatedGlow(
                  bottom: 120 + math.sin(t * 1.3) * 25,
                  left: 120 + math.cos(t) * 30,
                  size: 140,
                  color: LoginStyles.primaryColor.withOpacity(0.08),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: FadeTransition(
                      opacity: _cardOpacity,
                      child: ScaleTransition(
                        scale: _cardScale,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isMobile ? 320 : 350,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 22 : 28,
                              vertical: isMobile ? 24 : 30,
                            ),
                            decoration: LoginStyles.cardDecoration,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Center(
                                    child: Text(
                                      'LOGIN',
                                      style: LoginStyles.titleStyle,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  const Text(
                                    'Email',
                                    style: LoginStyles.labelStyle,
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: LoginStyles.inputTextStyle,
                                    validator: _validateEmail,
                                    decoration: LoginStyles.inputDecoration(
                                      hintText: 'Enter your email',
                                      prefixIcon: Icons.mail_outline_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'Password',
                                    style: LoginStyles.labelStyle,
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: LoginStyles.inputTextStyle,
                                    validator: _validatePassword,
                                    decoration:
                                        LoginStyles.inputDecoration(
                                          hintText: 'Enter your password',
                                          prefixIcon:
                                              Icons.lock_outline_rounded,
                                        ).copyWith(
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: LoginStyles.textSecondary,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                  ),
                                  const SizedBox(height: 28),
                                  SizedBox(
                                    width: double.infinity,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: LoginStyles.primaryColor
                                                .withOpacity(0.28),
                                            blurRadius: 24,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleLogin,
                                        style: LoginStyles.loginButtonStyle,
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Color(0xFF07111F),
                                                    ),
                                              )
                                            : const Text(
                                                'Login',
                                                style:
                                                    LoginStyles.buttonTextStyle,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedGlow({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color, blurRadius: 100, spreadRadius: 20),
            ],
          ),
        ),
      ),
    );
  }
}
