import 'package:flutter/material.dart';
import 'dart:async';

class AutoScroller extends StatefulWidget {
  const AutoScroller({
    super.key,
    required this.child,
    this.initialDelay = const Duration(seconds: 30),
    this.scrollDuration = const Duration(seconds: 60),
    this.enableAutoScroll = true,
  });

  final Widget child;
  final Duration initialDelay;
  final Duration scrollDuration;
  final bool enableAutoScroll;

  @override
  State<AutoScroller> createState() => _AutoScrollerState();
}

class _AutoScrollerState extends State<AutoScroller> {
final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    
    // Only set up auto-scrolling if it's enabled
    if (widget.enableAutoScroll) {
      Future.delayed(const Duration(seconds: 3), _setupAutoScroll);
    }
  }

  void _setupAutoScroll() {
    // Start a timer to begin scrolling after the initial delay
    _scrollTimer = Timer(widget.initialDelay, _startScrolling);
  }

  void _startScrolling() {
    if (!mounted || _scrollController.positions.isEmpty) return;
    
    setState(() {
      _isScrolling = true;
    });
    
    // Calculate the maximum scroll extent
    final maxScroll = _scrollController.position.maxScrollExtent;
    
    // Animate to the bottom over the specified duration
    _scrollController.animateTo(
      maxScroll,
      duration: widget.scrollDuration,
      curve: Curves.linear,
    );

    // track scrolling status
    _scrollController.addListener(() {
      if (_scrollController.offset >= maxScroll) {
        _scrollTimer?.cancel();
        setState(() {
          _isScrolling = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(AutoScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle changes to enableAutoScroll property during widget lifetime
    if (widget.enableAutoScroll != oldWidget.enableAutoScroll) {
      if (widget.enableAutoScroll) {
        // Auto-scroll was enabled, set it up
        _setupAutoScroll();
      } else {
        // Auto-scroll was disabled, cancel any pending timer
        _scrollTimer?.cancel();
        _scrollTimer = null;
        
        // Stop current scrolling animation if in progress
        if (_isScrolling) {
          _scrollController.jumpTo(_scrollController.offset);
          setState(() {
            _isScrolling = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main scrollable content
        SingleChildScrollView(
          controller: _scrollController,
          child: widget.child,
        ),

        // // Optional indicator showing scrolling status - only shown if auto-scrolling is enabled and active
        // if (_isScrolling && widget.enableAutoScroll)
        //Positioned(
        //  bottom: 16,
        //  right: 16,
        //  child: Container(
        //    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //    decoration: BoxDecoration(
        //      color: Colors.black.withValues(alpha: 200),
        //      borderRadius: BorderRadius.circular(20),
        //    ),
        //    child: const Text(
        //      'Auto-scrolling',
        //      style: TextStyle(color: Colors.white),
        //    ),
        //  ),
        //),
      ],
    ); 
  }
}
