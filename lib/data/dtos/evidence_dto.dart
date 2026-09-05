class EvidenceDto {
  final int pkEvidence;
  final String fileType;
  final String fileUrl;
  final String? description;
  final DateTime createdAt;

  EvidenceDto({
    required this.pkEvidence,
    required this.fileType,
    required this.fileUrl,
    this.description,
    required this.createdAt,
  });

  factory EvidenceDto.fromJson(Map<String, dynamic> json) {
    return EvidenceDto(
      pkEvidence: json['PK_evidence'] as int,
      fileType: json['fileType'] as String? ?? 'IMAGE',
      fileUrl: json['fileUrl'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
