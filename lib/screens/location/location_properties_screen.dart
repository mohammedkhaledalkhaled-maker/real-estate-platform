import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../property/property_details_screen.dart';

class LocationPropertiesScreen extends StatefulWidget {
  final String slug;
  final String name;
  final String token;

  const LocationPropertiesScreen({
    super.key,
    required this.slug,
    required this.name,
    required this.token,
  });

  @override
  State<LocationPropertiesScreen> createState() =>
      _LocationPropertiesScreenState();
}

class _LocationPropertiesScreenState extends State<LocationPropertiesScreen> {
  final String baseUrl = "https://estatealshamal.tech";
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/v1/locations/${widget.slug}/properties"),
        headers: {"Accept": "application/json"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List list;
        if (data is Map && data["data"] is List) {
          list = data["data"];
        } else if (data is List) {
          list = data;
        } else {
          list = (data["properties"] ?? []) as List;
        }
        items = list.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        error = "تعذّر جلب البيانات (${res.statusCode})";
      }
    } catch (e) {
      error = "خطأ في الاتصال: $e";
    }
    if (mounted) setState(() => loading = false);
  }

  String _img(Map<String, dynamic> it) {
    final u = it["featured_photo_url"] ?? it["photo_url"] ?? it["photo"];
    if (u == null) return "";
    final s = u.toString();
    if (s.startsWith("http")) return s;
    return "$baseUrl/uploads/$s";
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF003366),
          title: Text("عقارات ${widget.name}"),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(height: 8),
                          Text(error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text("إعادة المحاولة"),
                          ),
                        ],
                      ),
                    ),
                  )
                : items.isEmpty
                    ? const Center(
                        child: Text("لا توجد عقارات في هذه المحافظة حالياً"))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: .75,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final it = items[i];
                          return InkWell(
                            onTap: () {
                              final slug = it["slug"]?.toString();
                              if (slug != null && slug.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PropertyDetailsScreen(
                                      slug: slug,
                                      token: widget.token, // 👈 مرر التوكن
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(14)),
                                    child: Image.network(
                                      _img(it),
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                          height: 120, color: Colors.grey[300]),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            it["name"]?.toString() ??
                                                it["title"]?.toString() ??
                                                "",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text(
                                            it["address"]?.toString() ??
                                                it["location"]?.toString() ??
                                                "",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.grey)),
                                        const SizedBox(height: 6),
                                        Text(
                                            "السعر: \$${it["price"] ?? it["amount"] ?? "--"}",
                                            style: const TextStyle(
                                                color: Color(0xFFD4AF37),
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
