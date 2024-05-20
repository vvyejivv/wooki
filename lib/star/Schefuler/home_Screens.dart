import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wooki/star/Schefuler/main_calander.dart';
import '../firebase_options.dart';
import 'package:wooki/star/Schefuler/add_SchedulScreen.dart';
import 'package:wooki/star/Schefuler/get_SchedulList.dart';
import 'package:wooki/star/Schefuler/edit_SchedulScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Title',
      theme: ThemeData(),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      selectedDate = selectedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MainCalendar(
              selectedDate: selectedDate,
              onDaySelected: onDaySelected,
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: ScheduleService().fetchSchedulesForDate(selectedDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    List<Map<String, dynamic>> schedules = snapshot.data!;
                    return ListView.builder(
                      itemCount: schedules.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  '제목 : ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  child: Text(
                                    '${schedules[index]['title']}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  '내용 : ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  child: Text(
                                    '${schedules[index]['description']}',
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditScheduleScreen(
                                          schedule: schedules[index], // 선택한 일정의 정보 전달
                                          documentId: schedules[index]['id'], // 선택한 일정의 문서 ID 전달
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    // 삭제 기능을 구현합니다.
                                    // deleteSchedule(index);
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              // 일정을 탭하면 일정 상세 정보로 이동할 수 있는 기능 추가
                              // Navigator.push(context, MaterialPageRoute(builder: (context) => ScheduleDetailScreen(schedule: schedules[index])));
                            },
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddScheduleScreen(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
