import 'package:flutter/material.dart';
import 'package:real/screens/categories/CategoryItemsScreen.dart';

class CategoriesScreen extends StatelessWidget {
  final String token;

  const CategoriesScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5), // خلفية فاتحة
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
            children: [
              _buildCategoryCard(
                context,
                title: "أراضي",
                icon: Icons.terrain,
                endpoint: "https://estatealshamal.tech/api/v1/properties/lands",
              ),
              _buildCategoryCard(
                context,
                title: "سكنية",
                icon: Icons.home,
                endpoint:
                    "https://estatealshamal.tech/api/v1/properties/residential",
              ),
              _buildCategoryCard(
                context,
                title: "تجارية",
                icon: Icons.business,
                endpoint:
                    "https://estatealshamal.tech/api/v1/properties/commercial",
              ),
              _buildCategoryCard(
                context,
                title: "ترفيهية",
                icon: Icons.park,
                endpoint:
                    "https://estatealshamal.tech/api/v1/properties/recreational",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String endpoint,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryItemsScreen(
              title: title,
              endpoint: endpoint,
              token: token, // ✅ تمرير التوكن
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: const Color(0xFF003366), // أزرق غامق
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: "Cairo",
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
