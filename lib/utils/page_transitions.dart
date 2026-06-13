import 'package:flutter/material.dart';

/// Custom page route with fade-through transition
class FadeThroughPageRoute<T> extends PageRouteBuilder<T> {
  final Widget Function(BuildContext) builder;

  FadeThroughPageRoute({
    required this.builder,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) {
            return builder(context);
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade through transition
            final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
              ),
            );

            final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
              ),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );
}

/// Custom page route with slide transition
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget Function(BuildContext) builder;
  final AxisDirection direction;

  SlidePageRoute({
    required this.builder,
    this.direction = AxisDirection.right,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) {
            return builder(context);
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset beginOffset;
            switch (direction) {
              case AxisDirection.up:
                beginOffset = const Offset(0, 1);
                break;
              case AxisDirection.down:
                beginOffset = const Offset(0, -1);
                break;
              case AxisDirection.left:
                beginOffset = const Offset(1, 0);
                break;
              case AxisDirection.right:
                beginOffset = const Offset(-1, 0);
                break;
            }

            final slideAnimation = Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return SlideTransition(
              position: slideAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}

/// Extension methods for Navigator to use custom transitions
extension NavigationExtensions on BuildContext {
  /// Navigate with fade-through transition
  Future<T?> pushWithFadeTransition<T>(Widget page, {RouteSettings? settings}) {
    return Navigator.push<T>(
      this,
      FadeThroughPageRoute<T>(
        builder: (_) => page,
        settings: settings,
      ),
    );
  }

  /// Navigate with slide transition
  Future<T?> pushWithSlideTransition<T>(
    Widget page, {
    AxisDirection direction = AxisDirection.right,
    RouteSettings? settings,
  }) {
    return Navigator.push<T>(
      this,
      SlidePageRoute<T>(
        builder: (_) => page,
        direction: direction,
        settings: settings,
      ),
    );
  }
}
