class UserProfile {
  final String name;
  final String userEmail;
  final String userPhone;
  final String residenceType;
  final int? societyId;
  final String societyName;
  final String? tower;
  final String? flatNo;
  final String? address;
  final bool profileComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.name,
    required this.userEmail,
    required this.userPhone,
    required this.residenceType,
    this.societyId,
    required this.societyName,
    this.tower,
    this.flatNo,
    this.address,
    required this.profileComplete,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      userEmail: json['user_email'] ?? '',
      userPhone: json['user_phone'] ?? '',
      residenceType: json['residence_type'] ?? 'society',
      societyId: json['society_id'],
      societyName: json['society_name'] ?? '',
      tower: json['tower'],
      flatNo: json['flat_no'],
      address: json['address'],
      profileComplete: json['profile_complete'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'user_email': userEmail,
      'user_phone': userPhone,
      'residence_type': residenceType,
      if (societyId != null) 'society_id': societyId,
      'society_name': societyName,
      if (tower != null) 'tower': tower,
      if (flatNo != null) 'flat_no': flatNo,
      if (address != null) 'address': address,
      'profile_complete': profileComplete,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserProfile{name: $name, userEmail: $userEmail, userPhone: $userPhone, residenceType: $residenceType, societyId: $societyId, societyName: $societyName, tower: $tower, flatNo: $flatNo, address: $address, profileComplete: $profileComplete, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  UserProfile copyWith({
    String? name,
    String? userEmail,
    String? userPhone,
    String? residenceType,
    int? societyId,
    String? societyName,
    String? tower,
    String? flatNo,
    String? address,
    bool? profileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      residenceType: residenceType ?? this.residenceType,
      societyId: societyId ?? this.societyId,
      societyName: societyName ?? this.societyName,
      tower: tower ?? this.tower,
      flatNo: flatNo ?? this.flatNo,
      address: address ?? this.address,
      profileComplete: profileComplete ?? this.profileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
