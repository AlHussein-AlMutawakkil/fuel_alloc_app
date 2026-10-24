class PersonalInfoModel {
  final String arabicName;
  final String englishName;
  final String arabicAddress;
  final String englishAddress;
  final String contactNumbers;
  final String? logoPath;
  final String? stampPath;
  final String? signaturePath;
  final int logoScalePercent;
  final int stampScalePercent;
  final int signatureScalePercent;
  final bool includeInBackup;

  const PersonalInfoModel({
    this.arabicName = '',
    this.englishName = '',
    this.arabicAddress = '',
    this.englishAddress = '',
    this.contactNumbers = '',
    this.logoPath,
    this.stampPath,
    this.signaturePath,
    this.logoScalePercent = 100,
    this.stampScalePercent = 100,
    this.signatureScalePercent = 100,
    this.includeInBackup = true,
  });

  PersonalInfoModel copyWith({
    String? arabicName,
    String? englishName,
    String? arabicAddress,
    String? englishAddress,
    String? contactNumbers,
    String? logoPath,
    bool clearLogoPath = false,
    String? stampPath,
    bool clearStampPath = false,
    String? signaturePath,
    bool clearSignaturePath = false,
    int? logoScalePercent,
    int? stampScalePercent,
    int? signatureScalePercent,
    bool? includeInBackup,
  }) {
    return PersonalInfoModel(
      arabicName: arabicName ?? this.arabicName,
      englishName: englishName ?? this.englishName,
      arabicAddress: arabicAddress ?? this.arabicAddress,
      englishAddress: englishAddress ?? this.englishAddress,
      contactNumbers: contactNumbers ?? this.contactNumbers,
      logoPath: clearLogoPath ? null : (logoPath ?? this.logoPath),
      stampPath: clearStampPath ? null : (stampPath ?? this.stampPath),
      signaturePath: clearSignaturePath ? null : (signaturePath ?? this.signaturePath),
      logoScalePercent: logoScalePercent ?? this.logoScalePercent,
      stampScalePercent: stampScalePercent ?? this.stampScalePercent,
      signatureScalePercent: signatureScalePercent ?? this.signatureScalePercent,
      includeInBackup: includeInBackup ?? this.includeInBackup,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'arabic_name': arabicName,
      'english_name': englishName,
      'arabic_address': arabicAddress,
      'english_address': englishAddress,
      'contact_numbers': contactNumbers,
      'logo_path': logoPath,
      'stamp_path': stampPath,
      'signature_path': signaturePath,
      'logo_scale_percent': logoScalePercent,
      'stamp_scale_percent': stampScalePercent,
      'signature_scale_percent': signatureScalePercent,
      'include_in_backup': includeInBackup ? 1 : 0,
    };
  }

  factory PersonalInfoModel.fromMap(Map<String, dynamic> map) {
    return PersonalInfoModel(
      arabicName: map['arabic_name'] as String? ?? '',
      englishName: map['english_name'] as String? ?? '',
      arabicAddress: map['arabic_address'] as String? ?? '',
      englishAddress: map['english_address'] as String? ?? '',
      contactNumbers: map['contact_numbers'] as String? ?? '',
      logoPath: map['logo_path'] as String?,
      stampPath: map['stamp_path'] as String?,
      signaturePath: map['signature_path'] as String?,
      logoScalePercent: (map['logo_scale_percent'] as num?)?.toInt() ?? 100,
      stampScalePercent: (map['stamp_scale_percent'] as num?)?.toInt() ?? 100,
      signatureScalePercent: (map['signature_scale_percent'] as num?)?.toInt() ?? 100,
      includeInBackup: map['include_in_backup'] == 1 || map['include_in_backup'] == true || map['include_in_backup'] == 'true',
    );
  }
}
