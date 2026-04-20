import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: const Text("من نحن"),
          backgroundColor: const Color(0xFF003366),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ✅ العنوان الرئيسي
            const Text(
              "لماذا عقارات الشمال؟",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // ✅ النص التعريفي
            const Text(
              "منصة عقارية سورية مرخصة لبيع وشراء وتأجير العقارات في جميع المحافظات.\n\n"
              "نقدم البساطة والوضوح، ونجعل تجربة نشر وإدارة العقارات سهلة وموثوقة، "
              "مع دعم مستمر للوكلاء والمستخدمين.",
              style: TextStyle(fontSize: 16, height: 1.6),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // ✅ قسم كيف يعمل؟
            const Text(
              "كيف يعمل؟",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 0.8, // 👈 جعل البطاقات أطول
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: const [
                _StepCard(
                  icon: Icons.person_add,
                  title: "سجل",
                  text:
                      "قم بإنشاء حسابك خلال دقائق وسجل دخولك لبدء استخدام المنصة بسهولة.",
                ),
                _StepCard(
                  icon: Icons.assignment,
                  title: "أكمل ملفك",
                  text:
                      "أدخل بياناتك ووثائقك لتصبح وكيلاً معتمدًا وتبدأ بنشر العقارات.",
                ),
                _StepCard(
                  icon: Icons.home_work,
                  title: "أضف عقارك",
                  text:
                      "أدخل تفاصيل عقارك وصورًا عالية الجودة ليظهر في موقعنا بسهولة.",
                ),
                _StepCard(
                  icon: Icons.check_circle,
                  title: "استقبل العروض",
                  text:
                      "تواصل مع المهتمين وحدد مواعيد للإيجار أو البيع بسهولة وسرعة.",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ ويدجت لبطاقات الخطوات
class _StepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _StepCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF003366)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF003366),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
