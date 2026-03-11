class Outlet {
  final String id;
  final String name;
  final String highway;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? phone;
  final String? sapCode;
  final String? district;
  final bool isActive;
  final String? contactPerson;
  final String? contactEmail;
  final double? distanceKm;
  final String? roadSide;

  const Outlet({
    required this.id,
    required this.name,
    required this.highway,
    this.latitude,
    this.longitude,
    this.address,
    this.phone,
    this.sapCode,
    this.district,
    this.isActive = true,
    this.contactPerson,
    this.contactEmail,
    this.distanceKm,
    this.roadSide,
  });

  factory Outlet.fromJson(Map<String, dynamic> json) {
    return Outlet(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      highway: json['highway'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      sapCode: json['sap_code'] as String?,
      district: json['district'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      contactPerson: json['contact_person'] as String?,
      contactEmail: json['contact_email'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      roadSide: json['road_side'] as String?,
    );
  }

  String get shortAddress {
    if (address != null && address!.isNotEmpty) {
      final parts = address!.split(',');
      return parts.length > 1
          ? '${parts[0].trim()}, ${parts[1].trim()}'
          : address!;
    }
    return highway;
  }

  String get locationTag {
    final parts = <String>[highway];
    if (district != null && district!.isNotEmpty) parts.add(district!);
    return parts.join(', ');
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'highway': highway,
    'lat': latitude,
    'lng': longitude,
    'address': address,
    'district': district,
  };
}
