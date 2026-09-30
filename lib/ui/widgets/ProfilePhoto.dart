import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lingualloop/Utils/AppNotifier.dart';
import 'package:lingualloop/services/FileService.dart';
import 'package:provider/provider.dart';

import '../../models/User.dart';
import '../../providers/UserProvider.dart';
import '../../services/UserService.dart';

class ProfilePhotoWidget extends StatefulWidget {
  final double? width;
  final double? height;
  final double? borderRadius;
  final bool? editable;

  const ProfilePhotoWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.editable,
  });

  @override
  _ProfilePhotoWidgetState createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
  late UserService _userService;
  late LocalFileService _localFileService;
  late User? _user;

  @override
  void initState() {
    super.initState();

    _userService = Provider.of<UserService>(context, listen: false);
    _localFileService = Provider.of<LocalFileService>(context, listen: false);
    _user = Provider.of<UserProvider>(context, listen: false).user;
  }

  Future<void> _pickImageAndUpload() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final response =
        await _userService.updateProfilePhotoById(File(pickedFile.path));
    if (response.errorCode != null) {
      AppNotifier.showMessage("Fotoğraf yüklenemedi: ${response.errorCode}");

      return;
    }

    if (!mounted) return;
    await _localFileService.updateCachedProfilePhoto(
      response.data!.signedUrl,
      _user!.userId,
      context,
    );

    AppNotifier.showMessage(
        "Profil fotoğrafı başarıyla güncellendi. ${response.errorCode}",
        color: Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    final photoWidth = widget.width ?? 70;
    final photoHeight = widget.height ?? 70;
    final editButtonSize = (photoWidth * 0.30).clamp(30.0, 46.0).toDouble();
    final editIconSize = editButtonSize * 0.55;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none, // Taşmayı mümkün kılar
          children: [
            // Profil fotoğrafı
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final photoPath = userProvider.user?.profilePhotoUrl;

                return ClipRRect(
                  borderRadius:
                      BorderRadius.circular(widget.borderRadius ?? 20),
                  child: photoPath == null || photoPath.isEmpty
                      ? Image.asset(
                          'assets/icons/profilephoto.png',
                          width: photoWidth,
                          height: photoHeight,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(photoPath),
                          width: photoWidth,
                          height: photoHeight,
                          fit: BoxFit.cover,
                          key: ValueKey(DateTime.now()
                              .toString()), // Unique key forces reload
                        ),
                );
              },
            ),

            if (widget.editable == null || widget.editable != false)
              Positioned(
                bottom: -editButtonSize * 0.10,
                right: -editButtonSize * 0.12,
                child: GestureDetector(
                  onTap: _pickImageAndUpload,
                  child: Container(
                    width: editButtonSize,
                    height: editButtonSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFF041227),
                      borderRadius:
                          BorderRadius.circular(editButtonSize * 0.32),
                      border: Border.all(
                        color: const Color(0xFF0C2244),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.32),
                          offset: const Offset(0, 5),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color:
                              const Color(0xFFFFB000).withValues(alpha: 0.18),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      size: editIconSize,
                      color: const Color(0xFFF4F5F8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
