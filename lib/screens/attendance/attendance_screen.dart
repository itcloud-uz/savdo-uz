import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/attendance_log_model.dart';
import 'package.savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/screens/scan/face_scan_screen.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Davomat'),
      ),
      body: StreamBuilder<List<AttendanceLog>>(
        stream: firestoreService.getAttendanceRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Xatolik yuz berdi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Bugun uchun davomat yozuvlari mavjud emas.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final logs = snapshot.data!;

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final isCheckIn = log.status == 'keldi';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCheckIn
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    child: Icon(
                      isCheckIn ? Icons.login : Icons.logout,
                      color: isCheckIn ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text(log.employeeName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      DateFormat('dd.MM.yyyy HH:mm:ss').format(log.timestamp)),
                  trailing: Text(
                    isCheckIn ? 'Keldi' : 'Ketdi',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isCheckIn ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Yuzni skanerlash ekraniga o'tish
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FaceScanScreen()),
          );
        },
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Skanerlash'),
        tooltip: 'Ishga kelish/ketishni belgilash',
      ),
    );
  }
}
