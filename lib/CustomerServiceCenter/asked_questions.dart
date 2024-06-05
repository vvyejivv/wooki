import 'package:flutter/material.dart';
import 'package:wooki/CustomerServiceCenter/firestore_service.dart'; // Firestore 서비스를 위한 사용자 정의 라이브러리 임포트

class AskedQuestions extends StatefulWidget {
  const AskedQuestions({super.key});

  @override
  State<AskedQuestions> createState() => _AskedQuestionsState();
}

class _AskedQuestionsState extends State<AskedQuestions> {
  final FirestoreService _firestoreService =
  FirestoreService(); // FirestoreService 인스턴스 생성
  late final Stream<List<FAQ>> _faqStream; // FAQ 데이터를 가져오는 스트림
  String? _selectedCategory; // 선택된 카테고리
  List<FAQ> _allFaqs = []; // 모든 FAQ 목록
  List<FAQ> _filteredFaqs = []; // 필터링된 FAQ 목록

  @override
  void initState() {
    super.initState();
    _initializeFaqs(); // FAQ 데이터 초기화
  }

  Future<void> _initializeFaqs() async {
    _faqStream =
        _firestoreService.getFAQs(); // Firestore에서 FAQ 데이터 가져오는 스트림 초기화
    _faqStream.listen((faqs) {
      _allFaqs = faqs; // 전체 FAQ 목록 업데이트
      _filterFaqs(''); // FAQ 필터링
    });
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category; // 선택된 카테고리 업데이트
      _filterFaqs(''); // FAQ 필터링
    });
  }

  void _filterFaqs(String query) {
    setState(() {
      if (query.isEmpty) {
        // 검색어가 없는 경우
        _filteredFaqs =
        (_selectedCategory == null || _selectedCategory!.isEmpty)
            ? _allFaqs // 선택된 카테고리가 없으면 모든 FAQ 표시
            : _allFaqs
            .where((faq) => faq.category == _selectedCategory)
            .toList(); // 선택된 카테고리에 해당하는 FAQ 표시
      } else {
        // 검색어가 있는 경우
        _filteredFaqs = _allFaqs.where((faq) {
          return faq.question
              .toLowerCase()
              .contains(query.toLowerCase()) && // 질문에서 검색어 포함 여부 확인
              (_selectedCategory == null ||
                  _selectedCategory!.isEmpty ||
                  faq.category ==
                      _selectedCategory); // 선택된 카테고리에 해당하는 FAQ 여부 확인
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Color(0xFFFFFDEF),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  color: Color(0xFFFFFDEF),
                  child: TextField(
                    onChanged: (value) => _filterFaqs(value), // 검색어 입력 시 FAQ 필터링
                    decoration: InputDecoration(
                      labelText: '검색', // 검색 필드 레이블
                      labelStyle: TextStyle(
                        fontSize: 15, // 원하는 글씨 크기
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff4E3E36), // 텍스트 색상 (필요한 경우)
                      ),
                      hintText: '질문 검색...', // 검색 힌트
                      hintStyle: TextStyle(
                        fontSize: 13, // 힌트 텍스트 크기
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        color: Colors.grey, // 힌트 텍스트 색상
                      ),
                      prefixIcon: Icon(Icons.search), // 검색 아이콘
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
          ),
          SizedBox(
            height: 140,
            child: _buildCategoryGrid(), // 카테고리 그리드 생성
          ),
          Expanded(
            child: _buildFAQList(), // FAQ 목록 생성
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    // 카테고리 그리드 생성
    List<Category> categories = [
      Category(null, '모든 질문', Icons.all_inclusive),
      Category('서비스 이용과 결제', '서비스 이용과 결제', Icons.payment),
      Category('기술적 문제와 오류 해결', '기술적 문제와 오류 해결', Icons.build),
      Category('커뮤니티 및 이벤트', '커뮤니티 및 이벤트', Icons.event),
      Category('개인정보 보호와 보안', '개인정보 보호와 보안', Icons.security),
      Category('기타 문의 사항', '기타 문의 사항', Icons.more_horiz),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 5 / 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () => _selectCategory(category.id), // 카테고리 선택 시 처리
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedCategory == category.id
                    ? Color(0xFFFFE458)
                    : Color(0xff4E3E36), // 선택된 카테고리의 색상 변경
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon,
                    size: 20,
                    color: _selectedCategory == category.id
                        ? Color(0xFFFFE458)
                        : Color(0xff4E3E36)), // 아이콘 및 색상 변경
                const SizedBox(height: 5),
                Text(category.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10)), // 라벨 텍스트
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAQList() {
    // FAQ 목록 생성
    return ListView.builder(
      itemCount: _filteredFaqs.length,
      itemBuilder: (context, index) {      final faq = _filteredFaqs[index];
      return Card(
        color: Color(0xff4E3E36), // Card 배경색
        margin: const EdgeInsets.all(8.0),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Color(0xff4E3E36), // ExpansionTile 선 색상
          ),
          child: ExpansionTile(
            backgroundColor: Color(0xff4E3E36), // ExpansionTile 배경색
            title: Text(
              faq.question,
              style: TextStyle(
                color: Colors.white, // 질문 글씨색
                fontWeight: FontWeight.bold,
              ),
            ),
            iconColor: Color(0xff4E3E36), // 아이콘 색상
            children: [
              Container(
                color: Color(0xFFFFFDEF), // 답변 배경색
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  faq.answer,
                  style: TextStyle(
                    color: Color(0xff4E3E36), // 답변 글씨색
                  ),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }
}

class Category {
  final String? id;
  final String label;
  final IconData icon;

  Category(this.id, this.label, this.icon); // 카테고리 모델
}