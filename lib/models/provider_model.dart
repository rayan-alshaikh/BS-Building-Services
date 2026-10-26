import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderModel {
  const ProviderModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.locationText,
    required this.profession,
    required this.status,
    required this.role,
    required this.providerType,
    this.bio,
    this.crNumber,
    this.photoUrl,
    this.locationGeo,
    this.avgRating = 0.0,
    this.ratingCount = 0,
    this.ratingSum = 0.0,
  });

  final String id;
  final String name;
  final String email;
  final String phone;

  final String city;
  final String locationText;
  final GeoPoint? locationGeo;

  final String profession;
  final String? bio;
  final String? crNumber;

  final String status;
  final String role;
  final String? photoUrl;

  /// Rating fields (Cloud Function writes these)
  final double avgRating;
  final int ratingCount;

  /// Optional: support old/new data
  final double ratingSum;

  final String providerType;

  factory ProviderModel.fromMap(Map<String, dynamic> map, String documentId) {
    double safeNum(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int safeInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    // Support both ratingSum and ratingTotal in DB
    final ratingSumFromDb = safeNum(map['ratingSum']);
    final ratingTotalFromDb = safeNum(map['ratingTotal']);
    final sum = ratingSumFromDb > 0 ? ratingSumFromDb : ratingTotalFromDb;

    final count = safeInt(map['ratingCount']);

    // avgRating: prefer stored avgRating; fallback to sum/count
    final storedAvg = safeNum(map['avgRating']);
    final avg = storedAvg > 0 ? storedAvg : (count > 0 ? (sum / count) : 0.0);

    final professionStr = map['profession']?.toString();

    return ProviderModel(
      id: documentId,
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      locationText: map['location']?.toString() ?? '',
      locationGeo:
          map['locationGeo'] is GeoPoint ? map['locationGeo'] as GeoPoint : null,
      profession: professionStr ?? '',
      bio: map['bio']?.toString(),
      crNumber: map['crNumber']?.toString(),
      status: map['status']?.toString() ?? 'pending_verification',
      role: map['role']?.toString() ?? 'provider',
      photoUrl: map['photoUrl']?.toString(),
      avgRating: avg,
      ratingCount: count,
      ratingSum: sum,
      providerType: map['providerType']?.toString() ??
          _inferProviderType(professionStr),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'location': locationText,
      'locationGeo': locationGeo,
      'profession': profession,
      'bio': bio,
      'crNumber': crNumber,
      'status': status,
      'role': role,
      'photoUrl': photoUrl,

      // Keep for compatibility
      'ratingSum': ratingSum,
      'ratingCount': ratingCount,
      'avgRating': avgRating,

      'providerType': providerType,
    };
  }

  static String _inferProviderType(String? profession) {
    if (profession == null) return 'professional';
    final p = profession.toLowerCase();

    if (p.contains('company')) return 'company';

    // Keep "establishment" to match your screens
    if (p.contains('institution') || p.contains('establishment')) {
      return 'establishment';
    }

    return 'professional';
  }
}
