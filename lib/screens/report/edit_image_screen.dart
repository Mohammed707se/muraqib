import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:path_provider/path_provider.dart';

class EditImageScreen extends StatelessWidget {
  final String imagePath;

  const EditImageScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // appBar: AppBar(
      //   title: const Text('تعديل الصورة'),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.save),
      //       onPressed: () {
      //         // لا حاجة لتنفيذ منطق الحفظ هنا لأن الحفظ يتم في الـ Callback
      //       },
      //     ),
      //   ],
      // ),
      body: Center(
        child: ProImageEditor.asset(
          imagePath,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List bytes) async {
              final editedImagePath = await saveEditedImage(bytes);
              Navigator.pop(
                  context, editedImagePath); // إرجاع مسار الصورة المعدلة
            },
          ),
        ),
      ),
    );
  }

  Future<String> saveEditedImage(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory(); // الحصول على الدليل المؤقت
      final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes); // حفظ الصورة المعدلة
      print('تم تعديل الصورة بنجاح! محفوظة في: ${file.path}');
      return file.path; // إرجاع مسار الملف
    } catch (e) {
      print('فشل في حفظ الصورة: $e');
      return imagePath; // إرجاع المسار الأصلي في حال فشل الحفظ
    }
  }
}
