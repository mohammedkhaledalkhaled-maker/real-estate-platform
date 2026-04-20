import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';

import '../agents/agent_detail_screen.dart';
import '../location/location_properties_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final String slug;
  final String token;

  const PropertyDetailsScreen({
    super.key,
    required this.slug,
    required this.token,
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  static const String baseUrl = "https://estatealshamal.tech";
  bool loading = true;
  String? error;
  Map<String, dynamic>? property;
  List<Map<String, dynamic>> related = [];
  Map<String, dynamic>? mapData;
  List amenities = [];
  List videos = [];
  bool isFav = false;

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
      final encodedSlug = Uri.encodeComponent(widget.slug);
      final uri = Uri.parse("$baseUrl/api/v1/property/$encodedSlug");

      final res = await http.get(uri, headers: {"Accept": "application/json"});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data is Map && data["property"] is Map) {
          property = Map<String, dynamic>.from(data["property"]);

          // هل العقار في المفضلة؟
          isFav = property?["is_wishlist"] == true;

          if (data["related"] is List) {
            related = (data["related"] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }

          if (data["map"] is Map) {
            mapData = Map<String, dynamic>.from(data["map"]);
          }

          if (data["amenities"] is List) {
            amenities = data["amenities"];
          }

          if (data["property"]["videos"] is List) {
            videos = data["property"]["videos"];
          }
        } else {
          error = "استجابة غير متوقعة من السيرفر.";
        }
      } else {
        error = "تعذّر جلب البيانات (${res.statusCode}).";
      }
    } catch (e) {
      error = "خطأ في الاتصال: $e";
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> _toggleWishlist(int id) async {
    final wasFav = isFav;
    setState(() => isFav = !wasFav);

    try {
      final url = wasFav
          ? "$baseUrl/api/v1/user/wishlist/$id"
          : "$baseUrl/api/v1/wishlist/$id";

      final res = await (wasFav
          ? http.delete(Uri.parse(url), headers: {
              "Accept": "application/json",
              "Authorization": "Bearer ${widget.token}",
            })
          : http.post(Uri.parse(url), headers: {
              "Accept": "application/json",
              "Authorization": "Bearer ${widget.token}",
            }));

      if (res.statusCode >= 400) {
        // رجّع الحالة لو صار خطأ
        setState(() => isFav = wasFav);
      }
    } catch (e) {
      setState(() => isFav = wasFav);
    }
  }

  List<String> _extractPhotos(Map<String, dynamic> p) {
    final List<String> photos = [];
    if (p["featured_photo_url"] != null) {
      photos.add(p["featured_photo_url"]);
    }
    if (p["photos"] is List) {
      for (final v in p["photos"]) {
        if (v is Map && v["url"] != null) photos.add(v["url"]);
      }
    }
    return photos;
  }

  @override
  Widget build(BuildContext context) {
    final p = property ?? {};

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF003366),
          title: Text(p["name"]?.toString() ?? "تفاصيل العقار"),
          actions: [
            if (p["id"] != null)
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.white,
                ),
                onPressed: () => _toggleWishlist(p["id"]),
              ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text(error!))
                : _DetailsContent(
                    property: p,
                    photos: _extractPhotos(p),
                    amenities: amenities,
                    related: related,
                    mapData: mapData,
                    videos: videos,
                    token: widget.token,
                  ),
      ),
    );
  }
}

/* ===================== واجهة العرض ===================== */

class _DetailsContent extends StatefulWidget {
  final Map<String, dynamic> property;
  final List<String> photos;
  final List amenities;
  final List<Map<String, dynamic>> related;
  final Map<String, dynamic>? mapData;
  final List videos;
  final String token;

  const _DetailsContent({
    required this.property,
    required this.photos,
    required this.amenities,
    required this.related,
    required this.mapData,
    required this.videos,
    required this.token,
  });

  @override
  State<_DetailsContent> createState() => _DetailsContentState();
}

class _DetailsContentState extends State<_DetailsContent> {
  int activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final agent = widget.property["agent"] as Map?;
    final location = widget.property["location"] as Map?;

    return ListView(
      children: [
        if (widget.photos.isNotEmpty) ...[
          Column(
            children: [
              CarouselSlider(
                options: CarouselOptions(
                  height: 250,
                  viewportFraction: 1.0,
                  enableInfiniteScroll: false,
                  onPageChanged: (index, reason) {
                    setState(() => activeIndex = index);
                  },
                ),
                items: widget.photos
                    .map((url) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              AnimatedSmoothIndicator(
                activeIndex: activeIndex,
                count: widget.photos.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 6,
                  activeDotColor: Colors.orange,
                  dotColor: Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ],
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.property["name"] ?? "",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(widget.property["address"] ?? "",
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),

              /// ✅ التفاصيل
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _info("السعر", widget.property["price"], Icons.attach_money,
                      suffix: " \$"),
                  _info("المساحة", widget.property["size"], Icons.square_foot,
                      suffix: " م²"),
                  _info("غرف", widget.property["bedroom"], Icons.bed),
                  _info("الحالة", widget.property["purpose"], Icons.house),
                  _info("حمامات", widget.property["bathroom"], Icons.bathtub),
                  _info("الطابق", widget.property["floor"], Icons.layers),
                  _info("كراج", widget.property["garage"], Icons.garage),
                  _info("شرفات", widget.property["balcony"], Icons.balcony),
                  _info("سنة البناء", widget.property["built_year"],
                      Icons.calendar_today),
                  _info("المشاهدات", widget.property["total_views"],
                      Icons.remove_red_eye),
                  _info("المنطقة", widget.property["area"], Icons.map),
                ].whereType<Widget>().toList(),
              ),

              const SizedBox(height: 24),

              /// ✅ الوكيل + طرق التواصل
              if (agent != null) ...[
                _ActionCard(
                  icon: const Icon(Icons.person, color: Color(0xFF003366)),
                  title: "الوكيل",
                  value: agent["name"] ?? "",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AgentDetailScreen(
                          agentId: agent["id"],
                          token: widget.token, // 👈 مرر التوكن
                        ),
                      ),
                    );
                  },
                ),
                if (agent["phone"] != null &&
                    agent["phone"].toString().isNotEmpty)
                  _ActionCard(
                    icon: const Icon(Icons.phone, color: Colors.blue),
                    title: "تواصل",
                    value: "اتصال هاتفي",
                    onTap: () async {
                      final phone = agent["phone"].toString();
                      final uri = Uri(scheme: "tel", path: phone);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                _ActionCard(
                  icon: Image.network(
                    "https://estatealshamal.tech/uploads/whats.png",
                    width: 22,
                    height: 22,
                    color: Colors.green,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  title: "واتساب",
                  value: "تواصل عبر واتساب",
                  onTap: () async {
                    var phone = agent["phone"]
                        .toString()
                        .replaceAll(RegExp(r'[^0-9]'), '');
                    if (phone.startsWith("0")) phone = phone.substring(1);
                    if (!phone.startsWith("963")) {
                      phone = "963$phone";
                    }
                    final msg = Uri.encodeComponent(
                        "مرحباً، أنا مهتم بالعقار: ${widget.property["name"]}");
                    final url = "https://wa.me/$phone?text=$msg";
                    final uri = Uri.parse(url);

                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ],

              if (location != null)
                _ActionCard(
                  icon:
                      const Icon(Icons.location_city, color: Color(0xFF003366)),
                  title: "المحافظة",
                  value: location["name"] ?? "",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LocationPropertiesScreen(
                                slug: location["slug"],
                                name: location["name"],
                                token: widget.token,
                              )),
                    );
                  },
                ),

              if (widget.mapData != null &&
                  widget.mapData!["lat"] != null &&
                  widget.mapData!["lng"] != null)
                _ActionCard(
                  icon: const Icon(Icons.map, color: Colors.blue),
                  title: "الموقع",
                  value: "عرض على الخريطة",
                  onTap: () async {
                    final lat =
                        double.tryParse(widget.mapData!["lat"].toString()) ?? 0;
                    final lng =
                        double.tryParse(widget.mapData!["lng"].toString()) ?? 0;

                    final googleUrl =
                        Uri.parse("geo:$lat,$lng?q=$lat,$lng(العقار)");
                    if (await canLaunchUrl(googleUrl)) {
                      await launchUrl(googleUrl);
                    } else {
                      final fallbackUrl = Uri.parse(
                          "https://www.google.com/maps/search/?api=1&query=$lat,$lng");
                      if (await canLaunchUrl(fallbackUrl)) {
                        await launchUrl(fallbackUrl,
                            mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                ),

              const SizedBox(height: 24),

              if (widget.amenities.isNotEmpty) ...[
                const Text("المزايا",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: widget.amenities
                      .map((e) => Chip(
                            label: Text(e.toString()),
                            backgroundColor: Colors.blue.shade50,
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 24),

              if (widget.videos.isNotEmpty) ...[
                const Text("الفيديو",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Column(
                  children: widget.videos.map((v) {
                    final videoId = v["video"]?.toString().trim();
                    if (videoId == null || videoId.isEmpty) {
                      return const SizedBox();
                    }
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: YoutubePlayer(
                        controller: YoutubePlayerController.fromVideoId(
                          videoId: videoId,
                          autoPlay: false,
                          params: const YoutubePlayerParams(
                            showFullscreenButton: true,
                            enableJavaScript: true,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              ],

              const SizedBox(height: 24),

              if (widget.related.isNotEmpty) ...[
                const Text("عقارات مشابهة",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Column(
                  children: widget.related
                      .map((r) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: r["featured_photo_url"] != null
                                  ? Image.network(
                                      r["featured_photo_url"],
                                      width: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.image, size: 40),
                              title: Text(r["name"] ?? ""),
                              subtitle: Text(
                                  "${r["price"] ?? "--"} | ${r["size"] ?? "--"} م² | ${r["bedroom"] ?? 0} غرف"),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PropertyDetailsScreen(
                                      slug: r["slug"],
                                      token: widget.token,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        )
      ],
    );
  }

  Widget? _info(String label, dynamic value, IconData icon,
      {String suffix = ""}) {
    if (value == null) return null;
    if (value is num && value == 0) return null;
    if (value.toString().isEmpty) return null;

    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.grey),
      label: Text("$label: $value$suffix"),
      backgroundColor: Colors.grey.shade200,
    );
  }
}

class _ActionCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "$title: $value",
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                overflow: TextOverflow.ellipsis, // 👈 يمنع التقطيع العمودي
                maxLines: 1,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
