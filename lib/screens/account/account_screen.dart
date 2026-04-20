import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:real/screens/auth/login_screen.dart';

import 'edit_profile_screen.dart';
import 'wishlist_screen.dart';

class AccountScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;

  const AccountScreen({super.key, required this.user, required this.token});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Map<String, dynamic> user;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    user = Map<String, dynamic>.from(widget.user);
  }

  /// ✅ جلب بيانات المستخدم
  Future<void> _fetchUser() async {
    setState(() => loading = true);
    try {
      final res = await http.get(
        Uri.parse("https://estatealshamal.tech/api/v1/user"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Accept": "application/json",
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          user = data;
        });
      } else {
        debugPrint("❌ فشل جلب المستخدم: ${res.body}");
      }
    } catch (e) {
      debugPrint("⚠️ خطأ في جلب المستخدم: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundImage: user['photo'] != null
                          ? NetworkImage(user['photo'])
                          : null,
                      child: user['photo'] == null
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 15),

                    // ✅ الاسم
                    Text(
                      user['name'] ?? "مستخدم",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                    ),

                    // ✅ البريد
                    Text(
                      user['email'] ?? "-",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 25),

                    _buildInfoTile(Icons.person, "اسم المستخدم",
                        user['username']?.toString() ?? "-"),

                    const SizedBox(height: 25),

                    _buildButton(
                      label: "المفضلة",
                      icon: Icons.favorite,
                      color: Colors.red,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WishlistScreen(token: widget.token),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildButton(
                      label: "تعديل الملف الشخصي",
                      icon: Icons.edit,
                      color: const Color(0xFF003366),
                      onPressed: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(
                                user: user, token: widget.token),
                          ),
                        );

                        if (updated != null && updated is bool && updated) {
                          _fetchUser();
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // زر تسجيل الخروج
                    _buildButton(
                      label: "تسجيل الخروج",
                      icon: Icons.logout,
                      color: const Color(0xFF003366),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("تأكيد تسجيل الخروج"),
                            content: const Text(
                                "هل أنت متأكد أنك تريد تسجيل الخروج؟"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("إلغاء"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003366),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("تسجيل الخروج"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF003366)),
        title: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black87)),
        subtitle: Text(value, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: "Cairo",
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}
