class EmergencyNumberDto {
  final int pkInstitution;
  final String name;
  final String? acronym;
  final String phoneNumber;
  final String? email;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? typeName;

  EmergencyNumberDto({
    required this.pkInstitution,
    required this.name,
    this.acronym,
    required this.phoneNumber,
    this.email,
    this.address,
    this.latitude,
    this.longitude,
    this.typeName,
  });

  factory EmergencyNumberDto.fromJson(Map<String, dynamic> json) {
    return EmergencyNumberDto(
      pkInstitution: json['PK_institution'] as int,
      name: json['name'] as String? ?? '',
      acronym: json['acronym'] as String?,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      email: json['email'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      typeName: json['tbinstitutiontypes'] != null
          ? (json['tbinstitutiontypes']['name'] as String?)
          : null,
    );
  }
}
