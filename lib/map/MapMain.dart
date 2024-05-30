import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import '../messenger/ChatRoomListPage.dart';
import '../album/album_main.dart';
import '../login/Login_main.dart';
import 'package:wooki/Schefuler/main.dart';
import '../Join/JoinEditDelete.dart';

// main function to initialize Firebase and run the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: MapScreen(userId: 'your_user_id'),
  ));
}

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
  String? _userImage;
  double _heading = 0;
  Set<Polygon> _polygons = {};
  double _currentZoom = 18.0;
  Map<String, bool> _switchValues = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _getCurrentLocation();
    _listenToSensorEvents();
  }

  Future<void> _initializeUserData() async {
    QuerySnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance
        .collection('USERLIST')
        .where('email', isEqualTo: widget.userId)
        .get();
    if (userDoc.docs.isNotEmpty) {
      Map<String, dynamic> userData = userDoc.docs.first.data();
      setState(() {
        _userName = userData['name'];
        _userImage = userData['imagePath'];
      });
      _initializeCurrentPosition(userDoc.docs.first.id);
      _initializeFamilyMarkers(userDoc.docs.first.id);
    } else {
      print('User document not found');
    }
  }

  Future<void> _initializeCurrentPosition(String userId) async {
    DocumentSnapshot<Map<String, dynamic>> mapDoc = await FirebaseFirestore.instance
        .collection('USERLIST')
        .doc(userId)
        .collection('MAP')
        .doc('currentLocation')
        .get();

    if (mapDoc.exists) {
      Map<String, dynamic>? mapData = mapDoc.data();
      if (mapData != null) {
        setState(() {
          _currentPosition = LatLng(mapData['latitude'], mapData['longitude']);
        });
      }
    }
  }

  Future<void> _initializeFamilyMarkers(String userId) async {
    final familyCollection = await FirebaseFirestore.instance
        .collection('USERLIST')
        .doc(userId)
        .collection('FAMILY')
        .get();

    if (familyCollection.docs.isNotEmpty) {
      setState(() {
        for (var familyDoc in familyCollection.docs) {
          final familyData = familyDoc.data();
          _switchValues[familyDoc.id] = familyData['isSwitchOn'] ?? false;
          _markers.add(Marker(
            markerId: MarkerId(familyDoc.id),
            position: LatLng(familyData['latitude'], familyData['longitude']),
            infoWindow: InfoWindow(title: familyData['familyName']),
            visible: _switchValues[familyDoc.id] ?? false,
          ));
        }
      });
    }
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

    _savePositionToFirestore(position);
  }

  Future<Uint8List> _loadNetworkImage(String imageUrl) async {
    final http.Response response = await http.get(Uri.parse(imageUrl));
    return response.bodyBytes;
  }

  Future<Uint8List> _getCircleAvatarBytes(String imageUrl) async {
    Uint8List bytes = await _loadNetworkImage(imageUrl);
    ui.Codec codec = await ui.instantiateImageCodec(bytes);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    ui.Image image = frameInfo.image;

    final size = min(image.width, image.height);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();
    paint.isAntiAlias = true;
    final path = Path()
      ..addOval(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
    canvas.clipPath(path);
    canvas.drawImage(image, Offset.zero, paint);
    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _startUpdateTimer(Position position) {
    _updateTimer?.cancel();
    _updateTimer = Timer(Duration(seconds: 5), () {
      if (mounted) {
        _updatePosition(position);
      }
    });
  }

  Future<void> _updatePosition(Position position) async {
    final newPosition = LatLng(position.latitude, position.longitude);
    if (mounted) {
      if (_userImage != null) {
        final Uint8List imageBytes = await _getCircleAvatarBytes(_userImage!);
        final icon = BitmapDescriptor.fromBytes(imageBytes);
        setState(() {
          _currentPosition = newPosition;
          _currentLocationMarker = Marker(
            markerId: MarkerId('currentLocation'),
            position: newPosition,
            icon: icon,
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
  }

  Future<void> _savePositionToFirestore(Position position) async {
    final mapRef = FirebaseFirestore.instance
        .collection('USERLIST')
        .doc(widget.userId)
        .collection('MAP')
        .doc('currentLocation');
    await mapRef.set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _listenToSensorEvents() {
    _magnetometerSubscription = magnetometerEventStream().listen((MagnetometerEvent event) {
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
    const double baseViewDistance = 0.002;

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

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xff6D605A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: <Widget>[
                SizedBox(height: 16),
                _userImage != null
                    ? CircleAvatar(
                  radius: 120,
                  backgroundImage: NetworkImage(_userImage!),
                )
                    : CircleAvatar(
                  radius: 120,
                  child: Icon(Icons.person, size: 80),
                ),
                SizedBox(height: 16),
                Text(
                  _userName ?? '사용자 이름',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: Icon(Icons.edit, color: Colors.white),
                        title: Text('회원정보수정', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => UserEditApp()),
                                (Route<dynamic> route) => false,
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.group, color: Colors.white),
                        title: Text('가족연결관리', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          // Add your onTap functionality here
                        },
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.help, color: Colors.white),
                        title: Text('고객센터', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          // Add your onTap functionality here
                        },
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.logout, color: Colors.white),
                        title: Text('로그아웃', style: TextStyle(color: Colors.white)),
                        onTap: _logout,
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFamilyInfoBottomSheet() async {
    QuerySnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance
        .collection('USERLIST')
        .where('email', isEqualTo: widget.userId)
        .get();
    Map<String, dynamic> userData = userDoc.docs.first.data();

    bool familyLinked = userData['familyLinked'];

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        if (!familyLinked) {
          return Container(
            color: Color(0xff6D605A),
            child: Center(
              child: Text(
                '가족으로 등록된 사람이 없어요!',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ),
          );
        } else {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('USERLIST')
                .doc(userDoc.docs.first.id)
                .collection('FAMILY')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var familyDocs = snapshot.data!.docs;

              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Container(
                    color: Color(0xff6D605A),
                    child: ListView.builder(
                      itemCount: familyDocs.length,
                      itemBuilder: (context, index) {
                        var familyData = familyDocs[index].data() as Map<String, dynamic>;
                        bool isSwitchOn = _switchValues[familyDocs[index].id] ?? false;

                        return SwitchListTile(
                          title: Text(
                            familyData['familyName'],
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          value: isSwitchOn,
                          onChanged: (bool value) {
                            setState(() {
                              isSwitchOn = value;
                              _switchValues[familyDocs[index].id] = value;
                              _markers = _markers.map((marker) {
                                if (marker.markerId.value == familyDocs[index].id) {
                                  return marker.copyWith(visibleParam: value);
                                }
                                return marker;
                              }).toSet();
                            });
                            FirebaseFirestore.instance
                                .collection('USERLIST')
                                .doc(userDoc.docs.first.id)
                                .collection('FAMILY')
                                .doc(familyDocs[index].id)
                                .update({'isSwitchOn': value});
                          },
                          activeColor: Colors.blue,
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        }
      },
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginApp()),
          (Route<dynamic> route) => false,
    );
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
                _getCurrentLocation();
              });
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 18.0,
            ),
            onCameraMove: _onCameraMove,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: {
              if (_currentLocationMarker != null) _currentLocationMarker!,
              ..._markers,
            },
            polygons: _polygons,
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF4E3E36),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _showFamilyInfoBottomSheet,
              child: _buildBottomNavigationBarItem(Icons.account_circle),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                backgroundColor: Colors.transparent,
                elevation: 5,
                shadowColor: Colors.grey.withOpacity(0.5),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomListPage(userId: widget.userId),
                  ),
                );
              }, child: Image.asset('assets/img/wooki3.png', height: 60,),
            ),
            GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Schefuler(),
                    ),
                  );
                },
                child: _buildBottomNavigationBarItem(Icons.calendar_month)
            ),
            GestureDetector(
                onTap: _showBottomSheet,
                child: _buildBottomNavigationBarItem(Icons.more_horiz)
            ),
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