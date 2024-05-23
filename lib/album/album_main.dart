import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Story Board',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StoryBoard(),
    );
  }
}

class StoryBoard extends StatelessWidget {
  final List<Story> stories = [
    Story(date: '2020년 1월 11일 (토)', images: [
      'assets/img/wooki1.png', // Replace with actual image paths
      'assets/img/wooki2.png',
    ]),
    // Add more stories here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('스토리 게시판'),
      ),
      body: ListView.builder(
        itemCount: stories.length,
        itemBuilder: (context, index) {
          return StoryCard(story: stories[index]);
        },
      ),
    );
  }
}

class Story {
  final String date;
  final List<String> images;

  Story({required this.date, required this.images});
}

class StoryCard extends StatelessWidget {
  final Story story;

  StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              story.date,
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
          ...story.images.map((image) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(image),
          )).toList(),
        ],
      ),
    );
  }
}
