// lib/models/booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  const BookingModel({
    required this.id,
    required this.customerId,
    required this.providerId,
    required this.serviceId,
    required this.status,
    required this.dateTime,
    required this.totalPrice,
    this.note,
    this.bookingNumber,
    this.autoNumber,
  });

  final String id;
  final String customerId;
  final String providerId;
  final String serviceId;
  final String status;
  final DateTime dateTime;
  final String? note;
  final double totalPrice;

  /// New sequential booking number
  final int? bookingNumber;

  /// Legacy field (for old data only)
  final int? autoNumber;

  factory BookingModel.fromMap(Map<String, dynamic> map, String documentId) {
    final bookingNumberRaw = map['bookingNumber'];
    final autoNumberRaw = map['autoNumber'];

    // Prefer bookingNumber, fallback to autoNumber for legacy records
    final int? effectiveBookingNumber = bookingNumberRaw != null
        ? (bookingNumberRaw as num).toInt()
        : autoNumberRaw != null
            ? (autoNumberRaw as num).toInt()
            : null;

    return BookingModel(
      id: documentId,
      customerId: (map['customerId'] as String?) ?? '',
      providerId: (map['providerId'] as String?) ?? '',
      serviceId: (map['serviceId'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'pending',
      dateTime: map['dateTime'] is Timestamp
          ? (map['dateTime'] as Timestamp).toDate()
          : DateTime.now(),
      note: map['note'] as String?,
      totalPrice: map['totalPrice'] == null
          ? 0.0
          : (map['totalPrice'] as num).toDouble(),
      bookingNumber: effectiveBookingNumber,
      autoNumber: autoNumberRaw != null ? (autoNumberRaw as num).toInt() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'providerId': providerId,
      'serviceId': serviceId,
      'status': status,
      'dateTime': Timestamp.fromDate(dateTime),
      'note': note,
      'totalPrice': totalPrice,

      // New sequential booking number
      'bookingNumber': bookingNumber,

      // Optional: legacy compatibility
      'autoNumber': autoNumber,
    };
  }
}
