class EmergencyTypeDto {
  final String name;
  final String code;

  EmergencyTypeDto({required this.name, required this.code});

  factory EmergencyTypeDto.fromJson(Map<String, dynamic> json) {
    return EmergencyTypeDto(
      name: json['name'] as String? ?? 'Otro',
      code: json['code'] as String? ?? 'OTRO',
    );
  }
}

class EmergencyLocationDto {
  final double latitude;
  final double longitude;
  final String? address;
  final double? accuracy;

  EmergencyLocationDto({
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
  });

  factory EmergencyLocationDto.fromJson(Map<String, dynamic> json) {
    return EmergencyLocationDto(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String?,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
    );
  }
}

class EmergencyUnitDto {
  final String? unitCode;
  final String? unitName;

  EmergencyUnitDto({this.unitCode, this.unitName});

  factory EmergencyUnitDto.fromJson(Map<String, dynamic> json) {
    return EmergencyUnitDto(
      unitCode: json['unitCode'] as String?,
      unitName: json['unitName'] as String?,
    );
  }
}

class EmergencyInstitutionRefDto {
  final String name;
  final String? acronym;

  EmergencyInstitutionRefDto({required this.name, this.acronym});

  factory EmergencyInstitutionRefDto.fromJson(Map<String, dynamic> json) {
    return EmergencyInstitutionRefDto(
      name: json['name'] as String? ?? '',
      acronym: json['acronym'] as String?,
    );
  }
}

class EmergencyAssignmentDto {
  final String status;
  final EmergencyInstitutionRefDto? institution;
  final EmergencyUnitDto? unit;

  EmergencyAssignmentDto({required this.status, this.institution, this.unit});

  factory EmergencyAssignmentDto.fromJson(Map<String, dynamic> json) {
    return EmergencyAssignmentDto(
      status: json['status'] as String? ?? '',
      institution: json['tbinstitutions'] != null
          ? EmergencyInstitutionRefDto.fromJson(json['tbinstitutions'] as Map<String, dynamic>)
          : null,
      unit: json['tbunits'] != null
          ? EmergencyUnitDto.fromJson(json['tbunits'] as Map<String, dynamic>)
          : null,
    );
  }
}

class EmergencyDto {
  final int pkEmergency;
  final String emergencyCode;
  final String priority;
  final String status;
  final String description;
  final DateTime reportedAt;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final DateTime updatedAt;
  final EmergencyTypeDto type;
  final List<EmergencyAssignmentDto> assignments;
  final List<EmergencyLocationDto> locations;

  EmergencyDto({
    required this.pkEmergency,
    required this.emergencyCode,
    required this.priority,
    required this.status,
    required this.description,
    required this.reportedAt,
    required this.createdAt,
    this.resolvedAt,
    required this.updatedAt,
    required this.type,
    required this.assignments,
    required this.locations,
  });

  factory EmergencyDto.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    return EmergencyDto(
      pkEmergency: json['PK_emergency'] as int,
      emergencyCode: json['emergencyCode'] as String? ?? '',
      priority: json['priority'] as String? ?? 'MEDIA',
      status: json['status'] as String? ?? 'REPORTADA',
      description: json['description'] as String? ?? '',
      reportedAt: DateTime.tryParse(json['reportedAt'] as String? ?? '') ?? createdAt,
      createdAt: createdAt,
      resolvedAt: json['resolvedAt'] != null ? DateTime.tryParse(json['resolvedAt'] as String) : null,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? createdAt,
      type: json['tbemergencytypes'] != null
          ? EmergencyTypeDto.fromJson(json['tbemergencytypes'] as Map<String, dynamic>)
          : EmergencyTypeDto(name: 'Otro', code: 'OTRO'),
      assignments: (json['tbemergencyassignments'] as List<dynamic>? ?? [])
          .map((e) => EmergencyAssignmentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      locations: (json['tbemergencylocations'] as List<dynamic>? ?? [])
          .map((e) => EmergencyLocationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
