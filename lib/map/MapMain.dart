import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../messenger/ChatRoomListPage.dart';
import '../album/album_main.dart';

class MapScreen extends StatefulWidget {
  final String userId;

  MapScreen({required this.userId});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LatLng _currentPosition = LatLng(37.4909987338, 126.720552076);
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  bool _isCentered = false;
  Marker? _currentLocationMarker;
  Timer? _updateTimer;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  String? _userName;
  double _heading = 0;
  Set<Polygon> _polygons = {};
  double _currentZoom = 18.0;

  @override
  void initState() {
    super.initState();
    _getUserName();
    _getCurrentLocation();
    _listenToSensorEvents();
  }

  Future<void> _getUserName() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('USERLIST').doc(widget.userId).get();
    setState(() {
      _userName = userDoc['name'];
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('위치 서비스가 비활성화되었습니다.');
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('위치 권한이 영구히 거부되어, 권한을 요청할 수 없습니다.');
    }

    final position = await _geolocatorPlatform.getCurrentPosition();
    _updatePosition(position);

    _positionStreamSubscription = _geolocatorPlatform.getPositionStream().listen((Position position) {
      _startUpdateTimer(position);
    });
  }

  void _startUpdateTimer(Position position) {
    _updateTimer?.cancel();
    _updateTimer = Timer(Duration(seconds: 5), () {
      if (mounted) {
        _updatePosition(position);
      }
    });
  }

  void _updatePosition(Position position) {
    final newPosition = LatLng(position.latitude, position.longitude);
    if (mounted) {
      setState(() {
        _currentPosition = newPosition;
        _currentLocationMarker = Marker(
          markerId: MarkerId('currentLocation'),
          position: newPosition,
          infoWindow: InfoWindow(title: _userName != null ? '$_userName의 위치' : '현재 위치'),
          rotation: _heading,
        );

        if (_isCentered) {
          mapController.animateCamera(CameraUpdate.newLatLng(newPosition));
        }
        _updatePolygon();
      });
    }
  }

  void _listenToSensorEvents() {
    _magnetometerSubscription = magnetometerEvents.listen((MagnetometerEvent event) {
      if (mounted) {
        setState(() {
          _heading = _calculateHeading(event.x, event.y, event.z);
          _updatePolygon();
        });
      }
    });
  }

  double _calculateHeading(double x, double y, double z) {
    double heading = (x != 0) ? (atan2(y, x) * (180 / pi)) : 0;
    if (heading < 0) {
      heading += 360;
    }
    return heading;
  }

  void _updatePolygon() {
    const double baseViewAngle = 30.0;
    const double baseViewDistance = 0.002; // 약 200m

    double adjustedViewDistance = baseViewDistance * pow(2, 18.0 - _currentZoom);

    final double leftAngle = (_heading - baseViewAngle).toRad();
    final double rightAngle = (_heading + baseViewAngle).toRad();

    final LatLng leftPoint = LatLng(
      _currentPosition.latitude + adjustedViewDistance * cos(leftAngle),
      _currentPosition.longitude + adjustedViewDistance * sin(leftAngle),
    );
    final LatLng rightPoint = LatLng(
      _currentPosition.latitude + adjustedViewDistance * cos(rightAngle),
      _currentPosition.longitude + adjustedViewDistance * sin(rightAngle),
    );

    setState(() {
      _polygons = {
        Polygon(
          polygonId: PolygonId('viewPolygon'),
          points: [_currentPosition, leftPoint, rightPoint, _currentPosition],
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.transparent,
          strokeWidth: 2,
        ),
      };
    });
  }

  void _toggleCenter() {
    setState(() {
      _isCentered = !_isCentered;
    });
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentZoom = position.zoom;
      _updatePolygon();
    });

    if (_isCentered) {
      mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition));
    } else {
      setState(() {
        _isCentered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Google 지도',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xff6D605A),
        actions: [
          IconButton(
            icon: Icon(
              _isCentered ? Icons.location_on : Icons.location_off,
              color: _isCentered ? Colors.red : Colors.grey,
            ),
            onPressed: _toggleCenter,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              setState(() {
                mapController = controller;
              });
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 18.0,
            ),
            onCameraMove: _onCameraMove,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _currentLocationMarker != null ? {_currentLocationMarker!} : {},
            polygons: _polygons,
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF4E3E36),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBottomNavigationBarItem(Icons.home),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SnsApp(),
                  ),
                );
              },
              child: _buildBottomNavigationBarItem(Icons.photo_album)
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  backgroundColor: Colors.transparent
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomListPage(userId: widget.userId),
                    ),
                  );
              }, child: Image.asset('assets/img/wooki3.png', height: 60,)
              ),
            GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SnsApp(),
                    ),
                  );
                },
                child: _buildBottomNavigationBarItem(Icons.photo_album)
            ),
            _buildBottomNavigationBarItem(Icons.more_horiz),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBarItem(IconData icon) {
    return Icon(icon, color: Colors.white60, size: 30,);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    super.dispose();
  }
}

extension on double {
  double toRad() => this * pi / 180.0;
}
