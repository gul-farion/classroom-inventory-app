import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получение завершенных задач
  Stream<List<Map<String, dynamic>>> getCompletedTasks() {
    return _firestore
        .collection('tasks')
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "title": data['title'] ?? '',
          "cabinet": data['cabinet'] ?? '',
          "body": data['body'] ?? '',
          "date": (doc.metadata.hasPendingWrites) ? "Сохранение..." : DateTime.now().toIso8601String(),
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
        stream: getCompletedTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Ошибка загрузки данных"));
          }

          final history = snapshot.data ?? [];

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text("Выполнено: ${item["title"]}"),
                  subtitle: Text("Кабинет: ${item["cabinet"]}"),
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
