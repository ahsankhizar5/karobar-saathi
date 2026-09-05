/// Sweep-of-light shimmer for loading placeholders — the app's standard
/// loading treatment instead of circular spinners.
library;

import 'package:flutter/material.dart';

/// Wraps [child] in an endlessly sweeping highlight band.
///
/// The child should be opaque placeholder blocks (e.g. [ShimmerBox]) shaped
/// like the content that is loading.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color base = scheme.surfaceContainerHighest;
    final Color highlight =
        Theme.of(context).brightness == Brightness.dark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerLowest;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            final double dx =
                _controller.value * bounds.width * 2 - bounds.width * 0.5;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[base, highlight, base],
              stops: const <double>[0.35, 0.5, 0.65],
            ).createShader(bounds.translate(dx, 0));
          },
          child: child,
        );
      },
    );
  }
}

/// One rounded placeholder block. Stack several to sketch the shape of the
/// content that is loading.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, this.width, this.height = 14, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Small pulsing dot used inside buttons during an in-flight operation.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, this.size = 10, this.color});

  final double size;
  final Color? color;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.color ?? Theme.of(context).colorScheme.onPrimary;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
