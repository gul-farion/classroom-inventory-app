import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rooms_screen.dart';
import 'history_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getTasks({required bool isCompleted}) {
    return _firestore
        .collection('tasks')
        .where('isCompleted', isEqualTo: isCompleted)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "title": data['title'] ?? '',
          "body": data['body'] ?? '',
          "cabinet": data['cabinet'] ?? '',
          "isCompleted": data['isCompleted'] ?? false,
        };
      }).toList();
    });
  }

  Future<void> addTask(String title, String body, String cabinet) async {
    await _firestore.collection('tasks').add({
      "title": title,
      "body": body,
      "cabinet": cabinet,
      "isCompleted": false,
    });
  }

  Future<void> updateTaskStatus(String id, bool isCompleted) async {
    await _firestore.collection('tasks').doc(id).update({
      "isCompleted": isCompleted,
    });
  }

  Future<void> deleteTask(String id) async {
    await _firestore.collection('tasks').doc(id).delete();
  }

  void _addTask(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    TextEditingController bodyController = TextEditingController();
    TextEditingController cabinetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Добавить задачу"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Заголовок"),
              ),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: "Описание (необязательно)"),
                
              ),
              TextField(
                controller: cabinetController,
                decoration: const InputDecoration(labelText: "Кабинет"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Отмена"),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && cabinetController.text.isNotEmpty) {
                  addTask(
                    titleController.text,
                    bodyController.text,
                    cabinetController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text("Добавить"),
            ),
          ],
        );
      },
    );
  }

  void _openTaskDetails(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(task["title"]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Кабинет: ${task["cabinet"]}"),
              const SizedBox(height: 8),
              if (task["body"] != null && task["body"]!.isNotEmpty)
                Text("Описание: ${task["body"]}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                updateTaskStatus(task["id"], true); 
                Navigator.pop(context);
              },
              child: const Text("Завершить"),
            ),
            TextButton(
              onPressed: () {
                deleteTask(task["id"]);
                Navigator.pop(context);
              },
              child: const Text("Удалить", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Главная"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Admin",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.room),
              title: const Text("Кабинеты"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RoomsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("История"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Исходящие задачи",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: getTasks(isCompleted: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Ошибка загрузки данных"));
                  }
                  final tasks = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(task["title"]),
                          subtitle: Text("Кабинет: ${task["cabinet"]}"),
                          trailing: const Icon(
                            Icons.warning,
                            color: Colors.orange,
                          ),
                          onTap: () => _openTaskDetails(context, task),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              "История (выполненные задачи)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: getTasks(isCompleted: true),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Ошибка загрузки данных"));
                  }
                  final tasks = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(task["title"]),
                          subtitle: Text("Кабинет: ${task["cabinet"]}"),
                          trailing: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
