import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// صفحة التفاصيل
import '../property/property_details_screen.dart';

class AgentDetailScreen extends StatefulWidget {
  final int agentId;
  final String token;

  const AgentDetailScreen(
      {super.key, required this.agentId, required this.token});

  @override
  State<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

class _AgentDetailScreenState extends State<AgentDetailScreen> {
  final String baseUrl = "https://estatealshamal.tech";
  bool loading = true;

  Map<String, dynamic>? agent;
  List<Map<String, dynamic>> properties = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/v1/agents/${widget.agentId}"),
        headers: {"Accept": "application/json"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        Map<String, dynamic>? ag;
        List props = [];

        if (data is Map && data["agent"] is Map) {
          ag = Map<String, dynamic>.from(data["agent"]);
          if (data["properties"] is List) props = data["properties"];
        } else if (data is Map) {
          ag = Map<String, dynamic>.from(data);
          if (data["properties"] is List) props = data["properties"];
        }

        agent = ag;
        properties = props.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint("Agent detail error: $e");
    }
    if (mounted) setState(() => loading = false);
  }

  String _photoUrl(String? file) {
    if (file == null || file.isEmpty) return "";
    if (file.startsWith("http")) return file;
    return "$baseUrl/uploads/$file";
  }

  @override
  Widget build(BuildContext context) {
    final a = agent ?? {};

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(a["name"] ?? "الوكيل"),
          backgroundColor: const Color(0xFF003366),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  children: [
                    _AgentHeader(
                      name: a["name"] ?? a["username"] ?? "وكيل",
                      photoUrl: _photoUrl(a["photo"]),
                      city: a["city"],
                      phone: a["phone"],
                      email: a["email"],
                      bio: a["biography"],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(
                        children: const [
                          Icon(Icons.home, color: Color(0xFF003366)),
                          SizedBox(width: 8),
                          Text(
                            "الإعلانات المنشورة",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF003366),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (properties.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: .75,
                          ),
                          itemCount: properties.length,
                          itemBuilder: (_, i) => _PropertyCard(
                            item: properties[i],
                            token: widget.token,
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text("لا توجد عقارات لهذا الوكيل حالياً"),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AgentHeader extends StatelessWidget {
  final String name;
  final String photoUrl;
  final String? city;
  final String? phone;
  final String? email;
  final String? bio;

  const _AgentHeader({
    required this.name,
    required this.photoUrl,
    this.city,
    this.phone,
    this.email,
    this.bio,
  });

  /// ✅ فتح تطبيق الهاتف
  void _callPhone(String number) async {
    final Uri uri = Uri(scheme: "tel", path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0x11003366),
              backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
              child: photoUrl.isEmpty
                  ? const Icon(Icons.person, size: 40, color: Color(0xFF003366))
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF003366)),
            ),
            const SizedBox(height: 6),
            if (city != null && city!.isNotEmpty)
              Text(city!,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
            if (bio != null && bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  bio!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ),
            const Divider(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                if (phone != null && phone!.isNotEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.phone),
                    label: const Text("اتصال"),
                    onPressed: () => _callPhone(phone!),
                  ),
                if (email != null && email!.isNotEmpty)
                  _InfoChip(icon: Icons.email, text: email!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF003366)),
      label: Text(text),
      side: const BorderSide(color: Color(0x22003366)),
      backgroundColor: Colors.white,
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String token;

  const _PropertyCard({required this.item, required this.token});

  String _img() {
    final u = item["featured_photo_url"] ?? item["photo_url"] ?? item["photo"];
    if (u == null) return "";
    final s = u.toString();
    if (s.startsWith("http")) return s;
    return "https://estatealshamal.tech/uploads/$s";
  }

  void _openDetails(BuildContext context) {
    final slug = item["slug"]?.toString();
    if (slug != null && slug.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PropertyDetailsScreen(
            slug: slug,
            token: token,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لا يتوفر معرف (slug) لهذا العقار.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _img();
    final name = item["name"] ?? item["title"] ?? "";
    final price = item["price"] ?? item["amount"] ?? "--";
    final address = item["address"] ?? item["location"] ?? "";

    return InkWell(
      onTap: () => _openDetails(context),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                img,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 120, color: Colors.grey[300]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text("السعر: \$$price",
                      style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
