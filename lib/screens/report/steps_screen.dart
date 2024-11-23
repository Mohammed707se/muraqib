// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:io';
import 'dart:convert'; // للتشفير base64
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:muraqib/screens/report/edit_image_screen.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

// نموذج لبيانات كل خطوة
class StepData {
  final String title;
  final StepType type;
  final List<String>? options; // للخطوات التي تحتوي على خيارات
  final String? placeholder; // لنصوص الإدخال
  final bool hasOtherOption;

  StepData({
    required this.title,
    required this.type,
    this.options,
    this.placeholder,
    this.hasOtherOption = false,
  });
}

enum StepType {
  multipleChoice,
  imageUpload,
  textInput,
  summary,
}

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  // قائمة بالخطوات
  final List<StepData> steps = [
    StepData(
      title: 'ما نوع المشكلة التي تواجهها؟',
      type: StepType.multipleChoice,
      options: ['تسرب مياه', 'أعطال كهربائية', 'شقوق'],
      hasOtherOption: true,
    ),
    StepData(
      title: 'أرفق لنا صور للمشكلة إن وجدت',
      type: StepType.imageUpload,
    ),
    StepData(
      title: 'اكتب تفاصيل المشكلة',
      type: StepType.textInput,
      placeholder: 'اكتب وصف عن المشكلة هنا ...',
    ),
    StepData(
      title: 'تقرير',
      type: StepType.summary,
    ),
  ];

  int currentStep = 0; // مؤشر الخطوة الحالية

  // لتخزين الإجابات
  Map<int, dynamic> answers = {};

  bool isSubmitting = false; // يشير إلى أن عملية الإرسال جارية
  Map<String, dynamic>? reportData; // يحتفظ بالتقرير المستلم من API

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.sizeOf(context).width;
    final H = MediaQuery.sizeOf(context).height;
    final currentStepData = steps[currentStep]; // بيانات الخطوة الحالية
    final totalSteps = steps.length;
    bool isStepComplete = validateStep(currentStepData);

    // إذا تم استلام التقرير، عرضه
    if (reportData != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 80,
          backgroundColor: Colors.white,
          title: Text(
            'تقرير المشكلة',
            style: TextStyle(
              color: Color(0XFF702DFF),
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Image.asset(
                'assets/png/back.png',
              ),
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عرض التقرير
                  Text(
                    'التقرير النهائي',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  // عرض كل زوج مفتاح-قيمة في التقرير
                  ...reportData!.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        title: Text(
          'الإبلاغ عن مشكلة',
          style: TextStyle(
            color: Color(0XFF702DFF),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Image.asset(
              'assets/png/back.png',
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: isSubmitting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xff702DFF),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'جاري رفع البيانات وإرسال التقرير...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // المحتوى القابل للتمرير
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        children: [
                          // عنوان السؤال ورقم الخطوة
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'أجب عن الأسئلة التالية:',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xff7B5AFF),
                                      Color(0xff4A25E1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 4),
                                  child: Text(
                                    '${currentStep + 1} / $totalSteps',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          // بار التقدم
                          Align(
                            alignment: Alignment.center,
                            child: LinearPercentIndicator(
                              width: W / 1.11,
                              lineHeight: 6.0,
                              percent: (currentStep + 1) / totalSteps,
                              barRadius: Radius.circular(20),
                              progressColor: Color(0xff702DFF),
                            ),
                          ),
                          SizedBox(height: 20),
                          // عرض عنوان الخطوة الحالية
                          Container(
                            width: double.infinity,
                            child: Text(
                              currentStepData.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          // عرض المحتوى بناءً على نوع الخطوة
                          getStepWidget(currentStepData, currentStep),
                          SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // زر التالي ثابت في أسفل الشاشة
                Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: ElevatedButton(
                    onPressed: isStepComplete
                        ? () async {
                            if (currentStep < totalSteps - 1) {
                              setState(() {
                                currentStep++;
                              });
                            } else {
                              // المستخدم في الخطوة الأخيرة (التقرير)، نقوم بإرسال البيانات
                              await submitReport();
                            }
                          }
                        : null, // تعطيل الزر إذا لم تكتمل الخطوة
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff702DFF),
                      padding: EdgeInsets.symmetric(
                          horizontal: 100.0, vertical: 15.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      currentStep < totalSteps - 1 ? 'التالي' : 'إنهاء',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // دالة لإرجاع الويدجت المناسب لكل خطوة
  Widget getStepWidget(StepData stepData, int stepIndex) {
    switch (stepData.type) {
      case StepType.multipleChoice:
        return MultipleChoiceWidget(
          options: stepData.options ?? [],
          hasOtherOption: stepData.hasOtherOption,
          onSelected: (selected) {
            setState(() {
              answers[stepIndex] = selected;
            });
          },
        );
      case StepType.imageUpload:
        return ImageUploadWidget(
          onImagesSelected: (images) {
            setState(() {
              answers[stepIndex] = images;
            });
          },
        );
      case StepType.textInput:
        return Column(
          children: [
            TextInputWidget(
              label: 'موقع المشكلة',
              placeholder:
                  'المطبخ / غرفة النوم / دورة المياه / أخرى', // تم تعديل النص
              onTextChanged: (text) {
                setState(() {
                  if (answers[stepIndex] == null ||
                      answers[stepIndex] is! Map<String, String>) {
                    answers[stepIndex] = {};
                  }
                  answers[stepIndex]['موقع المشكلة'] = text;
                });
              },
            ),
            SizedBox(height: 20),
            TextInputWidget(
              label: 'وصف المشكلة',
              placeholder: stepData.placeholder ?? '',
              onTextChanged: (text) {
                setState(() {
                  if (answers[stepIndex] == null ||
                      answers[stepIndex] is! Map<String, String>) {
                    answers[stepIndex] = {};
                  }
                  answers[stepIndex]['وصف المشكلة'] = text;
                });
              },
            ),
          ],
        );
      case StepType.summary:
        return SummaryWidget(answers: answers);
      default:
        return Container();
    }
  }

  // دالة للتحقق من ملء الإجابة في الخطوة الحالية
  bool validateStep(StepData stepData) {
    if (stepData.type == StepType.summary) {
      return true;
    }
    var answer = answers[currentStep];
    if (stepData.type == StepType.multipleChoice) {
      if (answer == null || (answer is String && answer.trim().isEmpty)) {
        return false;
      }
      return true;
    } else if (stepData.type == StepType.textInput) {
      if (answer == null ||
          (answer is Map<String, String> &&
              ((answer['موقع المشكلة'] == null ||
                      answer['موقع المشكلة']!.trim().isEmpty) ||
                  (answer['وصف المشكلة'] == null ||
                      answer['وصف المشكلة']!.trim().isEmpty)))) {
        return false;
      }
      return true;
    }
    return true;
  }

  // دالة لإرسال التقرير
  Future<void> submitReport() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      // الخطوة 1: رفع الصور إلى Firebase Storage والحصول على روابطها
      List<XFile> images = [];
      if (answers.containsKey(1)) {
        images = answers[1] as List<XFile>;
      }

      List<String> imageUrls = [];
      for (XFile image in images) {
        String fileName =
            DateTime.now().millisecondsSinceEpoch.toString() + '_' + image.name;
        Reference storageRef =
            FirebaseStorage.instance.ref().child('reports/$fileName');
        UploadTask uploadTask = storageRef.putFile(File(image.path));

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // الخطوة 2: تجهيز البيانات للحفظ في Firestore
      String selectedProblem = answers[0] ?? '';
      String location = '';
      String description = '';
      if (answers[2] != null) {
        Map<String, String> textInputs = answers[2] as Map<String, String>;
        location = textInputs['موقع المشكلة'] ?? '';
        description = textInputs['وصف المشكلة'] ?? '';
      }

      // الخطوة 3: حفظ بيانات التقرير في Firestore
      DocumentReference reportRef =
          FirebaseFirestore.instance.collection('reports').doc();

      await reportRef.set({
        'selectedProblem': selectedProblem,
        'location': location,
        'description': description,
        'imageUrls': imageUrls,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // الخطوة 4: إرسال البيانات إلى ChatGPT API
      // تأكد من استبدال 'YOUR_OPENAI_API_KEY' بمفتاح API الخاص بك
      String apiKey = 'YOUR_OPENAI_API_KEY'; // ⚠️ احرص على حماية هذا المفتاح
      String apiUrl = 'https://api.openai.com/v1/chat/completions';

      // تجهيز الصور بالتشفير base64
      List<String> base64Images = [];
      for (XFile image in images) {
        File imgFile = File(image.path);
        List<int> imageBytes = await imgFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        base64Images.add(base64Image);
      }

      // تجهيز الرسالة (Prompt) بنفس طريقة البايثون
      String prompt = '''
أنت مساعد متقدم متخصص في تحليل مشاكل إدارة العقارات وإنشاء مخرجات منظمة.

التعليمات:
1. قم بتحليل المدخلات المقدمة أدناه وابتكر استجابة بصيغة JSON فقط.
2. لا تقم بتضمين أي شروحات إضافية أو تعليقات خارج صيغة JSON.
3. اتبع هيكل JSON المثال المقدم بدقة، وقم بملء جميع الحقول بناءً على المدخلات المقدمة.
4. بالنسبة للمرفقات (الصور)، والتي يتم توفيرها كسلاسل مشفرة base64، قم بتعيين معرف فريد لكل صورة (مثل 1، 2، إلخ) وضمن وصفًا موجزًا لكل صورة.
5. يجب أن تكون جميع النصوص في JSON باللغة العربية.

المدخلات:
- نوع المشكلة المحددة: $selectedProblem
- الموقع: $location
- الوصف: $description
- عدد الصور: ${base64Images.length}
- الصور: يتم توفير الصور كسلاسل مشفرة base64.

صيغة JSON المثال:
${jsonEncode(_getExampleJson())}

الاستجابة:
- قم بإرجاع كائن JSON صالح مملوء بالمعلومات اللازمة بناءً على المدخلات المقدمة. يجب أن تكون جميع النصوص في JSON باللغة العربية.
''';

      // إعداد الطلب
      Map<String, dynamic> requestBody = {
        "model": "gpt-4",
        "messages": [
          {
            "role": "user",
            "content": prompt,
          }
        ],
        "max_tokens": 1000,
      };

      // إجراء طلب HTTP POST
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // افترض أن API يعيد JSON
        Map<String, dynamic> apiResponse = jsonDecode(response.body);

        // استخراج محتوى الرسالة من الاستجابة
        String reportContent = apiResponse['choices'][0]['message']['content'];

        // تحويل النص إلى كائن JSON
        Map<String, dynamic> reportJson = jsonDecode(reportContent);

        // الخطوة 5: حفظ استجابة API في Firestore
        await reportRef.update({
          'report': reportJson,
        });

        // الخطوة 6: تحديث الواجهة لعرض التقرير
        setState(() {
          reportData = reportJson;
        });
      } else {
        // معالجة الردود غير الناجحة
        print('Failed to fetch report: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في إرسال التقرير. حاول مرة أخرى.')),
        );
      }
    } catch (e) {
      // معالجة الأخطاء
      print('Error submitting report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إرسال التقرير.')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  // دالة لإرجاع صيغة JSON المثال المستخدمة في البايثون
  Map<String, dynamic> _getExampleJson() {
    return {
      "case_report": {
        "priority": {
          "urgency":
              "<اختر كلمة واحدة: عاجل، معتدل، أو منخفض بناءً على المعايير التالية: \n- 'عاجل' إذا كانت النسبة 70 أو أعلى ويشير الوصف إلى خطر فوري أو ضرر كبير.\n- 'معتدل' إذا كانت النسبة بين 40 و69 والمشكلة يمكن أن تنتظر ولكنها لا تزال تتطلب اهتمامًا.\n- 'منخفض' إذا كانت النسبة أقل من 40 والمشكلة تشكل خطرًا أو تأثيرًا ضئيلًا.>",
          "percentage":
              "<احسب نسبة الاستعجال بناءً على تقييم موزون للشدة، احتمالية الضرر، وسرعة الإجراء. استخدم النطاقات التالية:\n- خطر مرتفع: 70–100٪ (تهديد حرج وفوري).\n- خطر متوسط: 40–69٪ (ليس حرجًا ولكنه يحتاج إلى حل).\n- خطر منخفض: 0–39٪ (تأثير ضئيل، يمكن أن ينتظر).>",
          "description":
              "<اشرح مستوى الاستعجال المختار بربطه بالمشاكل الملحوظة (مثل الشقوق، خطر هيكلي) والنسبة المحسوبة.>"
        },
        "analysis_summary": {
          "observation":
              "<وصف الملاحظات الرئيسية المتعلقة بالمشكلة، مثل الضرر المرئي أو علامات المشاكل الهيكلية.>",
          "recommendation":
              "<قدم توصية واضحة للإجراء، بما في ذلك مستوى الأولوية والخطوات المقترحة لمعالجة المشكلة.>"
        },
        "attachments": [
          {
            "type": "image",
            "id": "<قدم معرفًا فريدًا للمرفق، مثل 1، 2، إلخ>",
            "description": "<صف بإيجاز ما يمثله المرفق، مثل صورة للضرر.>"
          }
        ],
        "problem_description": {
          "summary":
              "<قدم ملخصًا موجزًا للمشكلة، بما في ذلك ما تم ملاحظته ونطاق المشكلة.>",
          "cause": "<أدرج الأسباب المحتملة أو العوامل المساهمة في المشكلة.>",
          "impact":
              "<اشرح التأثير المحتمل للمشكلة إذا تُركت دون حل، مع التركيز على السلامة، الوظائف، أو الجماليات.>"
        }
      }
    };
  }
}

// ويدجت مخصص لعرض الاختيارات المتعددة
class MultipleChoiceWidget extends StatefulWidget {
  final List<String> options;
  final bool hasOtherOption;
  final Function(String?) onSelected;

  const MultipleChoiceWidget({
    super.key,
    required this.options,
    this.hasOtherOption = false,
    required this.onSelected,
  });

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  String? selectedOption;
  String? otherText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.options.map((option) {
          bool isSelected = option == selectedOption;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedOption = option;
                otherText = null;
              });
              widget.onSelected(selectedOption);
            },
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 8.0),
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xff4F2AEA),
                          Color(0xff2D1884),
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                border: Border.all(
                  color: isSelected ? Color(0xff702DFF) : Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.circle_outlined,
                    color: isSelected ? Colors.white : Color(0xff737791),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        if (widget.hasOtherOption)
          GestureDetector(
            onTap: () {
              setState(() {
                selectedOption = 'أخرى';
              });
              widget.onSelected(selectedOption);
            },
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 8.0),
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
              decoration: BoxDecoration(
                gradient: selectedOption == 'أخرى'
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xff4F2AEA),
                          Color(0xff2D1884),
                        ],
                      )
                    : null,
                color: selectedOption == 'أخرى' ? null : Colors.white,
                border: Border.all(
                  color: selectedOption == 'أخرى'
                      ? Color(0xff702DFF)
                      : Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'أخرى (اذكرها)',
                      style: TextStyle(
                        color: selectedOption == 'أخرى'
                            ? Colors.white
                            : Colors.black,
                        fontWeight: selectedOption == 'أخرى'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.circle_outlined,
                    color: selectedOption == 'أخرى'
                        ? Colors.white
                        : Color(0xff737791),
                  ),
                ],
              ),
            ),
          ),
        if (selectedOption == 'أخرى')
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  otherText = value;
                });
                widget.onSelected(otherText);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'اذكرها',
              ),
            ),
          ),
      ],
    );
  }
}

// ويدجت مخصص لعرض تحميل الصور
class ImageUploadWidget extends StatefulWidget {
  final Function(List<XFile>) onImagesSelected;

  const ImageUploadWidget({super.key, required this.onImagesSelected});

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  List<XFile> images = [];

  Future<void> pickImages() async {
    // عرض خيارات للمستخدم: الكاميرا أو المعرض
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(18.0),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('التقاط صورة بالكاميرا'),
                onTap: () async {
                  Navigator.pop(context); // إغلاق الـ Modal
                  await _pickFromCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo),
                title: Text('اختيار من المعرض'),
                onTap: () async {
                  Navigator.pop(context); // إغلاق الـ Modal
                  await _pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // وظيفة لفتح الكاميرا
  Future<void> _pickFromCamera() async {
    // طلب إذن الوصول إلى الكاميرا
    var cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      print("إذن الكاميرا مرفوض.");
      return;
    }

    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        images.add(image);
      });
      widget.onImagesSelected(images);
    } else {
      print("لم يتم التقاط أي صورة.");
    }
  }

  // وظيفة لاختيار الصور من المعرض
  Future<void> _pickFromGallery() async {
    // طلب إذن الوصول إلى معرض الصور
    var storageStatus = await Permission.photos.request();
    if (!storageStatus.isGranted) {
      print("إذن معرض الصور مرفوض.");
      return;
    }

    final ImagePicker _picker = ImagePicker();
    final List<XFile>? pickedImages = await _picker.pickMultiImage();

    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        images.addAll(pickedImages);
      });
      widget.onImagesSelected(images);
    } else {
      print("لم يتم اختيار أي صور.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10, // المسافة الأفقية بين الصور
      runSpacing: 10, // المسافة الرأسية بين الصور
      children: [
        GestureDetector(
          onTap: pickImages,
          child: DottedBorder(
            borderType: BorderType.RRect,
            radius: Radius.circular(8),
            padding: EdgeInsets.all(6),
            color: Color(0xff702DFF),
            child: ClipRRect(
              borderRadius: BorderRadius.all(
                Radius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/png/camera.png',
                      width: 50,
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Text(
                      'التقط / حمل \nصورة',
                      style: TextStyle(
                        color: Color(0xff702DFF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ...images.map((image) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.all(
                  Radius.circular(12),
                ),
                child: Image.file(
                  File(image.path),
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      images.remove(image);
                    });
                    widget.onImagesSelected(images);
                  },
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                top: 10,
                child: GestureDetector(
                  onTap: () async {
                    // افتح واجهة تعديل الصورة
                    final editedImagePath = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditImageScreen(
                          imagePath: image.path,
                        ),
                      ),
                    );

                    if (editedImagePath != null && editedImagePath is String) {
                      setState(() {
                        int index = images.indexOf(image);
                        images[index] = XFile(editedImagePath);
                      });
                      widget.onImagesSelected(images);
                    }
                  },
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.edit,
                      size: 14,
                      color: Color(0xff230B34),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}

// ويدجت مخصص لإدخال نصوص
class TextInputWidget extends StatefulWidget {
  final String label;
  final String placeholder;
  final Function(String) onTextChanged;

  const TextInputWidget({
    super.key,
    required this.label,
    required this.placeholder,
    required this.onTextChanged,
  });

  @override
  State<TextInputWidget> createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _controller,
          onChanged: widget.onTextChanged,
          decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              hintText: widget.placeholder,
              hintStyle: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              )),
          maxLines: widget.label == 'وصف المشكلة' ? 5 : 1,
        ),
      ],
    );
  }
}

// ويدجت التقرير النهائي
class SummaryWidget extends StatelessWidget {
  final Map<int, dynamic> answers;

  const SummaryWidget({super.key, required this.answers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تقرير',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        ...answers.entries.map((entry) {
          String displayText = '';

          if (entry.value is List<XFile>) {
            displayText =
                '${(entry.value as List<XFile>).length} صورة تم تحميلها';
          } else {
            displayText = entry.value.toString();
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'الخطوة ${entry.key + 1}: $displayText',
              style: TextStyle(fontSize: 16),
            ),
          );
        }).toList(),
      ],
    );
  }
}
