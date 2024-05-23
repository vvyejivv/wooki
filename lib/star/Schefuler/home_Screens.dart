import 'package:flutter/material.dart';
import 'package:wooki/star/Schefuler/main_calander.dart';
import 'package:wooki/star/Schefuler/add_SchedulScreen.dart';
import 'package:wooki/star/Schefuler/edit_SchedulScreen.dart';
import 'package:wooki/star/Schefuler/get_Schedule.dart';
import 'package:wooki/star/Schefuler/today_banner.dart';
import 'package:wooki/star/Schefuler/delete_SchedulScreen.dart'; // deleteSchedule 함수가 있는 파일 경로

class HomeScreen extends StatefulWidget {
  final Function(DateTime) updateScheduleCount;

  const HomeScreen({Key? key, required this.updateScheduleCount})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 선택된 날짜를 저장하는 변수입니다.
  DateTime selectedDate = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  // 일정 개수와 일정 목록을 저장하는 변수입니다.
  int scheduleCount = 0;
  List<Map<String, dynamic>> schedules = [];

  @override
  void initState() {
    super.initState();
    // 화면 초기화 시 선택된 날짜에 해당하는 일정 개수를 가져옵니다.
    updateScheduleCount(selectedDate);
  }

  // 날짜가 선택될 때 호출되는 함수입니다.
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      selectedDate = selectedDay;
      updateScheduleCount(selectedDate);
    });
  }

  // 선택된 날짜에 해당하는 일정 개수를 업데이트하는 함수입니다.
  void updateScheduleCount(DateTime selectedDate) async {
    try {
      // ScheduleService를 통해 선택된 날짜의 일정을 가져옵니다.
      List<Map<String, dynamic>> fetchedSchedules =
          await ScheduleService().fetchSchedulesForDate(selectedDate);
      setState(() {
        schedules = fetchedSchedules;
        scheduleCount = fetchedSchedules.length;
      });
    } catch (error) {
      // 일정 가져오기 실패 시 에러를 출력하고 일정 목록을 초기화합니다.
      print('일정 가져오기 실패: $error');
      setState(() {
        schedules = [];
        scheduleCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 메인 캘린더 위젯입니다.
            MainCalendar(
              selectedDate: selectedDate,
              onDaySelected: onDaySelected,
            ),
            // 오늘의 일정 개수를 표시하는 배너입니다.
            TodayBanner(
              selectedDate: selectedDate,
              count: scheduleCount,
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                // ScheduleService를 통해 선택된 날짜의 일정을 가져옵니다.
                future: ScheduleService().fetchSchedulesForDate(selectedDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // 데이터를 불러오는 중이면 로딩 스피너를 표시합니다.
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    // 에러가 발생하면 에러 메시지를 표시합니다.
                    return Center(child: Text('오류: ${snapshot.error}'));
                  } else {
                    // 데이터가 성공적으로 불러와졌을 때 일정 목록을 업데이트합니다.
                    schedules = snapshot.data ?? [];
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
                                // 수정 아이콘 버튼입니다.
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () async {
                                    var result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditScheduleScreen(
                                          schedule: schedules[index],
                                          updateScheduleCount:
                                              updateScheduleCount, // updateScheduleCount 메서드 전달
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      updateScheduleCount(
                                          selectedDate); // 일정 업데이트
                                    }
                                  },
                                ),

                                // 삭제 아이콘 버튼입니다.
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    // 일정을 삭제합니다.
                                    deleteSchedule(
                                        context, selectedDate, schedules, index,
                                        () {
                                      updateScheduleCount(selectedDate);
                                    });
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              // 일정을 탭하면 일정 상세 정보로 이동할 수 있는 기능을 추가할 수 있습니다.
                              //Navigator.push(context, MaterialPageRoute(builder: (context) => ScheduleDetailScreen(schedule: schedules[index])));
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
      // 일정 추가 버튼입니다.
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 일정 추가 화면으로 이동합니다.
          var value = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddScheduleScreen(
                selectedDate: selectedDate,
                updateScheduleCount: updateScheduleCount, // updateScheduleCount 메서드 전달
              ),
            ),
          );

          // 일정 추가 후 돌아왔을 때 상태를 업데이트합니다.
          if (value == true) {
            updateScheduleCount(selectedDate);
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}