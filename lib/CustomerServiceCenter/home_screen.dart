import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'user_chat_screen.dart';

class ToHomeScreen extends StatefulWidget {
  const ToHomeScreen({Key? key}) : super(key: key);

  @override
  State<ToHomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ToHomeScreen> {
  List<String> items = [
    '자주하는 질문 ',
    '최신 공지사항 ',
    '최신 소식 ',
    '고객 리뷰 ',
    '고객 지원 ',
    '최근 활동 ',
  ]; // 전체 항목 리스트
  List<String> filteredItems = []; // 필터링된 항목 리스트

  @override
  void initState() {
    super.initState();
    // 처음에는 모든 항목을 보여줍니다.
    filteredItems = items;
  }

  // 리스트 필터링 함수
  void filterList(String query) {
    if (mounted) {
      setState(() {
        // 검색어를 입력하지 않았을 경우에는 전체 리스트를 보여줍니다.
        if (query.isEmpty) {
          filteredItems = items;
        } else {
          // 검색어를 포함하는 항목만 필터링하여 보여줍니다.
          filteredItems = items
              .where((item) => item.toLowerCase().contains(query.toLowerCase()))
              .toList();
        }
      });
    }
  }

  // 기능 버튼 데이터
  List<FeatureButtonData> featureButtons = [
    FeatureButtonData(
      icon: Icons.new_releases,
      label: '최신 소식',
      onPressed: (context) {
        // 최신 소식 기능 실행
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LatestNewsScreen()),
        );
      },
    ),
    FeatureButtonData(
      icon: Icons.star,
      label: '고객 리뷰',
      onPressed: (context) {
        // 고객 리뷰 기능 실행
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CustomerReviewsScreen()),
        );
      },
    ),
    FeatureButtonData(
      icon: Icons.support,
      label: '고객 지원',
      onPressed: (context) {
        // 고객 지원 기능 실행
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CustomerSupportScreen()),
        );
      },
    ),
    FeatureButtonData(
      icon: Icons.history,
      label: '최근 활동',
      onPressed: (context) {
        // 최근 활동 기능 실행
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecentActivitiesScreen()),
        );
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 검색 바
          Container(
            color: Color(0xFFFFFDEF),
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Container(
                child: TextField(
                  onChanged: filterList, // 검색어 변경 시 필터링 함수 호출
                  decoration: InputDecoration(
                    labelText: '검색',
                    labelStyle: TextStyle(
                      fontSize: 15, // 원하는 글씨 크기
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff4E3E36), // 텍스트 색상 (필요한 경우)
                    ),
                    hintText: '검색어를 입력하세요',
                    hintStyle: TextStyle(
                      fontSize: 13, // 힌트 텍스트 크기
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      color: Colors.grey, // 힌트 텍스트 색상
                    ),
                    prefixIcon: Icon(Icons.search),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xff3A281F), // 밑줄 색상
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xff3A281F), // 포커스된 밑줄 색상
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 10,
            child: Container(color: Color(0xFFFFFDEF),),
          ), // 위젯 간 간격 조절
          // 기능 버튼들
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              color: Color(0xFFFFFDEF), // 배경색 지정
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: featureButtons.map((button) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildFeatureButton(
                      icon: button.icon,
                      label: button.label,
                      onPressed: () => button.onPressed(context),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 10,child: Container(color: Color(0xFFFFFDEF),),),
          // 피싱/스미싱/사칭 사기 주의 메시지
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.amberAccent, // 배경색 설정
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '피싱/스미싱/사칭 사기 주의하세요!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '금융 기관이나 기타 중요한 개인 정보를 요구하는 메시지나 링크를 받았을 경우 신뢰하지 마세요. ',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  '절대로 개인 정보를 제공하지 마시고, 해당 메시지를 삭제해 주세요. ',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                    '문자/이메일을 통해 전화 연결이나 출처를 알 수 없는 인터넷 주소(URL)를 유도할 경우 절대 클릭하지 마세요'),
              ],
            ),
          ),
          SizedBox(child: Container(color: Color(0xFFFFFDEF),),),
          // 그 외 문의 빠르게 해결하세요 메시지
          GestureDetector(
            onTap: () {
              // UserChatScreen으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserChatScreen()),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Color(0xFF4E3E36), // 배경색 설정
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.question_answer, color: Colors.white),
                  SizedBox(width: 8,child: Container(color: Color(0xFFFFFDEF),),),
                  Text(
                    '그 외 문의를 빠르게 해결하세요',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10,child: Container(color: Color(0xFFFFFDEF),),),
          // 필터링된 항목 리스트 표시
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Define navigation logic here based on the item clicked
                    if (filteredItems[index] == '최신 소식') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LatestNewsScreen()),
                      );
                    } else if (filteredItems[index] == '고객 리뷰') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CustomerReviewsScreen()),
                      );
                    } else if (filteredItems[index] == '고객 지원') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CustomerSupportScreen()),
                      );
                    } else if (filteredItems[index] == '최근 활동') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RecentActivitiesScreen()),
                      );
                    }
                  },
                  child: Container(
                    color: Color(0xFFFFFDEF),
                    child: ListTile(
                      title: Text(
                          filteredItems[index],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                          _getSubtitle(filteredItems[index])),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 기능 버튼 위젯
  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label,style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF3A281F),
        foregroundColor: Color(0xFF3A281F),
        minimumSize: Size(80, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  // Subtitle generation method
  String _getSubtitle(String item) {
    // Define your logic here to generate subtitles based on the item.
    // This is just a placeholder example:
    if (item.contains('최신 소식')) {
      return '우끼와 함께하는 이벤트!';
    } else if (item.contains('고객 리뷰')) {
      return '우끼를 사용한 리뷰 작성 부탁드립니다.';
    } else if (item.contains('고객 지원')) {
      return '고객 지원';
    } else if (item.contains('최근 활동')) {
      return '최근 활동';
    } else {
      return ''; // Return an empty string if no specific subtitle is defined.
    }
  }
}

// 기능 버튼 데이터 모델
class FeatureButtonData {
  final IconData icon;
  final String label;
  final void Function(BuildContext context) onPressed;

  FeatureButtonData({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}

// 각 기능에 해당하는 화면들
class LatestNewsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFDEF),
      appBar: AppBar(title: Text('최신 소식')),
      body: Center(child: Text('최신 소식 화면')),
    );
  }
}

class CustomerReviewsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFDEF),
      appBar: AppBar(
          title: Text('고객 리뷰'),
          backgroundColor: Color(0xFFFFFDEF)
      ),
      body: Center(child: Text('고객 리뷰 화면')),
    );
  }
}

class CustomerSupportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFDEF),
      appBar: AppBar(
          title: Text('고객 지원'),
          backgroundColor: Color(0xFFFFFDEF)
      ),
      body: Center(child: Text('고객 지원 화면')),
    );
  }
}

class RecentActivitiesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFDEF),
      appBar: AppBar(
          title: Text('최근 활동'),
          backgroundColor: Color(0xFFFFFDEF)
      ),
      body: Center(child: Text('최근 활동 화면')),
    );
  }
}
