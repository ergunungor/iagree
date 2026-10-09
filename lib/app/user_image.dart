import 'dart:io';

import 'package:flutter/widgets.dart';

import '../core/domain/user_profile.dart';

/// Kullanıcının profil fotoğrafı; yoksa null (avatar baş harflere düşer).
ImageProvider? userImage(UserProfile? user) {
  final path = user?.photoPath;
  return path == null ? null : FileImage(File(path));
}
