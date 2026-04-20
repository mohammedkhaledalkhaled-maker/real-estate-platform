import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // ✅ Auto Scroll
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_controller.hasClients) {
        _currentPage = (_currentPage + 1) % 4; // عدد الأعضاء
        _controller.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _openWhatsApp(String phone, String name) async {
    var phoneClean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phoneClean.startsWith("0")) {
      phoneClean = phoneClean.substring(1);
    }
    if (!phoneClean.startsWith("963")) {
      phoneClean = "963$phoneClean";
    }

    final msg = Uri.encodeComponent("مرحباً، أنا مهتم بالتواصل مع $name");
    final url = "https://wa.me/$phoneClean?text=$msg";
    final uri = Uri.parse(url);

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _memberCard({
    required String name,
    required String role,
    required String desc,
    required String phone,
    required String photoUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF003366), width: 0),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),

              // ✅ الاسم
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // ✅ الدور
              Text(
                role,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ✅ الوصف
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // ✅ زر واتساب
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _openWhatsApp(phone, name),
                  icon: Image.network(
                    "https://estatealshamal.tech/uploads/whats.png",
                    width: 22,
                    height: 22,
                    color: Colors.green,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  label: const Text(
                    "تواصل عبر واتساب",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("الفريق"),
          backgroundColor: const Color(0xFF003366),
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                },
                children: [
                  _memberCard(
                    name: "المهندس محمد خالد تشرين الخالد",
                    role: "مبرمج تطبيقات Flutter",
                    desc:
                        "المهندس المسؤول عن برمجة تطبيق الموبايل بحيث يكون التطبيق سلس وسريع اثناء الاستخدام ليوفر تجربة فريدة للعملاء",
                    phone: "963953779499",
                    photoUrl: "https://estatealshamal.tech/uploads/team1.jpg",
                  ),
                  _memberCard(
                    name: "المهندس محمد جنيد الحسين",
                    role: "مطور ويب Laravel",
                    desc:
                        "المهندس المسؤول عن تطوير واجهة برمجة التطبيقات (API) باستخدام Laravel، ويهتم بأمان واستقرار الخوادم.",
                    phone: "963995328036",
                    photoUrl: "https://picsum.photos/200?random=2",
                  ),
                  _memberCard(
                    name: "المهندس عبدالرحمن محمد بركات",
                    role: "مسؤول عن برمجة موقع الويب",
                    desc:
                        "المهندس المسؤول عن برمجة موقع الويب باستخدام JavaScript بحيث يجعل تجربة العملاء للموقع سهلة وسريعة",
                    phone: "905374515869",
                    photoUrl: "https://estatealshamal.tech/uploads/team.jpg",
                  ),
                  _memberCard(
                    name: "المهندس سعد حسن منصور",
                    role: "مسؤول عن تصميم موقع الويب",
                    desc:
                        "المهندس المسؤول عن تصميم الواجهات في موقع الويب باستخدام HTML , CSS",
                    phone: "17208607319",
                    photoUrl: "https://estatealshamal.tech/uploads/team2.jpg",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SmoothPageIndicator(
              controller: _controller,
              count: 4,
              effect: const ExpandingDotsEffect(
                activeDotColor: Color(0xFF003366),
                dotColor: Colors.grey,
                dotHeight: 10,
                dotWidth: 10,
                spacing: 6,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
