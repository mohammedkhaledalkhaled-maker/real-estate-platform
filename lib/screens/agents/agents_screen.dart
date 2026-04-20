import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'agent_detail_screen.dart';

class AgentsScreen extends StatefulWidget {
  final String token; // ✅ أضفنا التوكن هنا

  const AgentsScreen({super.key, required this.token});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  final String baseUrl = "https://estatealshamal.tech";

  bool loading = true;
  bool loadingMore = false;
  String? error;

  List<Map<String, dynamic>> agents = [];
  int currentPage = 1;
  int? lastPage;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAgents();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (loadingMore || loading) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      if (lastPage != null && currentPage < lastPage!) {
        _fetchAgents(nextPage: currentPage + 1);
      }
    }
  }

  Future<void> _fetchAgents({int? nextPage, bool clear = false}) async {
    setState(() {
      error = null;
      if (nextPage == null || clear) {
        loading = true;
        if (clear) {
          currentPage = 1;
          lastPage = null;
          agents.clear();
        }
      } else {
        loadingMore = true;
      }
    });

    final page = nextPage ?? currentPage;
    final uri = Uri.parse("$baseUrl/api/v1/agents?page=$page");

    try {
      final res = await http.get(uri, headers: {"Accept": "application/json"});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final list = (data is Map && data["data"] is List)
            ? (data["data"] as List)
            : (data is List)
                ? data
                : <dynamic>[];

        final newAgents =
            list.map((e) => Map<String, dynamic>.from(e)).toList();

        setState(() {
          if (page == 1) {
            agents = newAgents;
          } else {
            agents.addAll(newAgents);
          }

          currentPage = (data is Map && data["current_page"] is int)
              ? data["current_page"]
              : page;
          lastPage = (data is Map && data["last_page"] is int)
              ? data["last_page"]
              : currentPage;
        });
      } else {
        error = "تعذّر جلب البيانات (${res.statusCode})";
      }
    } catch (e) {
      error = "خطأ في الاتصال: $e";
    }

    setState(() {
      loading = false;
      loadingMore = false;
    });
  }

  String _photoUrl(String? file) {
    if (file == null || file.isEmpty) return "";
    if (file.startsWith("http")) return file;
    return "$baseUrl/uploads/$file";
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // ✅ أزلنا الـ AppBar هنا
        backgroundColor: Colors.white,
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
                            onPressed: () => _fetchAgents(clear: true),
                            child: const Text("إعادة المحاولة"),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _fetchAgents(clear: true),
                    child: agents.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text("لا يوجد وكلاء حالياً")),
                            ],
                          )
                        : GridView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: .9,
                            ),
                            itemCount: agents.length + (loadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= agents.length) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              final a = agents[index];
                              final name = a["name"] ?? a["username"] ?? "وكيل";
                              final img = _photoUrl(a["photo"]);
                              final count =
                                  a["properties_count"] ?? a["ads_count"];

                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AgentDetailScreen(
                                        agentId: a["id"],
                                        token: widget.token,
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 10),
                                      Stack(
                                        alignment: Alignment.topLeft,
                                        children: [
                                          CircleAvatar(
                                            radius: 36,
                                            backgroundColor:
                                                const Color(0x11003366),
                                            backgroundImage: img.isEmpty
                                                ? null
                                                : NetworkImage(img),
                                            child: img.isEmpty
                                                ? const Icon(Icons.person,
                                                    size: 36,
                                                    color: Color(0xFF003366))
                                                : null,
                                          ),
                                          if (count != null)
                                            Positioned(
                                              top: -2,
                                              left: -2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF6F42C1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  "$count عقار",
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      height: 1),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        "وكيل معتمد",
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12),
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
