import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../common/service_call.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ImagePicker picker = ImagePicker();
  XFile? image;
  Uint8List? selectedAvatarBytes;

  late String userName;
  late String userEmail;
  late String userMobile;
  String userAvatarUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchProfile(); // Fetch live data to override any cached info
  }

  void _loadUserInfo() {
    final payload = ServiceCall.userPayload;
    userName = (payload['fullName'] ?? payload['name'] ?? '').toString().trim();
    userEmail = (payload['email'] ?? '').toString().trim();
    userMobile = (payload['mobile'] ?? payload['phone'] ?? '').toString().trim();
    userAvatarUrl = (payload['avatarUrl'] ?? '').toString().trim();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await ServiceCall.fetchGet(SVKey.svCustomerProfile, isToken: true);
      if (response != null && response['success'] == true) {
         final data = response['data'] as Map;
         final normalized = Map<String, dynamic>.from(ServiceCall.userPayload);
         normalized.addAll(Map<String, dynamic>.from(data));
         
         ServiceCall.userPayload = normalized;
         Globs.udSet(normalized, Globs.userPayload);
         
         if (mounted) {
            setState(() {
               _loadUserInfo();
            });
         }
      }
    } catch (e) {
      debugPrint('Loi tai profile: $e');
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return;
    }

    final pickedBytes = await picked.readAsBytes();

    setState(() {
      image = picked;
      selectedAvatarBytes = pickedBytes;
    });

    final authToken = Globs.udValueString(KKey.authToken);
    if (authToken.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ban can dang nhap lai de tai avatar.')),
        );
      }
      return;
    }

    try {
      Globs.showHUD(status: 'Dang tai avatar...');

      final request = http.MultipartRequest('POST', Uri.parse(SVKey.svCustomerProfileAvatar));
      request.headers['Authorization'] = 'Bearer $authToken';
      final mime = picked.mimeType;
      final mediaType = _resolveMediaType(mime);
      
      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            pickedBytes,
            filename: picked.name,
            contentType: mediaType,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'avatar',
            picked.path,
            contentType: mediaType,
          ),
        );
      }

      final streamed = await request.send();
      final responseBody = await streamed.stream.bytesToString();
      final decoded = responseBody.isNotEmpty ? json.decode(responseBody) : {};

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        if (decoded is Map<String, dynamic>) {
          throw decoded[KKey.message] ?? responseBody;
        }
        throw responseBody;
      }

      if (decoded is Map<String, dynamic>) {
        final avatarPath = (decoded['avatarUrl'] ?? '').toString();
        final profile = decoded['profile'];

        final normalized = Map<String, dynamic>.from(ServiceCall.userPayload);
        if (profile is Map) {
          final profileMap = Map<String, dynamic>.from(profile);
          normalized['fullName'] = profileMap['fullName'] ?? normalized['fullName'];
          normalized[KKey.name] = profileMap['fullName'] ?? normalized[KKey.name];
          normalized['email'] = profileMap['email'] ?? normalized['email'];
          normalized['phone'] = profileMap['phone'] ?? normalized['phone'];
          normalized['mobile'] = profileMap['phone'] ?? normalized['mobile'];
          normalized['avatarUrl'] = profileMap['avatarUrl'] ?? avatarPath;
        } else {
          normalized['avatarUrl'] = avatarPath;
        }

        ServiceCall.userPayload = normalized;
        Globs.udSet(normalized, Globs.userPayload);

        if (mounted) {
          setState(() {
            selectedAvatarBytes = null;
            image = null;
            _loadUserInfo();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tai avatar thanh cong.')),
          );
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      Globs.hideHUD();
    }
  }

  Future<void> _showEditAccountDialog() async {
    final nameController = TextEditingController(text: userName);
    final emailController = TextEditingController(text: userEmail);
    final mobileController = TextEditingController(text: userMobile);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Doi thong tin tai khoan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Ho ten'),
              ),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'So dien thoai'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Huy'),
            ),
            TextButton(
              onPressed: () async {
                final fullName = nameController.text.trim();
                final email = emailController.text.trim();
                final phone = mobileController.text.trim();

                if (fullName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ho ten la bat buoc.')),
                  );
                  return;
                }

                try {
                  Globs.showHUD(status: 'Dang cap nhat thong tin...');

                  // Gọi API cập nhật thông tin trên server
                  await ServiceCall.fetchPut(
                    SVKey.svCustomerProfile,
                    isToken: true,
                    body: {
                      'hoTen': fullName,
                      'email': email.isEmpty ? null : email,
                      'soDienThoai': phone,
                    },
                  );

                  // Cập nhật local storage
                  final normalized = Map<String, dynamic>.from(ServiceCall.userPayload);
                  normalized['fullName'] = fullName;
                  normalized[KKey.name] = fullName;
                  normalized['phone'] = phone;
                  normalized['mobile'] = phone;
                  normalized['email'] = email;

                  ServiceCall.userPayload = normalized;
                  Globs.udSet(normalized, Globs.userPayload);

                  if (!mounted) {
                    return;
                  }

                  setState(() {
                    _loadUserInfo();
                  });
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cap nhat thong tin thanh cong.')),
                  );
                } catch (error) {
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                } finally {
                  Globs.hideHUD();
                }
              },
              child: const Text('Luu'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatarPreview() {
    if (selectedAvatarBytes != null) {
      return Image.memory(
        selectedAvatarBytes!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    }

    if (image != null && !kIsWeb) {
      return Image.file(
        File(image!.path),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    }

    if (userAvatarUrl.isNotEmpty) {
      final fullUrl = userAvatarUrl.startsWith('http') ? userAvatarUrl : '${SVKey.nodeUrl}$userAvatarUrl';
      return Image.network(
        fullUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (_, error, __) {
          return Icon(
            Icons.person,
            size: 65,
            color: TColor.secondaryText,
          );
        },
      );
    }

    return Icon(
      Icons.person,
      size: 65,
      color: TColor.secondaryText,
    );
  }

  MediaType _resolveMediaType(String? mime) {
    final normalized = (mime ?? '').toLowerCase().trim();
    if (normalized.startsWith('image/')) {
      final parts = normalized.split('/');
      if (parts.length == 2 && parts[1].isNotEmpty) {
        return MediaType('image', parts[1]);
      }
    }
    return MediaType('image', 'jpeg');
  }

  Widget _infoTile({required String label, required String value, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: TColor.textfield,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: TColor.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: TColor.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: TColor.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 46),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: TColor.placeholder,
                  borderRadius: BorderRadius.circular(50),
                ),
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: _buildAvatarPreview(),
                ),
              ),
              TextButton.icon(
                onPressed: _pickAndUploadAvatar,
                icon: Icon(
                  Icons.edit,
                  color: TColor.primary,
                  size: 12,
                ),
                label: Text(
                  'Edit Avatar',
                  style: TextStyle(color: TColor.primary, fontSize: 12),
                ),
              ),
              Text(
                'Xin chao, $userName',
                style: TextStyle(
                  color: TColor.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  ServiceCall.logout();
                },
                child: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: TColor.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _infoTile(label: 'Name', value: userName.isEmpty ? 'Nguoi dung' : userName, icon: Icons.person_outline),
              _infoTile(label: 'Email', value: userEmail.isEmpty ? 'Chua cap nhat email' : userEmail, icon: Icons.mail_outline),
              _infoTile(label: 'Mobile Phone', value: userMobile.isEmpty ? 'Chua cap nhat so dien thoai' : userMobile, icon: Icons.phone_android_outlined),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showEditAccountDialog,
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('Doi thong tin tai khoan'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}