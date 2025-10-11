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
  late double? width;
  late double? height;
  late double? borderRadius;
  late bool? editable;

  ProfilePhotoWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.editable
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

  Future<void> _pickImageAndUpload(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final response = await _userService.updateProfilePhotoById(File(pickedFile.path));
    if (response.errorCode != null) {
      AppNotifier.showMessage("Fotoğraf yüklenemedi: ${response.errorCode}");

      return;
    }

    await _localFileService.updateCachedProfilePhoto(response.data!.signedUrl, _user!.userId, context,);

    AppNotifier.showMessage("Profil fotoğrafı başarıyla güncellendi. ${response.errorCode}", color: Colors.green);
  }

  @override
  Widget build(BuildContext context) {

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none, // Taşmayı mümkün kılar
          children: [
            // Profil fotoğrafı
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius ?? 20),
                  child: Image.file(
                    File(userProvider.user!.profilePhotoUrl!),
                    width: widget.width ?? 70,
                    height: widget.height ?? 70,
                    fit: BoxFit.cover,
                    key: ValueKey(DateTime.now().toString()), // Unique key forces reload
                  ),
                );
              },
            ),

            if (widget.editable == null || widget.editable != false)
              Positioned(
                bottom: -6,
                right: -10,
                child: GestureDetector(
                  onTap: () => _pickImageAndUpload(context),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Color(0xFF5F5CF0),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: Colors.white,
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
