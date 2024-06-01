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
      appBar: AppBar(
        title: const Text('자주하는질문', textAlign: TextAlign.center), // 앱 바 타이틀
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Container(
                width: 500,
                child: TextField(
                  onChanged: (value) => _filterFaqs(value), // 검색어 입력 시 FAQ 필터링
                  decoration: InputDecoration(
                    labelText: '검색', // 검색 필드 레이블
                    hintText: '질문 검색...', // 검색 힌트
                    prefixIcon: Icon(Icons.search), // 검색 아이콘
                    border: OutlineInputBorder(
                      // 텍스트 필드 외각선 스타일
                      borderRadius: BorderRadius.circular(20),
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
                    ? Colors.blue
                    : Colors.grey, // 선택된 카테고리의 색상 변경
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon,
                    size: 20,
                    color: _selectedCategory == category.id
                        ? Colors.blue
                        : Colors.grey), // 아이콘 및 색상 변경
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
      itemBuilder: (context, index) {
        final faq = _filteredFaqs[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ExpansionTile(
            title: Text(faq.question), // 질문
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(faq.answer), // 답변
              ),
            ],
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