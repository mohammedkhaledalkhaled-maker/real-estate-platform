import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class PostDetailScreen extends StatefulWidget {
  final String slug;

  const PostDetailScreen({super.key, required this.slug});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? post;
  List comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  Future<void> _fetchPost() async {
    try {
      final res = await http.get(
        Uri.parse("https://estatealshamal.tech/api/v1/blog/${widget.slug}"),
        headers: {"Accept": "application/json"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          post = data["post"];
          comments = post?["comments"] ?? [];
          loading = false;
        });
      } else {
        setState(() {
          error = "فشل تحميل المقال";
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

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final comment = _commentController.text.trim();

    try {
      final res = await http.post(
        Uri.parse(
            "https://estatealshamal.tech/api/v1/blog/${widget.slug}/comments"),
        headers: {"Accept": "application/json"},
        body: {"body": comment}, // ✅ حسب API الحقل اسمه body
      );

      if (res.statusCode == 200) {
        _commentController.clear();
        _fetchPost(); // إعادة تحميل التعليقات
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تمت إضافة التعليق ✅")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("فشل إرسال التعليق ❌")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(post?["title"] ?? "تفاصيل المقال"),
          backgroundColor: const Color(0xFF003366),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text(error!))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post?["photo"] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              "https://estatealshamal.tech/uploads/${post!["photo"]}",
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(height: 16),

                        // العنوان
                        Text(
                          post?["title"] ?? "",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // النص
                        HtmlWidget(post?["description"] ?? ""),
                        const SizedBox(height: 20),

                        // التعليقات
                        const Text(
                          "التعليقات",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (comments.isEmpty)
                          const Text("لا توجد تعليقات بعد")
                        else
                          Column(
                            children: comments.map((c) {
                              final name = c["author_name"] ?? "مجهول";
                              final body = c["body"] ?? "";
                              final date = c["created_at"]
                                      ?.toString()
                                      .split("T")
                                      .first ??
                                  "";

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFF003366),
                                    child:
                                        Icon(Icons.person, color: Colors.white),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(body),
                                      const SizedBox(height: 4),
                                      Text(
                                        date,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 20),

                        // إضافة تعليق جديد
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: "أضف تعليقك...",
                                  filled: true,
                                  fillColor:
                                      const Color.fromARGB(102, 121, 100, 224),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addComment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003366),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "إرسال",
                                style: TextStyle(
                                    color: Color.fromARGB(255, 253, 254, 255)),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
