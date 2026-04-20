import 'dart:convert';
import 'package:http/http.dart' as http;

class WishlistService {
  final String token;
  WishlistService(this.token);

  static const String baseUrl = "https://estatealshamal.tech/api/v1";

  /// جلب المفضلة
  Future<List<Map<String, dynamic>>> getWishlist() async {
    final res = await http.get(
      Uri.parse("$baseUrl/user/wishlist"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["wishlist"] is List) {
        return (data["wishlist"] as List).map<Map<String, dynamic>>((item) {
          final property = Map<String, dynamic>.from(item["property"]);
          property["wishlist_id"] = item["id"]; // نخزن الـ wishlistId
          return property;
        }).toList();
      }
    }
    return [];
  }

  /// إضافة إلى المفضلة
  Future<bool> addToWishlist(int propertyId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/wishlist/$propertyId"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    return res.statusCode == 201;
  }

  /// حذف من المفضلة
  Future<bool> removeFromWishlist(int wishlistId) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/user/wishlist/$wishlistId"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    return res.statusCode == 200;
  }
}
