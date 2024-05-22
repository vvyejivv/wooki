import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Core 추가

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화

  runApp(FamilyAuth());
}

class FamilyAuth extends StatelessWidget {
  FamilyAuth ({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Dynamic Link Example'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              // Firebase Dynamic Links 사용 코드
              DynamicLinkParameters dynamicLinkParams = DynamicLinkParameters(
                uriPrefix: "https://wookiauth.page.link",
                link: Uri.parse("https://wookiauth.page.link/test"),
                androidParameters: const AndroidParameters(
                  packageName: "com.example.wooki",
                  minimumVersion: 0,
                ),
              );

              ShortDynamicLink dynamicLink = await FirebaseDynamicLinks.instance
                  .buildShortLink(dynamicLinkParams);

              String url = dynamicLink.shortUrl.toString();
              print(url);
            },
            child: Text('Create Dynamic Link'),
          ),
        ),
      ),
    );
  }
}
