// Onboarding step model
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final TooltipPosition position;
  final GlobalKey targetKey;

  OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.position,
    required this.targetKey,
  });
}

// Tooltip position enum
enum TooltipPosition {
  top,
  right,
  bottom,
  left,
}

// Onboarding provider to manage the state and control of the tour
class OnboardingProvider extends ChangeNotifier {
  late Future<SharedPreferences> _storage;
  final List<OnboardingStep> _steps = [];
  String _tourKey = "";
  int _currentStepIndex = 0;
  bool _isActive = false;
  OverlayEntry? _overlayEntry;
  BuildContext? _overlayContext;
  String _initializedBy = "";

  // Getters
  List<OnboardingStep> get steps => _steps;
  int get currentStepIndex => _currentStepIndex;
  bool get isActive => _isActive;
  OnboardingStep? get currentStep =>
      _isActive && _steps.isNotEmpty && _currentStepIndex < _steps.length
          ? _steps[_currentStepIndex]
          : null;

  OnboardingProvider(Future<SharedPreferences> storage) {
    _storage = storage;
  }

  // Initialize the context needed for overlay
  void init(BuildContext context) {
    // if (!_initialized) {
    _overlayContext = context;
    // _initialized = true;
    // }
  }

  // Add a single step
  void addStep(OnboardingStep step) {
    _steps.add(step);
    notifyListeners();
  }

  // Add multiple steps
  void addSteps(List<OnboardingStep> steps, String tourKey) async {
    // check if tour is completed, skip if yes
    final prefs = await _storage;
    if (tourKey.isNotEmpty && prefs.getBool(tourKey) == true) {
      print("Skipping tour: $tourKey, because it's completed");
      return;
    }

    _steps.addAll(steps);
    _tourKey = tourKey;
    notifyListeners();
  }

  // Store tour as completed, this wouldn't show to the user again.
  void completeTour() async {
    if (_tourKey.isNotEmpty) {
      print("Completing tour: '$_tourKey'");
      final prefs = await _storage;
      await prefs.setBool(_tourKey, true);
    } else {
      print("Keeping tour: '$_tourKey'");
    }
  }

  // Clear all steps
  void clearSteps() {
    _steps.clear();
    notifyListeners();
  }

  // Start the tour
  void startTour() {
    if (_steps.isEmpty || _overlayContext == null) return;

    _currentStepIndex = 0;
    _isActive = true;
    _showCurrentTooltip();
    notifyListeners();
  }

  // Start the tour from a specific step
  void startTourFromStep(String stepId) {
    if (_steps.isEmpty || _overlayContext == null) return;

    final index = _steps.indexWhere((step) => step.id == stepId);
    if (index != -1) {
      _currentStepIndex = index;
      _isActive = true;
      _showCurrentTooltip();
      notifyListeners();
    }
  }

  // Move to the next step
  void nextStep() {
    _removeOverlay();

    if (_currentStepIndex < _steps.length - 1) {
      print("Next");
      _currentStepIndex++;
      _showCurrentTooltip();
    } else {
      print("End");
      _isActive = false;
      if (_tourKey.isNotEmpty) {
        // Store tour completed
        completeTour();
      }
    }

    notifyListeners();
  }

  // Skip the tour
  void skipTour() {
    _removeOverlay();
    _isActive = false;
    notifyListeners();
  }

  // Remove the current tooltip overlay
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // Show the current tooltip
  void _showCurrentTooltip() {
    if (!_isActive ||
        _currentStepIndex >= _steps.length ||
        _overlayContext == null) return;

    final step = _steps[_currentStepIndex];

    // Ensure the target has been rendered
    if (step.targetKey.currentContext == null) {
      // If target not available, skip to next or end tour
      if (_currentStepIndex < _steps.length - 1) {
        _currentStepIndex++;
        _showCurrentTooltip();
      } else {
        _isActive = false;
        notifyListeners();
      }
      return;
    }

    // Get the target widget's position
    final RenderBox renderBox =
        step.targetKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildTooltipOverlay(position, size, step),
    );

    if (_overlayContext?.mounted == true) {
      Overlay.of(_overlayContext!).insert(_overlayEntry!);
    } else {
      print("Overlay context not mounted");
    }
  }

  // Build the tooltip overlay
  Widget _buildTooltipOverlay(Offset position, Size size, OnboardingStep step) {
    return Stack(
      children: [
        // Semi-transparent background
        Positioned.fill(
          child: GestureDetector(
            onTap: skipTour,
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),

        // Target highlight
        Positioned(
          left: position.dx - 5,
          top: position.dy - 5,
          child: Container(
            width: size.width + 10,
            height: size.height + 10,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),

        // Tooltip bubble
        _positionedTooltip(position, size, step),
      ],
    );
  }

  // Position the tooltip relative to the target
  Positioned _positionedTooltip(
      Offset position, Size size, OnboardingStep step) {
    final screenSize = MediaQuery.of(_overlayContext!).size;

    final double margin = 8;
    double tooltipWidth = 250;
    double tooltipHeight = 150;
    double arrowSize = 16;

    double left = 0;
    double top = 0;

    double arrowLeft = 0;
    double arrowTop = 0;

    // Position tooltip based on specified position
    switch (step.position) {
      case TooltipPosition.top:
        left = position.dx + (size.width / 2) - (tooltipWidth / 2);
        top = position.dy - tooltipHeight - arrowSize;

        arrowLeft = (left + tooltipWidth + arrowSize) / 4;
        arrowTop = top - arrowSize;
        break;
      case TooltipPosition.right:
        left = position.dx + size.width + arrowSize;
        top = position.dy + (size.height / 2) - (tooltipHeight / 2);
        arrowLeft = 0; // left + arrowSize;
        arrowTop = (top + tooltipHeight - arrowSize) / 4;
        break;
      case TooltipPosition.bottom:
        left = position.dx + (size.width / 2) - (tooltipWidth / 2);
        top = position.dy + size.height + arrowSize;
        arrowLeft = (left + tooltipWidth + arrowSize) / 4;
        arrowTop = 0; // top + arrowSize;
        break;
      case TooltipPosition.left:
        left = position.dx - tooltipWidth - arrowSize;
        top = position.dy + (size.height / 2) - (tooltipHeight / 2);
        arrowLeft = tooltipWidth - arrowSize;
        arrowTop = (top + tooltipHeight - arrowSize) / 4;
        break;
    }

    // Ensure tooltip stays on screen
    left = left.clamp(10, screenSize.width - tooltipWidth - 10);
    top = top.clamp(10, screenSize.height - tooltipHeight - 10);

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Container(
              width: tooltipWidth - 16,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(margin),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(step.description),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_currentStepIndex + 1} of ${_steps.length}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: skipTour,
                            child: Text('Skip'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                            ),
                          ),
                          SizedBox(width: 8),
                          TextButton(
                            onPressed: nextStep,
                            child: Text(_currentStepIndex < _steps.length - 1
                                ? 'Next'
                                : 'Finish'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Positioned(
              left: arrowLeft,
              top: arrowTop / 1.48,
              // 90 degrees rotated box
              child: Transform.rotate(
                angle: -pi / 4,
                child: Container(
                  width: arrowSize,
                  height: arrowSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }
}
