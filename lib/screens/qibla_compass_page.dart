import 'dart:async';
import 'dart:math' show pi, sin, cos, tan, atan2;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran_app_flutter/screens/home_page.dart';
import 'package:quran_app_flutter/utils/utils.dart';

class QiblaCompass extends StatefulWidget {
  const QiblaCompass({super.key});

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass>
    with SingleTickerProviderStateMixin {
  StreamSubscription<CompassEvent>? _subscription;
  double _qiblaDirectionDegrees = 0;
  double? heading;
  bool hasPermission = false;
  Position? userLocation;
  final double kaabaLat = 21.422487;
  final double kaabaLng = 39.826206;

  // For heading smoothing
  final List<double> _headingBuffer = [];
  static const int bufferSize =
      5; // Adjust this value to change smoothing level

  @override
  void initState() {
    super.initState();
    updateThemeScale(context);
    _checkLocationPermission();

    // Initialize heading listener
    _subscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        _updateHeading(event.heading!);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _updateHeading(double newHeading) {
    // Add new heading to buffer
    _headingBuffer.add(newHeading);
    if (_headingBuffer.length > bufferSize) {
      _headingBuffer.removeAt(0);
    }

    // Calculate smoothed heading
    if (_headingBuffer.length == bufferSize) {
      // Sort the buffer to remove outliers
      final sortedHeadings = List<double>.from(_headingBuffer)..sort();
      // Use median value for more stable reading
      final smoothedHeading = sortedHeadings[bufferSize ~/ 2];

      // Create smooth rotation animation
      final oldHeading = heading ?? smoothedHeading;
      var headingDiff = smoothedHeading - oldHeading;

      // Normalize the difference to handle 360° -> 0° transition
      if (headingDiff > 180) {
        headingDiff -= 360;
      } else if (headingDiff < -180) {
        headingDiff += 360;
      }

      setState(() {
        heading = smoothedHeading;
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      setState(() => hasPermission = true);
      _getCurrentLocation();
    } else {
      setState(() => hasPermission = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();

      final location = Position(
        longitude: position.longitude, // 45.323484,
        latitude: position.latitude, // 2.033466,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        altitude: position.altitude,
        altitudeAccuracy: position.altitudeAccuracy,
        heading: position.heading,
        headingAccuracy: position.headingAccuracy,
        speed: position.speed,
        speedAccuracy: position.speedAccuracy,
      );
      setState(() => userLocation = location);
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  double _calculateQiblaDirection() {
    if (userLocation == null) return 0;

    final userLat = userLocation!.latitude * pi / 180;
    final userLng = userLocation!.longitude * pi / 180;
    final kaabaLatRad = kaabaLat * pi / 180;
    final kaabaLngRad = kaabaLng * pi / 180;

    final y = sin(kaabaLngRad - userLng);
    final x = cos(userLat) * tan(kaabaLatRad) -
        sin(userLat) * cos(kaabaLngRad - userLng);

    var qiblaDirection = atan2(y, x);
    qiblaDirection = (qiblaDirection * 180 / pi + 360) % 360;

    return qiblaDirection;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('MeezanSync'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Center(
        child: hasPermission
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (heading != null && userLocation != null)
                    Transform.rotate(
                      angle: (heading! * pi / 180) * -1,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Compass Circle
                          Container(
                            width: 300,
                            height: 300,
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.teal, width: 1),
                            ),
                            child: Opacity(
                              opacity: 0.55,
                              child: Image.asset(
                                "assets/images/compass.png",
                              ),
                            ),
                          ),
                          // Qibla Direction
                          Transform.rotate(
                            angle: _calculateQiblaDirection() * pi / 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 233,
                                  width: 233,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  child: Column(
                                    children: [
                                      Text(
                                        "${_calculateQiblaDirection().toStringAsFixed(2)}°",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          shadows:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? shadows
                                                  : lightShadows,
                                        ),
                                      ),
                                      Image.asset(
                                        "assets/images/kaaba.png",
                                        width: 48,
                                        height: 48,
                                      ),
                                      // Text(
                                      //   'Qibla',
                                      //   style: TextStyle(
                                      //     fontSize: 16,
                                      //     fontWeight: FontWeight.bold,
                                      //     color: Colors.teal,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const CircularProgressIndicator(color: Colors.teal),
                  const SizedBox(height: 20),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      'Qibla Direction',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      "${_calculateQiblaDirection().toStringAsFixed(2)}°",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (userLocation != null)
                      Text(
                        "${latToString(userLocation!.latitude)} ${lngToString(userLocation!.longitude)}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                  ]),
                ],
              )
            : SizedBox(
                width: 350,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_disabled,
                        size: 64, color: Colors.teal),
                    const SizedBox(height: 16),
                    const Text(
                      'Location permission is required to show the compass',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _checkLocationPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Enable Location'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class QiblaDirectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.teal
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
