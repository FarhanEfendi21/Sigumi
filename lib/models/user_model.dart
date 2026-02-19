class UserModel {
  final String id;
  final String name;
  final String email;
  final int? age;
  final double? latitude;
  final double? longitude;
  final String language;
  final String? region;
  final bool audioGuidance;
  final double fontSize;
  final bool highContrast;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.latitude,
    this.longitude,
    this.language = 'id',
    this.region,
    this.audioGuidance = false,
    this.fontSize = 1.0,
    this.highContrast = false,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    double? latitude,
    double? longitude,
    String? language,
    String? region,
    bool? audioGuidance,
    double? fontSize,
    bool? highContrast,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      language: language ?? this.language,
      region: region ?? this.region,
      audioGuidance: audioGuidance ?? this.audioGuidance,
      fontSize: fontSize ?? this.fontSize,
      highContrast: highContrast ?? this.highContrast,
    );
  }

  bool get isChild => age != null && age! < 13;
  bool get isElderly => age != null && age! > 60;
}
