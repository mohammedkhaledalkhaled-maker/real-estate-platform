import 'package:flutter/material.dart';
import '../../screens/property/property_details_screen.dart';
import '../../screens/wishlist_service.dart';

class WishlistScreen extends StatefulWidget {
  final String token;
  const WishlistScreen({super.key, required this.token});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late WishlistService _service;
  bool loading = true;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _service = WishlistService(widget.token);
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    items = await _service.getWishlist();
    setState(() => loading = false);
  }

  Future<void> _remove(int wishlistId) async {
    final ok = await _service.removeFromWishlist(wishlistId);
    if (ok) {
      setState(() {
        items.removeWhere((e) => e["wishlist_id"] == wishlistId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("المفضلة"),
          backgroundColor: const Color(0xFF003366),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? const Center(child: Text("لا توجد عقارات مفضلة"))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final p = items[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: p["featured_photo_url"] != null
                              ? Image.network(p["featured_photo_url"],
                                  width: 60, fit: BoxFit.cover)
                              : const Icon(Icons.home),
                          title: Text(p["name"] ?? ""),
                          subtitle: Text(p["address"] ?? ""),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _remove(p["wishlist_id"]),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PropertyDetailsScreen(
                                  slug: p["slug"],
                                  token: widget.token, // ✅ أضفنا التوكن
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
