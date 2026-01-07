import 'package:flutter/material.dart';

/// Direction for slide transition
enum SlideDirection {
  fromRight,
  fromLeft,
  fromBottom,
  fromTop,
}

/// Custom page route with slide and fade transition
///
/// Provides smooth slide+fade animations for screen transitions.
/// Default: 300ms slide from right with easeInOutCubic curve.
/// Works with iOS back swipe gesture and Android back button.
class SlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;
  final Duration duration;
  final Curve curve;

  SlideRoute({
    required this.page,
    this.direction = SlideDirection.fromRight,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          settings: settings,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Calculate slide offset based on direction
            Offset begin;
            switch (direction) {
              case SlideDirection.fromRight:
                begin = const Offset(1.0, 0.0);
                break;
              case SlideDirection.fromLeft:
                begin = const Offset(-1.0, 0.0);
                break;
              case SlideDirection.fromBottom:
                begin = const Offset(0.0, 1.0);
                break;
              case SlideDirection.fromTop:
                begin = const Offset(0.0, -1.0);
                break;
            }

            const end = Offset.zero;

            // Slide animation
            final slideTween = Tween(begin: begin, end: end);
            final slideAnimation = animation.drive(
              slideTween.chain(CurveTween(curve: curve)),
            );

            // Fade animation
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
            final fadeAnimation = animation.drive(
              fadeTween.chain(CurveTween(curve: curve)),
            );

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Fade-only route transition (no slide)
///
/// Useful for modal screens or overlays where slide doesn't make sense
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;

  FadeRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeInOut,
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          settings: settings,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
            final fadeAnimation = animation.drive(
              fadeTween.chain(CurveTween(curve: curve)),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
        );
}
