import 'package:flutter/material.dart';
import 'package:muraqib/screens/home/home_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // قائمة الصفحات لكل عنصر في شريط التنقل
  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    Center(child: Text('الفئات')),
    Center(child: Text('السجل')),
    Center(child: Text('الملف الشخصي')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex], // عرض الصفحة المحددة
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5), // لون الظل
              spreadRadius: 1,
              blurRadius: 30,
              offset: const Offset(0, -3), // اتجاه الظل للأعلى
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent, // جعل الخلفية شفافة
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.category),
                label: 'الفئات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'السجل',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'الملف الشخصي',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xff4F2AEA), // لون العنصر النشط
            unselectedItemColor: Colors.grey, // لون العناصر غير النشطة
            selectedFontSize: 12, // حجم خط النص للعناصر النشطة
            unselectedFontSize: 12, // حجم خط النص للعناصر غير النشطة
            showUnselectedLabels: true, // إظهار أسماء الصفحات دائمًا
            onTap: _onItemTapped, // تحديث الصفحة عند تغيير العنصر
            elevation: 0, // إزالة الظل الافتراضي لشريط التنقل
          ),
        ),
      ),
    );
  }
}
