import 'package:cloud_firestore/cloud_firestore.dart';

// Davomat yozuvlari uchun model
class AttendanceLog {
  final String? id;
  final String employeeId;
  final String employeeName;
  final DateTime timestamp;
  final String status; // Masalan: "keldi", "ketdi"

  AttendanceLog({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.timestamp,
    required this.status,
  });

  factory AttendanceLog.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AttendanceLog(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }
}
