import 'package:flutter/material.dart';
import 'package:wooki/CustomerServiceCenter/firestore_service.dart'; // Firestore 서비스를 위한 사용자 정의 라이브러리 임포트

class AskedQuestions extends StatefulWidget {
  const AskedQuestions({super.key});

  @override
  State<AskedQuestions> createState() => _AskedQuestionsState();
}

class _AskedQuestionsState extends State<AskedQuestions> {
  final FirestoreService _firestoreService = FirestoreService();
  late final Stream<List<FAQ>> _faqStream;
  String? _selectedCategory;
  List<FAQ> _allFaqs = [];
  List<FAQ> _filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    _initializeFaqs();
  }

  Future<void> _initializeFaqs() async {
    _faqStream = _firestoreService.getFAQs();
    _faqStream.listen((faqs) {
      _allFaqs = faqs;
      _filterFaqs('');
    });
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _filterFaqs('');
    });
  }

  void _filterFaqs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFaqs = (_selectedCategory == null || _selectedCategory!.isEmpty)
            ? _allFaqs
            : _allFaqs.where((faq) => faq.category == _selectedCategory).toList();
      } else {
        _filteredFaqs = _allFaqs.where((faq) {
          return faq.question.toLowerCase().contains(query.toLowerCase()) &&
              (_selectedCategory == null || _selectedCategory!.isEmpty || faq.category == _selectedCategory);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자주하는질문', textAlign: TextAlign.center),
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
                  onChanged: (value) => _filterFaqs(value),
                  decoration: InputDecoration(
                    labelText: '검색',
                    hintText: '질문 검색...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 140,
            child: _buildCategoryGrid(),
          ),
          Expanded(
            child: _buildFAQList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
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
          onTap: () => _selectCategory(category.id),
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedCategory == category.id ? Colors.blue : Colors.grey,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, size: 20, color: _selectedCategory == category.id ? Colors.blue : Colors.grey),
                const SizedBox(height: 5),
                Text(category.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAQList() {
    return ListView.builder(
      itemCount: _filteredFaqs.length,
      itemBuilder: (context, index) {
        final faq = _filteredFaqs[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ExpansionTile(
            title: Text(faq.question),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(faq.answer),
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

  Category(this.id, this.label, this.icon);
}
