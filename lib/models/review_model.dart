import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.serviceId,
    required this.providerId,
    required this.customerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.bookingId,
  });

  /// Firestore document id
  final String id;

  /// Reviewed service id
  final String serviceId;

  /// Provider id
  final String providerId;

  /// Customer (reviewer) id
  final String customerId;

  /// Optional: link review to a specific booking
  final String? bookingId;

  /// 1..5
  final double rating;

  /// Review text
  final String comment;

  /// Created time
  final DateTime createdAt;

  factory ReviewModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ReviewModel(
      id: documentId,
      serviceId: (map['serviceId'] as String?) ?? '',
      providerId: (map['providerId'] as String?) ?? '',
      customerId: (map['customerId'] as String?) ?? '',
      bookingId: map['bookingId'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      comment: (map['comment'] as String?) ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'providerId': providerId,
      'customerId': customerId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
