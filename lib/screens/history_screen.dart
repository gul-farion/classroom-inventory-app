import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getHistory() {
    return _firestore.collection('history').orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final rawDate = data['date'];
        DateTime? dateTime;

        if (rawDate is Timestamp) {
          dateTime = rawDate.toDate();
        } else if (rawDate is String) {
          dateTime = DateTime.tryParse(rawDate);
        }

        final formattedTime = dateTime != null ? DateFormat.Hms().format(dateTime) : 'Неизвестно';

        return {
          "id": doc.id,
          "event": data['event'] ?? 'Неизвестное событие',
          "equipment": data['equipment'] ?? 'Неизвестное оборудование',
          "room": data['room'] ?? 'Неизвестный кабинет',
          "date": formattedTime, 
          "details": data['details'] ?? '',
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("История"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Ошибка загрузки данных"));
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return const Center(child: Text("История пока пуста."));
          }

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text("${item["event"]}: ${item["equipment"]}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Кабинет: ${item["room"]}"),
                      Text("Время: ${item["date"]}"), 
                      if (item["details"].isNotEmpty) Text("Детали: ${item["details"]}"),
                    ],
                  ),
                  leading: const Icon(Icons.history, color: Colors.blue),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
