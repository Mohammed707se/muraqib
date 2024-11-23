import 'package:concentric_transition/concentric_transition.dart';
import 'package:flutter/material.dart';
import 'package:muraqib/home_page.dart';

import 'widgets/LoadingOverlay.dart'; // تأكد من استيراد الويدجت

final pages = [
  const PageData(
    image: 'assets/png/logo_white.png',
    title:
        "يسهل تطبيقنا عملية الإبلاغ عن المشاكل المنزلية ويجعلها أسرع وأكثر دقة بفضل تقنيات الذكاء الاصطناعي",
    bgColor: Color(0xff2D1884),
    textColor: Colors.white,
  ),
  const PageData(
    image: 'assets/png/logo_white.png',
    title:
        "أبلغ عن مشكلتك بخطوات بسيطة وتلقَ الدعم اللازم من فريق الصيانة في أسرع وقت",
    bgColor: Color(0xfffab800),
    textColor: Color(0xff3b1790),
  ),
  const PageData(
    image: 'assets/png/logo_white.png',
    title:
        "صوّر المشكلة، وأرسل الإبلاغ، ودع الباقي علينا لتحصل على حلول سريعة ومهنية",
    bgColor: Color(0xffffffff),
    textColor: Color(0xff3b1790),
  ),
];

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isLoading = false;
  int currentPage = 0;
  final PageController _pageController = PageController();

  void _navigateToNextPage() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      isLoading = false;
    });

    // الانتقال إلى الصفحة التالية
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: [
          ConcentricPageView(
            pageController: _pageController, // تعيين PageController
            colors: pages.map((p) => p.bgColor).toList(),
            radius: screenWidth * 0.1,
            nextButtonBuilder: (context) => Padding(
              padding: const EdgeInsets.only(left: 3),
              child: IconButton(
                icon: Icon(
                  Icons.navigate_next,
                  size: screenWidth * 0.08,
                ),
                onPressed: () {
                  if (currentPage == pages.length - 1) {
                    _navigateToNextPage(); // إذا كانت الصفحة الأخيرة
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
            scaleFactor: 2,
            itemBuilder: (index) {
              final page = pages[index % pages.length];
              return SafeArea(
                child: _Page(page: page),
              );
            },
          ),
          if (isLoading) LoadingOverlay(isLoading: isLoading),
        ],
      ),
    );
  }
}

class PageData {
  final String? title;
  final String image;
  final Color bgColor;
  final Color textColor;

  const PageData({
    this.title,
    required this.image,
    this.bgColor = Colors.white,
    this.textColor = Colors.black,
  });
}

class _Page extends StatelessWidget {
  final PageData page;

  const _Page({Key? key, required this.page}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.all(16.0),
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: page.textColor),
          child: Image.asset(
            page.image,
            height: screenHeight * 0.1,
            color: page.bgColor,
          ),
        ),
        Text(
          page.title ?? "",
          style: TextStyle(
              color: page.textColor,
              fontSize: screenHeight * 0.030,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
