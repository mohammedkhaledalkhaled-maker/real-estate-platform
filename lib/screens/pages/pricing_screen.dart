import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  List plans = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await http.get(
        Uri.parse("https://estatealshamal.tech/api/v1/pricing"),
        headers: {"Accept": "application/json"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data["packages"] is List) {
          plans = data["packages"];
        }
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: const Text("الاشتراكات"),
          backgroundColor: const Color(0xFF003366),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ✅ النص التسويقي في البداية
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Text(
                      "هل تريد أن تصبح وكيلاً وتبدأ بنشر عقاراتك على موقعنا؟ \n\n"
                      "انضم الآن إلى شبكة وكلاء عقارات الشمال، "
                      "واستفد من خططنا المرنة التي تمنحك إمكانية نشر عقاراتك، "
                      " وزيادة وصولك إلى آلاف العملاء الباحثين عن عقار أحلامهم . ",
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF003366),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      childAspectRatio: 3 / 2,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: plans.length,
                    itemBuilder: (_, i) {
                      final p = plans[i] as Map;
                      return _buildPlanCard(p);
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPlanCard(Map p) {
    final String name = p["name"] ?? "خطة";
    final price = p["price"] ?? 0;
    final props = p["allowed_properties"] ?? 0;
    final days = p["allowed_days"] ?? 0;

    // ألوان حسب نوع الخطة
    Color color;
    if (name.toLowerCase() == "gold") {
      color = Colors.orange;
    } else if (name.toLowerCase() == "standard") {
      color = Colors.purple;
    } else {
      color = Colors.indigo;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "\$$price / شهر",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text("عدد العقارات: $props"),
          Text("عدد الأيام: $days"),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () async {
              final uri =
                  Uri.parse("https://estatealshamal.tech/agent/registration");
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text("اختر الخطة"),
          ),
        ],
      ),
    );
  }
}
