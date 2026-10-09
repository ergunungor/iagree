import 'package:flutter/foundation.dart';

/// Giriş yapmış kullanıcı.
@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.photoPath,
  });

  final String id;
  final String name;
  final String email;

  /// Yerel profil fotoğrafı yolu (sunucu gelince adres olur); yoksa baş harfler gösterilir.
  final String? photoPath;

  UserProfile copyWith({String? name, String? photoPath}) => UserProfile(
    id: id,
    name: name ?? this.name,
    email: email,
    photoPath: photoPath ?? this.photoPath,
  );

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.photoPath == photoPath;

  @override
  int get hashCode => Object.hash(id, name, email, photoPath);
}
