import 'package:flutter/material.dart';
import 'post_detail_screen.dart';

class BlogDetailScreen extends StatelessWidget {
  final String title;
  final List posts;

  const BlogDetailScreen({
    super.key,
    required this.title,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: "Cairo",
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF003366),
        ),
        body: posts.isEmpty
            ? const Center(
                child: Text(
                  "لا توجد مقالات",
                  style: TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final p = posts[index];
                  final imageUrl = p["photo"] != null
                      ? "https://estatealshamal.tech/uploads/${p["photo"]}"
                      : "https://via.placeholder.com/600x300";
                  final title = p["title"] ?? "";
                  final short = p["short_description"] ?? "";

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // صورة المقال
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            imageUrl,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // العنوان
                              Text(
                                title,
                                style: const TextStyle(
                                  fontFamily: "Cairo",
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003366),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // الوصف القصير
                              if (short.isNotEmpty)
                                Text(
                                  short,
                                  style: const TextStyle(
                                    fontFamily: "Cairo",
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              const SizedBox(height: 12),

                              // زر "اقرأ المزيد"
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PostDetailScreen(
                                          slug:
                                              p["slug"], // نمرر فقط slug المقال
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "اقرأ المزيد",
                                    style: TextStyle(
                                      fontFamily: "Cairo",
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
