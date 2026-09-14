class CitizenDto {
  final int pkCitizen;
  final String firstName;
  final String lastName;
  final String? ci;
  final String phoneNumber;
  final String? email;
  final String? profileImage;
  final bool status;
  final DateTime createdAt;

  CitizenDto({
    required this.pkCitizen,
    required this.firstName,
    required this.lastName,
    this.ci,
    required this.phoneNumber,
    this.email,
    this.profileImage,
    required this.status,
    required this.createdAt,
  });

  factory CitizenDto.fromJson(Map<String, dynamic> json) {
    return CitizenDto(
      pkCitizen: json['PK_citizen'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      ci: json['CI'] as String?,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      email: json['email'] as String?,
      profileImage: json['profileImage'] as String?,
      status: json['status'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}
