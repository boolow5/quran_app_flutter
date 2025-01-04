import 'package:flutter/material.dart';

class AnimatedGradientCard extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const AnimatedGradientCard({
    Key? key,
    required this.child,
    this.colors = const [
      Colors.purple,
      Colors.blue,
      Colors.cyan,
      Colors.green,
    ],
    this.duration = const Duration(seconds: 3),
    this.borderRadius,
    this.padding,
  }) : super(key: key);

  @override
  State<AnimatedGradientCard> createState() => _AnimatedGradientCardState();
}

class _AnimatedGradientCardState extends State<AnimatedGradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Color> get colors => widget.colors;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
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
        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(15),
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
                stops: List.generate(
                  colors.length,
                  (index) => (index / colors.length + _controller.value) % 1.0,
                ),
              ),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Example usage
/*
class ExampleGradientCard extends StatelessWidget {
  const ExampleGradientCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AnimatedGradientCard(
            // Custom colors example
            colors: const [
              Color(0xFF6B8DE3),
              Color(0xFF7C51CD),
              Color(0xFF6B8DE3),
              Color(0xFF7C51CD),
            ],
            duration: const Duration(seconds: 5),
            padding: const EdgeInsets.all(16.0),
            child: const SizedBox(
              width: double.infinity,
              height: 200,
              child: Center(
                child: Text(
                  'Animated Gradient Card',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} */
