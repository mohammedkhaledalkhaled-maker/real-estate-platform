import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'blog_detail_screen.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  bool loading = true;
  String? error;
  List types = [];
  List posts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await http.get(
        Uri.parse("https://estatealshamal.tech/api/v1/blog"),
        headers: {"Accept": "application/json"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          types = data["types"] ?? []; // ✅ كل الأقسام
          posts = data["posts"]["data"] ?? [];
          loading = false;
        });
      } else {
        setState(() {
          error = "فشل تحميل البيانات";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "خطأ: $e";
        loading = false;
      });
    }
  }

  // ✅ أيقونات الأقسام الرئيسية
  final Map<String, IconData> categoryIcons = {
    "residential": Icons.home, // سكني
    "commercial": Icons.business, // تجاري وخدمي
    "recreational": Icons.park, // ترفيهي
    "lands": Icons.terrain, // أراضي
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text("المدونة"),
          backgroundColor: const Color(0xFF003366),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text(error!))
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: types.length,
                      itemBuilder: (context, index) {
                        final type = types[index];
                        final name = type["name"] ?? "";
                        final slug = type["slug"] ?? "";
                        final image = type["image"];
                        final icon = categoryIcons[slug] ?? Icons.category;

                        return GestureDetector(
                          onTap: () {
                            final filtered = posts
                                .where((p) =>
                                    p["type"]["id"].toString() ==
                                    type["id"].toString())
                                .toList();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlogDetailScreen(
                                  title: name,
                                  posts: filtered,
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
                                if (image != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      "https://estatealshamal.tech/uploads/$image",
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  Icon(
                                    icon,
                                    size: 48,
                                    color: const Color(0xFF003366),
                                  ),
                                const SizedBox(height: 12),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: "Cairo",
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF003366),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
