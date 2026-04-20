import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;

  const EditProfileScreen({super.key, required this.user, required this.token});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController usernameCtrl;
  late TextEditingController emailCtrl;

  File? pickedImage;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.user['name'] ?? "");
    usernameCtrl = TextEditingController(text: widget.user['username'] ?? "");
    emailCtrl = TextEditingController(text: widget.user['email'] ?? "");
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        pickedImage = File(picked.path);
      });
    }
  }

  /// ✅ دالة لضغط الصورة قبل الرفع
  Future<File?> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = p.join(
      dir.path,
      "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg",
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, // 👈 قلل الجودة (من 50-80 مثالي)
    );

    if (result == null) return null;
    return File(result.path); // ✅ تحويل XFile إلى File
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    final url = Uri.parse("https://estatealshamal.tech/api/v1/user/profile");

    final request = http.MultipartRequest("POST", url);
    request.headers["Authorization"] = "Bearer ${widget.token}";
    request.headers["Accept"] = "application/json";

    // ✅ فقط الحقول المدعومة
    request.fields["name"] = nameCtrl.text;
    request.fields["username"] = usernameCtrl.text;
    request.fields["email"] = emailCtrl.text;

    // ✅ ضغط الصورة قبل الرفع
    if (pickedImage != null) {
      final compressed = await _compressImage(pickedImage!);
      if (compressed != null) {
        request.files.add(
          await http.MultipartFile.fromPath("photo", compressed.path),
        );
      }
    }

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ تم تحديث الملف الشخصي بنجاح")),
        );
        Navigator.pop(context, true); // رجوع وتحديث
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ خطأ: $respStr")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ خطأ في الاتصال: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("تعديل الملف الشخصي"),
          backgroundColor: const Color(0xFF003366),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundImage: pickedImage != null
                        ? FileImage(pickedImage!)
                        : (widget.user['photo'] != null
                            ? NetworkImage(widget.user['photo'])
                            : null) as ImageProvider?,
                    child: (pickedImage == null && widget.user['photo'] == null)
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField("الاسم", nameCtrl),
                _buildTextField("اسم المستخدم", usernameCtrl),
                _buildTextField("البريد", emailCtrl,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : _saveProfile,
                    icon: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text("حفظ التغييرات"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
