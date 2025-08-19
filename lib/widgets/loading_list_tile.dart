import 'package:flutter/material.dart';

// Ma'lumotlar yuklanayotganda ko'rinadigan chiroyli animatsiya
class LoadingListTile extends StatelessWidget {
  const LoadingListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.black12,
        ),
        title: Container(
          height: 16,
          width: 150,
          color: Colors.black12,
        ),
        subtitle: Container(
          height: 12,
          width: 100,
          color: Colors.black12,
        ),
      ),
    );
  }
}
