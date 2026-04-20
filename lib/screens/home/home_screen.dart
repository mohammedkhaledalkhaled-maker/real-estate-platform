import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:real/screens/blog/blog_list_screen.dart';
import 'package:real/screens/pages/about_screen.dart';
import 'package:real/screens/pages/pricing_screen.dart';
import '../team_screen.dart';

import '../location/location_properties_screen.dart';
import '../property/property_details_screen.dart';
import '../agents/agents_screen.dart';
import '../categories/categories_screen.dart';
import '../account/account_screen.dart';
import '../wishlist_service.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.token, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> homeProps = [];
  List<Map<String, dynamic>> locations = [];
  List<Map<String, dynamic>> allProps = [];
  List<Map<String, dynamic>> searchResults = [];
  Set<int> wishlist = {}; // IDs المفضلة
  late WishlistService _wishlistService;

  TextEditingController searchController = TextEditingController();
  bool loading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _wishlistService = WishlistService(widget.token);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    try {
      await Future.wait([
        _fetchHome(),
        _fetchAllProperties(),
        _fetchWishlist(),
      ]);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _fetchHome() async {
    final res = await http.get(
      Uri.parse("https://estatealshamal.tech/api/v1/home"),
      headers: {"Accept": "application/json"},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      homeProps = (data["strip_properties"] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      locations = (data["locations"] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }

  Future<void> _fetchAllProperties() async {
    final res = await http.get(
      Uri.parse("https://estatealshamal.tech/api/v1/properties/search"),
      headers: {"Accept": "application/json"},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = (data is Map && data["data"] is List)
          ? data["data"]
          : (data is List ? data : (data["properties"] ?? []));
      allProps =
          (list as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }

  Future<void> _fetchWishlist() async {
    final items = await _wishlistService.getWishlist();
    setState(() {
      wishlist = items.map<int>((e) => e["id"] as int).toSet();
    });
  }

  Future<void> _toggleWishlist(int id) async {
    final isFav = wishlist.contains(id);
    setState(() {
      if (isFav) {
        wishlist.remove(id);
      } else {
        wishlist.add(id);
      }
    });

    bool ok;
    if (isFav) {
      ok = await _wishlistService.removeFromWishlist(id);
    } else {
      ok = await _wishlistService.addToWishlist(id);
    }

    if (!ok) {
      setState(() {
        if (isFav) {
          wishlist.add(id);
        } else {
          wishlist.remove(id);
        }
      });
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }
    final q = query.toLowerCase();
    final all = [...homeProps, ...allProps];
    setState(() {
      searchResults = all.where((p) {
        final name = (p["name"] ?? "").toString().toLowerCase();
        final address = (p["address"] ?? "").toString().toLowerCase();
        return name.contains(q) || address.contains(q);
      }).toList();
    });
  }

  Widget _buildHomeTab() {
    final sortedHome = [...homeProps]..sort((a, b) {
        final da = DateTime.tryParse(a["created_at"] ?? "") ?? DateTime(1970);
        final db = DateTime.tryParse(b["created_at"] ?? "") ?? DateTime(1970);
        return db.compareTo(da);
      });
    final latestTop = sortedHome.take(5).toList();

    final topIds = latestTop.map((e) => e["id"]).toSet();
    final others = allProps.where((p) => !topIds.contains(p["id"])).toList();

    if (loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "ابحث بالاسم أو الموقع...",
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          if (searchResults.isNotEmpty) ...[
            const _SectionHeader(title: "نتائج البحث"),
            Column(
              children: searchResults.map((p) {
                final id = p["id"];
                final isFav = wishlist.contains(id);
                final purpose = (p["purpose"] ?? "").toString();
                return _PropertyListCard(
                  property: p,
                  isFav: isFav,
                  purpose: purpose,
                  onFavToggle: () => _toggleWishlist(id),
                  onTap: () {
                    final slug = p["slug"];
                    if (slug != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PropertyDetailsScreen(
                            slug: slug,
                            token: widget.token,
                          ),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ],
          if (latestTop.isNotEmpty) ...[
            const _SectionHeader(title: "العقارات المضافة حديثاً"),
            CarouselSlider(
              options: CarouselOptions(
                height: 220,
                viewportFraction: 0.9,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                enlargeCenterPage: true,
              ),
              items: latestTop.map((p) {
                final id = p["id"];
                final isFav = wishlist.contains(id);
                final purpose = (p["purpose"] ?? "").toString();
                return _PropertyGridCard(
                  property: p,
                  isFav: isFav,
                  purpose: purpose,
                  onFavToggle: () => _toggleWishlist(id),
                  onTap: () {
                    final slug = p["slug"];
                    if (slug != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PropertyDetailsScreen(
                            slug: slug,
                            token: widget.token,
                          ),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ],
          if (locations.isNotEmpty) ...[
            const _SectionHeader(title: "المحافظات"),
            CarouselSlider(
              options: CarouselOptions(
                height: 150,
                viewportFraction: 0.45,
                enlargeCenterPage: true,
                autoPlay: true,
              ),
              items: locations.map((loc) {
                return _LocationCard(loc: loc, token: widget.token);
              }).toList(),
            ),
          ],
          if (others.isNotEmpty) ...[
            const _SectionHeader(title: "جميع العقارات"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: others.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 240,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, i) {
                  final id = others[i]["id"];
                  final isFav = wishlist.contains(id);
                  final purpose = (others[i]["purpose"] ?? "").toString();
                  return _PropertyGridCard(
                    property: others[i],
                    isFav: isFav,
                    purpose: purpose,
                    onFavToggle: () => _toggleWishlist(id),
                    onTap: () {
                      final slug = others[i]["slug"];
                      if (slug != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PropertyDetailsScreen(
                              slug: slug,
                              token: widget.token,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        _buildHomeTab(),
        AgentsScreen(token: widget.token),
        CategoriesScreen(token: widget.token),
        AccountScreen(user: widget.user, token: widget.token),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: const Text("عقارات الشمال"),
          backgroundColor: const Color(0xFF003366),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                if (v == 'about') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                } else if (v == 'blog') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BlogListScreen()),
                  );
                } else if (v == 'team') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeamScreen()),
                  );
                } else if (v == 'pricing') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PricingScreen()),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'about',
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('من نحن'),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'blog',
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        Icon(Icons.article_outlined, color: Colors.green),
                        SizedBox(width: 8),
                        Text('المدونة'),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'team',
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        Icon(Icons.group_outlined, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('الفريق'),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'pricing',
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('الأسعار'),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF003366),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "الرئيسية"),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: "الوكلاء"),
            BottomNavigationBarItem(
                icon: Icon(Icons.category), label: "الفئات"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "حسابي"),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003366),
          ),
        ),
      );
}

class _LocationCard extends StatelessWidget {
  final Map<String, dynamic> loc;
  final String token;

  const _LocationCard({required this.loc, required this.token});

  @override
  Widget build(BuildContext context) {
    final name = loc["name"] ?? "";
    final slug = loc["slug"];
    final photo = loc["photo"];
    return InkWell(
      onTap: () {
        if (slug != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LocationPropertiesScreen(
                  slug: slug, name: name, token: token),
            ),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                "https://estatealshamal.tech/uploads/$photo",
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(6),
                child: Text(name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _PropertyGridCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback onTap;
  final VoidCallback onFavToggle;
  final bool isFav;
  final String purpose;

  const _PropertyGridCard({
    required this.property,
    required this.onTap,
    required this.onFavToggle,
    required this.isFav,
    required this.purpose,
  });

  @override
  Widget build(BuildContext context) {
    final img = property["featured_photo_url"] ?? "";
    final name = property["name"] ?? "";
    final address = property["address"] ?? "";
    final price = property["price"] ?? "--";

    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.network(img,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey[300])),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text("السعر: \$$price",
                          style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.white,
                ),
                onPressed: onFavToggle,
              ),
            ),
            if (purpose.isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: purpose == "rent" ? Colors.orange : Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    purpose == "rent" ? "للإيجار" : "للبيع",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PropertyListCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback onTap;
  final VoidCallback onFavToggle;
  final bool isFav;
  final String purpose;

  const _PropertyListCard({
    required this.property,
    required this.onTap,
    required this.onFavToggle,
    required this.isFav,
    required this.purpose,
  });

  @override
  Widget build(BuildContext context) {
    final img = property["featured_photo_url"] ?? "";
    final name = property["name"] ?? "";
    final address = property["address"] ?? "";
    final price = property["price"] ?? "--";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(img,
              width: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300])),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(address, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text("السعر: \$$price",
                style: const TextStyle(color: Color(0xFFD4AF37))),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : Colors.grey,
              ),
              onPressed: onFavToggle,
            ),
            if (purpose.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: purpose == "rent" ? Colors.orange : Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  purpose == "rent" ? "للإيجار" : "للبيع",
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
