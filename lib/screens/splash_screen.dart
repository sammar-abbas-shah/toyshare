import 'package:flutter/material.dart';
import '../widgets/toyshare_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late String _tagline;

  static const _taglines = [
    'Share joy, one toy at a time',
    'Every toy deserves a second adventure',
    'Giving toys a new home, one child at a time',
    'Where toys find new friends',
    'Sharing smiles, one toy at a time',
    'Less clutter, more laughter',
    'Your unused toy is someone\'s treasure',
    'Building community through play',
  ];

  @override
  void initState() {
    super.initState();
    _tagline = _taglines[DateTime.now().millisecondsSinceEpoch % _taglines.length];
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _logoOpacity = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _textOpacity = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _textSlide = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: const Offset(0, 0.4), end: Offset.zero));
    _logoCtrl.forward().then((_) => _textCtrl.forward());
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) Navigator.of(context).pushReplacementNamed('/auth');
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Widget _circle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3D32A8), Color(0xFF5B4FCF), Color(0xFF7B6FE8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(children: [
          Positioned(top: -60, right: -60, child: _circle(200, Colors.white.withOpacity(0.05))),
          Positioned(bottom: -80, left: -80, child: _circle(280, Colors.white.withOpacity(0.05))),
          Positioned(top: 120, left: -40, child: _circle(100, Colors.white.withOpacity(0.04))),
          Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Center(child: ToyShareLogo(size: 72, animate: false, white: true)),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: Column(children: [
                    const Text('ToyShare',
                      style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1)),
                    const SizedBox(height: 6),
                    Text(_tagline,
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 15)),
                  ]),
                ),
              ),
            ]),
          ),
          Positioned(
            bottom: 48, left: 0, right: 0,
            child: FadeTransition(
              opacity: _textOpacity,
              child: const Center(
                child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
