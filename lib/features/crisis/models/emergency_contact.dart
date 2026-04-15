class EmergencyContact {
  final String name;
  final String nameAr;
  final String nameFr;
  final String phone;
  final String? description;
  final String? descriptionAr;
  final String? descriptionFr;
  final String region;

  const EmergencyContact({
    required this.name,
    required this.nameAr,
    required this.nameFr,
    required this.phone,
    this.description,
    this.descriptionAr,
    this.descriptionFr,
    required this.region,
  });

  String getLocalizedName(String language) {
    switch (language) {
      case 'ar':
        return nameAr;
      case 'fr':
        return nameFr;
      default:
        return name;
    }
  }

  String? getLocalizedDescription(String language) {
    switch (language) {
      case 'ar':
        return descriptionAr;
      case 'fr':
        return descriptionFr;
      default:
        return description;
    }
  }
}

class EmergencyContacts {
  static const List<EmergencyContact> all = [
    // Morocco
    EmergencyContact(
      name: 'SOS Psychiatrie Morocco',
      nameAr: 'SOS الطب النفسي المغرب',
      nameFr: 'SOS Psychiatrie Maroc',
      phone: '0522-293-030',
      description: 'Mental health emergency line',
      descriptionAr: 'خط طوارئ الصحة النفسية',
      descriptionFr: 'Ligne d\'urgence en santé mentale',
      region: 'morocco',
    ),
    EmergencyContact(
      name: 'SAMU Morocco',
      nameAr: 'الإسعاف المغرب',
      nameFr: 'SAMU Maroc',
      phone: '141',
      description: 'Emergency medical services',
      descriptionAr: 'خدمات الطوارئ الطبية',
      descriptionFr: 'Services médicaux d\'urgence',
      region: 'morocco',
    ),
    // Saudi Arabia
    EmergencyContact(
      name: 'Mental Health Hotline',
      nameAr: 'خط مساندة للصحة النفسية',
      nameFr: 'Ligne d\'aide en santé mentale',
      phone: '920033360',
      description: 'Saudi mental health support',
      descriptionAr: 'الدعم النفسي في السعودية',
      descriptionFr: 'Soutien en santé mentale en Arabie Saoudite',
      region: 'saudi',
    ),
    EmergencyContact(
      name: 'Emergency Services Saudi',
      nameAr: 'خدمات الطوارئ السعودية',
      nameFr: 'Services d\'urgence Arabie Saoudite',
      phone: '911',
      description: 'Saudi emergency services',
      descriptionAr: 'الطوارئ السعودية',
      descriptionFr: 'Services d\'urgence saoudiens',
      region: 'saudi',
    ),
    // UAE
    EmergencyContact(
      name: 'Hope Line UAE',
      nameAr: 'خط الأمل الإمارات',
      nameFr: 'Ligne d\'espoir EAU',
      phone: '800-4673',
      description: 'UAE mental health crisis line',
      descriptionAr: 'خط أزمات الصحة النفسية الإمارات',
      descriptionFr: 'Ligne de crise en santé mentale EAU',
      region: 'uae',
    ),
    EmergencyContact(
      name: 'Emergency Services UAE',
      nameAr: 'خدمات الطوارئ الإمارات',
      nameFr: 'Services d\'urgence EAU',
      phone: '999',
      description: 'UAE emergency services',
      descriptionAr: 'الطوارئ الإمارات',
      descriptionFr: 'Services d\'urgence émirats',
      region: 'uae',
    ),
    // International
    EmergencyContact(
      name: 'Crisis Text Line',
      nameAr: 'خط الأزمات النصي',
      nameFr: 'Ligne de crise par SMS',
      phone: '741741',
      description: 'Text HOME to 741741',
      descriptionAr: 'أرسل HOME إلى 741741',
      descriptionFr: 'Envoyez HOME au 741741',
      region: 'international',
    ),
    EmergencyContact(
      name: 'International Emergency',
      nameAr: 'الطوارئ الدولية',
      nameFr: 'Urgence internationale',
      phone: '112',
      description: 'International emergency number',
      descriptionAr: 'رقم الطوارئ الدولي',
      descriptionFr: 'Numéro d\'urgence international',
      region: 'international',
    ),
  ];

  static List<EmergencyContact> forRegion(String region) {
    return all.where((c) => c.region == region).toList();
  }

  static List<EmergencyContact> get priority {
    return [
      ...forRegion('saudi'),
      ...forRegion('morocco'),
      ...forRegion('uae'),
      ...forRegion('international'),
    ];
  }
}
