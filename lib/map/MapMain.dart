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
import 'package:wooki/CustomerServiceCenter/main.dart';

// main 함수에서 Firebase 초기화 및 앱 실행
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: MapScreen(),
  ));
}

class MapScreen extends StatefulWidget {
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
  String? _userId;
  String? _userName;
  String? _userImage;
  double _heading = 0;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _getCurrentLocation();
    _listenToSensorEvents();
  }

  Future<void> _initializeUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('email');
    if (_userId != null) {
      QuerySnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance
          .collection('USERLIST')
          .where('email', isEqualTo: _userId)
          .get();
      if (userDoc.docs.isNotEmpty) {
        Map<String, dynamic> userData = userDoc.docs.first.data();
        String userKey = userData['key']; // userKey 값 가져오기
        setState(() {
          _userName = userData['name'];
          _userImage = userData['imagePath'];
        });
        _initializeCurrentPosition(userId: userDoc.docs.first.id); // userId 값을 전달하여 호출
        _initializeFamilyMarkers(userKey: userKey); // userKey 값을 전달하여 호출
      } else {
        print('User document not found');
      }
    }
  }

  Future<void> _initializeCurrentPosition({required String userId}) async {
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

  Future<void> _initializeFamilyMarkers({required String userKey}) async {
    QuerySnapshot<Map<String, dynamic>> userQuerySnapshot = await FirebaseFirestore.instance
        .collection('USERLIST')
        .where('email', isEqualTo: _userId)
        .get();

    if (userQuerySnapshot.docs.isEmpty) {
      print('User document not found');
      return;
    }

    DocumentSnapshot<Map<String, dynamic>> userDoc = userQuerySnapshot.docs.first;
    List<dynamic> whiteList = userDoc.data()?['whiteList'] ?? [];

    FirebaseFirestore.instance
        .collection('USERLIST')
        .where('key', isEqualTo: userKey)
        .snapshots()
        .listen((familySnapshot) {
      setState(() {
        _markers.clear();
        for (var familyDoc in familySnapshot.docs) {
          final familyData = familyDoc.data();
          String familyId = familyDoc.id;

          if (whiteList.contains(familyData['email'])) {
            FirebaseFirestore.instance
                .collection('USERLIST')
                .doc(familyId)
                .collection('MAP')
                .doc('currentLocation')
                .snapshots()
                .listen((mapSnapshot) async {
              if (mapSnapshot.exists) {
                Map<String, dynamic>? mapData = mapSnapshot.data();
                if (mapData != null) {
                  Uint8List imageBytes = await _getCircleAvatarBytes(familyData['imagePath'], size: 250);
                  final icon = BitmapDescriptor.fromBytes(imageBytes);

                  setState(() {
                    _markers.add(Marker(
                      markerId: MarkerId(familyId),
                      position: LatLng(mapData['latitude'], mapData['longitude']),
                      icon: icon,
                      infoWindow: InfoWindow(title: familyData['name']),
                      visible: true,
                    ));
                  });
                }
              }
            });
          }
        }
      });
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

    _savePositionToFirestore(position);
  }

  Future<Uint8List> _loadNetworkImage(String imageUrl) async {
    final http.Response response = await http.get(Uri.parse(imageUrl));
    return response.bodyBytes;
  }

  Future<Uint8List> _getCircleAvatarBytes(String imageUrl, {required int size}) async {
    Uint8List bytes = await _loadNetworkImage(imageUrl);
    ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: size, targetHeight: size);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    ui.Image image = frameInfo.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;
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
        final Uint8List imageBytes = await _getCircleAvatarBytes(_userImage!, size: 250); // 크기를 250으로 지정
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
        });
      }
    }
  }

  Future<void> _savePositionToFirestore(Position position) async {
    // 이메일을 기준으로 도큐먼트 아이디를 찾음
    QuerySnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance
        .collection('USERLIST')
        .where('email', isEqualTo: _userId)
        .get();

    if (userDoc.docs.isEmpty) {
      print('User document not found');
      return;
    }

    // 도큐먼트 아이디를 사용하여 위치 데이터 저장
    String docId = userDoc.docs.first.id;

    final mapRef = FirebaseFirestore.instance
        .collection('USERLIST')
        .doc(docId)
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

  void _toggleCenter() {
    setState(() {
      _isCentered = !_isCentered;
    });
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {});

    if (_isCentered) {
      mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition));
    } else {
      setState(() {
        _isCentered = false;
      });
    }
  }

  void _showBottomSheet() async {
    QuerySnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance
        .collection('USERLIST')
        .where('email', isEqualTo: _userId)
        .get();

    if (userDoc.docs.isEmpty) {
      print('User document not found');
      return;
    }

    DocumentSnapshot user = userDoc.docs.first;
    bool isAdmin = user['isAdmin'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.56,
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xff6D605A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: <Widget>[
                SizedBox(height: 24),
                _userImage != null
                    ? CircleAvatar(
                  radius: 80,
                  backgroundImage: NetworkImage(_userImage!),
                )
                    : CircleAvatar(
                  radius: 80,
                  child: Icon(Icons.person, size: 80),
                ),
                SizedBox(height: 16),
                Text(
                  _userName ?? '사용자 이름',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: ui.FontWeight.w600),
                ),
                SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: Icon(Icons.edit, color: Colors.white),
                        title: Text('회원정보수정', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: ui.FontWeight.w600)),
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserEditApp(user: user, isAdmin: isAdmin),
                            ),
                                (Route<dynamic> route) => false,
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.help, color: Colors.white),
                        title: Text('고객센터', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: ui.FontWeight.w600)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Customer()),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.logout, color: Colors.white),
                        title: Text('로그아웃', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: ui.FontWeight.w600)),
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
        .where('email', isEqualTo: _userId)
        .get();

    if (userDoc.docs.isEmpty) {
      print('User document not found');
      return;
    }

    Map<String, dynamic> userData = userDoc.docs.first.data();
    String userKey = userData['key'] ?? '';

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Color(0xff6D605A),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('USERLIST')
                .where('key', isEqualTo: userKey)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final familyCollection = snapshot.data!.docs;
              List<dynamic> whiteList = userData['whiteList'] ?? [];

              return ListView.builder(
                itemCount: familyCollection.length,
                itemBuilder: (context, index) {
                  var familyData = familyCollection[index].data() as Map<String, dynamic>;
                  String familyEmail = familyData['email'] ?? '';
                  if (familyEmail == _userId) {
                    return Container(); // 본인은 리스트에 포함되지 않음
                  }
                  bool isInWhiteList = whiteList.contains(familyEmail);
                  String familyName = familyData['name'] ?? 'Unknown';
                  String imagePath = familyData['imagePath'] ?? 'default_image_path';

                  return SwitchListTile(
                    title: Text(
                      familyName,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    value: isInWhiteList,
                    onChanged: (bool value) async {
                      DocumentReference userRef = FirebaseFirestore.instance.collection('USERLIST').doc(userDoc.docs.first.id);

                      setState(() {
                        if (value) {
                          whiteList.add(familyEmail);
                        } else {
                          whiteList.remove(familyEmail);
                        }
                      });

                      await userRef.update({'whiteList': whiteList});

                      // 마커 업데이트
                      setState(() {
                        _markers.clear();
                        FirebaseFirestore.instance
                            .collection('USERLIST')
                            .where('key', isEqualTo: userKey)
                            .snapshots()
                            .listen((familySnapshot) {
                          for (var familyDoc in familySnapshot.docs) {
                            final familyData = familyDoc.data();
                            String familyId = familyDoc.id;

                            if (whiteList.contains(familyData['email'])) {
                              FirebaseFirestore.instance
                                  .collection('USERLIST')
                                  .doc(familyId)
                                  .collection('MAP')
                                  .doc('currentLocation')
                                  .snapshots()
                                  .listen((mapSnapshot) async {
                                if (mapSnapshot.exists) {
                                  Map<String, dynamic>? mapData = mapSnapshot.data();
                                  if (mapData != null) {
                                    Uint8List imageBytes = await _getCircleAvatarBytes(familyData['imagePath'], size: 250);
                                    final icon = BitmapDescriptor.fromBytes(imageBytes);

                                    setState(() {
                                      _markers.add(Marker(
                                        markerId: MarkerId(familyId),
                                        position: LatLng(mapData['latitude'], mapData['longitude']),
                                        icon: icon,
                                        infoWindow: InfoWindow(title: familyData['name']),
                                        visible: true,
                                      ));
                                    });
                                  }
                                }
                              });
                            }
                          }
                        });
                      });
                    },
                    activeColor: Colors.blue,
                    secondary: imagePath != 'default_image_path'
                        ? CircleAvatar(
                      backgroundImage: NetworkImage(imagePath),
                    )
                        : CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );

    // 리스너 추가하여 마커 상태 변경
    FirebaseFirestore.instance
        .collection('USERLIST')
        .where('key', isEqualTo: userKey)
        .snapshots()
        .listen((familySnapshot) {
      setState(() {
        _markers.clear();
        for (var familyDoc in familySnapshot.docs) {
          final familyData = familyDoc.data();
          String familyId = familyDoc.id;

          if (userData['whiteList'].contains(familyData['email'])) {
            FirebaseFirestore.instance
                .collection('USERLIST')
                .doc(familyId)
                .collection('MAP')
                .doc('currentLocation')
                .snapshots()
                .listen((mapSnapshot) async {
              if (mapSnapshot.exists) {
                Map<String, dynamic>? mapData = mapSnapshot.data();
                if (mapData != null) {
                  Uint8List imageBytes = await _getCircleAvatarBytes(familyData['imagePath'], size: 250);
                  final icon = BitmapDescriptor.fromBytes(imageBytes);

                  setState(() {
                    _markers.add(Marker(
                      markerId: MarkerId(familyId),
                      position: LatLng(mapData['latitude'], mapData['longitude']),
                      icon: icon,
                      infoWindow: InfoWindow(title: familyData['name']),
                      visible: true,
                    ));
                  });
                }
              }
            });
          }
        }
      });
    });
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
          style: TextStyle(color: Color(0xFF4E3E36), fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFFFFFDEF),
        leading: null,
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
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFFFFFDEF),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _showFamilyInfoBottomSheet,
              child: _buildBottomNavigationBarItem(Icons.family_restroom),
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
                shadowColor: Colors.grey.withOpacity(0.9),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomListPage(userId: _userId!),
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
    return Icon(icon, color: Color(0xFF4E3E36), size: 30,);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    super.dispose();
  }
}
