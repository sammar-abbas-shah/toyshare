import 'package:flutter/material.dart';

class ToyShareLogo extends StatefulWidget {
  final double size;
  final bool animate;
  final bool white;
  const ToyShareLogo({super.key, this.size = 80, this.animate = true, this.white = false});

  @override
  State<ToyShareLogo> createState() => _ToyShareLogoState();
}

class _ToyShareLogoState extends State<ToyShareLogo> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _bounce = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.animate) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final logo = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: widget.white ? null : const LinearGradient(
          colors: [Color(0xFF5B4FCF), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: widget.white ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(s * 0.28),
        boxShadow: widget.white ? [] : [
          BoxShadow(
            color: const Color(0xFF5B4FCF).withOpacity(0.50),
            blurRadius: 18, offset: const Offset(0, 7), spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(alignment: Alignment.center, children: [
        Positioned(
          top: -s * 0.04, right: -s * 0.04,
          child: Container(
            width: s * 0.5, height: s * 0.5,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), shape: BoxShape.circle),
          ),
        ),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: s * 0.28, height: s * 0.28,
              decoration: BoxDecoration(color: const Color(0xFFFFE066), borderRadius: BorderRadius.circular(s * 0.07)),
              child: Icon(Icons.star_rounded, color: const Color(0xFF5B4FCF), size: s * 0.18),
            ),
            SizedBox(width: s * 0.04),
            Icon(Icons.swap_horiz_rounded, color: Colors.white.withOpacity(0.9), size: s * 0.22),
            SizedBox(width: s * 0.04),
            Container(
              width: s * 0.28, height: s * 0.28,
              decoration: BoxDecoration(color: const Color(0xFF4ECDC4), borderRadius: BorderRadius.circular(s * 0.07)),
              child: Icon(Icons.favorite_rounded, color: Colors.white, size: s * 0.18),
            ),
          ]),
          SizedBox(height: s * 0.06),
          Container(
            padding: EdgeInsets.symmetric(horizontal: s * 0.05, vertical: s * 0.02),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(s * 0.06),
            ),
            child: Text('TOYSHARE', style: TextStyle(
              color: Colors.white, fontSize: s * 0.10,
              fontWeight: FontWeight.w900, letterSpacing: 0.5,
            )),
          ),
        ]),
      ]),
    );
    if (!widget.animate) return logo;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.scale(scale: _bounce.value, child: child),
      child: logo,
    );
  }
}
