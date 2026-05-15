import 'package:flutter/material.dart';

Future<T?> navigateTo<T>(BuildContext context, Widget page) =>
    Navigator.push<T>(context, _SlideUpRoute(page: page));

Future<T?> navigateReplace<T>(BuildContext context, Widget page) =>
    Navigator.pushReplacement(context, _FadeRoute(page: page));

class _SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  _SlideUpRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final tween = Tween(begin: const Offset(0.0, 0.04), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(opacity: animation.drive(fadeTween), child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
        );
}

class _FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  _FadeRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        );
}
