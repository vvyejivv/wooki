import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LatLng _currentPosition = LatLng(37.4909987338, 126.720552076);
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  bool _isCentered = true;
  Marker? _currentLocationMarker;
  Timer? _updateTimer;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('위치 서비스가 비활성화되었습니다.');
    }

    // Check for location permissions.
    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('위치 권한이 영구적으로 거부되어, 권한 요청을 할 수 없습니다.');
    }

    // Get the current location.
    final position = await _geolocatorPlatform.getCurrentPosition();
    _updatePosition(position);

    // Listen for location updates.
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
          infoWindow: InfoWindow(title: '현재 위치'),
        );

        if (_isCentered) {
          mapController.animateCamera(CameraUpdate.newLatLng(newPosition));
        }
      });
    }
  }

  void _toggleCenter() {
    setState(() {
      _isCentered = !_isCentered;
    });
  }

  void _onCameraMove(CameraPosition position) {
    if (_isCentered) {
      mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition));
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
      body: GoogleMap(
        onMapCreated: (controller) {
          setState(() {
            mapController = controller;
          });
        },
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 14.0,
        ),
        onCameraMove: _onCameraMove,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _currentLocationMarker != null ? {_currentLocationMarker!} : {},
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFFB69E94),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildBottomNavigationBarItem(Icons.home, '홈'),
            _buildBottomNavigationBarItem(Icons.photo_album, '앨범'),
            _buildBottomNavigationBarItem(Icons.message, '메신저'),
            _buildBottomNavigationBarItem(Icons.calendar_today, '캘린더'),
            _buildBottomNavigationBarItem(Icons.more_horiz, '더보기'),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBarItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: Colors.white),
        Text(
          label,
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
