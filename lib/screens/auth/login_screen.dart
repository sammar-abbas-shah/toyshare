import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../core/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/toyshare_logo.dart';

final _auth = fb_auth.FirebaseAuth.instance;

class AppIcons {
  static const person = null;
  static const email = null;
  static const password = null;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _showPassword = false;

  late AnimationController _fadeCtrl, _slideCtrl, _cardCtrl;
  late Animation<double> _fadeAnim, _cardFade;
  late Animation<Offset> _slideAnim, _cardSlide;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150), () { if (mounted) _slideCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _cardCtrl.forward(); });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose(); _slideCtrl.dispose(); _cardCtrl.dispose();
    _emailCtrl.dispose(); _passwordCtrl.dispose(); _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
      } else {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
        await cred.user?.updateDisplayName(_usernameCtrl.text.trim());
        await cred.user?.reload();
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      if (mounted) _showError(_friendlyAuthError(e.code));
    } catch (e) {
      if (mounted) _showError('An error occurred. Please try again.');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found for this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'invalid-credential': return 'Invalid email or password.';
      case 'email-already-in-use': return 'An account already exists with this email.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'too-many-requests': return 'Too many attempts. Please try again later.';
      default: return 'Authentication failed. Please try again.';
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: AppColors.error,
      margin: const EdgeInsets.all(14),
    ));
  }

  void _toggleMode() {
    setState(() { _isLogin = !_isLogin; _formKey.currentState?.reset(); });
    _cardCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF3D32A8), Color(0xFF5B4FCF), Color(0xFF7B55D4)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(children: [
                    SlideTransition(
                      position: _slideAnim,
                      child: Column(children: [
                        const ToyShareLogo(size: 86),
                        const SizedBox(height: 18),
                        const Text('ToyShare', style: TextStyle(
                          color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        const SizedBox(height: 5),
                        Text('Share joy, one toy at a time',
                          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14)),
                      ]),
                    ),
                    const SizedBox(height: 40),
                    SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.22),
                              blurRadius: 48, offset: const Offset(0, 20), spreadRadius: -10)],
                          ),
                          padding: const EdgeInsets.all(28),
                          child: Form(
                            key: _formKey,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_isLogin ? 'Welcome back!' : 'Create account',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                                  letterSpacing: -0.7, color: AppColors.textPrimary)),
                              const SizedBox(height: 3),
                              Text(_isLogin ? 'Sign in to continue sharing' : 'Join your neighborhood toy circle',
                                style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                              const SizedBox(height: 24),
                              if (!_isLogin) ...[
                                AppTextField(
                                  controller: _usernameCtrl,
                                  label: 'Username',
                                  prefixIcon: Icons.person_rounded,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a username' : null,
                                ),
                                const SizedBox(height: 14),
                              ],
                              AppTextField(
                                controller: _emailCtrl,
                                label: 'Email',
                                prefixIcon: Icons.email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your email'
                                    : (!v.contains('@') ? 'Enter a valid email' : null),
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                controller: _passwordCtrl,
                                label: 'Password',
                                prefixIcon: Icons.lock_rounded,
                                obscureText: !_showPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 20, color: AppColors.textSecondary),
                                  onPressed: () => setState(() => _showPassword = !_showPassword),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? 'Enter your password'
                                    : (v.length < 6 ? 'Password must be at least 6 characters' : null),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    minimumSize: const Size(double.infinity, 54), elevation: 0),
                                  child: _isLoading
                                      ? const SizedBox(width: 22, height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                      : Text(_isLogin ? 'Sign In' : 'Create Account',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton(
                                  onPressed: _toggleMode,
                                  child: RichText(text: TextSpan(
                                    style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                                    children: [
                                      TextSpan(text: _isLogin ? "Don't have an account? " : 'Already have an account? '),
                                      TextSpan(text: _isLogin ? 'Sign up' : 'Sign in',
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                                    ],
                                  )),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
