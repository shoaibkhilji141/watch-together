import 'package:flutter/material.dart';

/// Subtle skeleton shimmer over the video area while loading.
class VideoShimmer extends StatefulWidget {
  const VideoShimmer({super.key});

  @override
  State<VideoShimmer> createState() => _VideoShimmerState();
}

class _VideoShimmerState extends State<VideoShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + _controller.value * 2, 0),
              end: Alignment(-0.5 + _controller.value * 2, 0),
              colors: const [
                Color(0xFF1A1A1A),
                Color(0xFF2E2E2E),
                Color(0xFF1A1A1A),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: Container(
        color: const Color(0xFF141414),
      ),
    );
  }
}
