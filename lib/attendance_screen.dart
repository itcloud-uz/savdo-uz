import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:savdo_uz/services/firestore_service.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Xodimlar Davomati"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getAttendanceRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Xatolik: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("Hozircha davomat yozuvlari mavjud emas."));
          }

          final records = snapshot.data!.docs;

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index].data() as Map<String, dynamic>;
              final timestamp = (record['timestamp'] as Timestamp).toDate();
              final status = record['status'] as String?;
              final isClockIn = status == 'clock_in';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isClockIn ? Colors.green : Colors.orange,
                    child: Icon(isClockIn ? Icons.login : Icons.logout,
                        color: Colors.white),
                  ),
                  title: Text(record['employeeName'] ?? 'Noma\'lum xodim'),
                  subtitle: Text(isClockIn ? 'Ishga keldi' : 'Ishdan ketdi'),
                  trailing: Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(timestamp),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
