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

  // Получение всех задач
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

  // Добавление новой задачи
  Future<void> addTask(String title, String body, String cabinet) async {
    await _firestore.collection('tasks').add({
      "title": title,
      "body": body,
      "cabinet": cabinet,
      "isCompleted": false,
    });
  }

  // Обновление задачи (переключение статуса)
  Future<void> updateTaskStatus(String id, bool isCompleted) async {
    await _firestore.collection('tasks').doc(id).update({
      "isCompleted": isCompleted,
    });
  }

  // Удаление задачи
  Future<void> deleteTask(String id) async {
    await _firestore.collection('tasks').doc(id).delete();
  }

  // Открытие модального окна для добавления задачи
  void _addTask(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    TextEditingController bodyController = TextEditingController();
    TextEditingController cabinetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Добавить задачу"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Заголовок"),
              ),
              TextField(
                controller: bodyController,
                decoration: InputDecoration(labelText: "Описание (необязательно)"),
                
              ),
              TextField(
                controller: cabinetController,
                decoration: InputDecoration(labelText: "Кабинет"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Отмена"),
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
              child: Text("Добавить"),
            ),
          ],
        );
      },
    );
  }

  // Открытие модального окна для просмотра деталей задачи
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
              SizedBox(height: 8),
              if (task["body"] != null && task["body"]!.isNotEmpty)
                Text("Описание: ${task["body"]}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                updateTaskStatus(task["id"], true); // Завершить задачу
                Navigator.pop(context);
              },
              child: Text("Завершить"),
            ),
            TextButton(
              onPressed: () {
                deleteTask(task["id"]); // Удалить задачу
                Navigator.pop(context);
              },
              child: Text("Удалить", style: TextStyle(color: Colors.red)),
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
        title: Text("Главная"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
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
              leading: Icon(Icons.room),
              title: Text("Кабинеты"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RoomsScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text("История"),
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
            // Секция "Исходящие задачи"
            Text(
              "Исходящие задачи",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: getTasks(isCompleted: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Ошибка загрузки данных"));
                  }
                  final tasks = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(task["title"]),
                          subtitle: Text("Кабинет: ${task["cabinet"]}"),
                          trailing: Icon(
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
            SizedBox(height: 16),

            // Секция "История"
            Text(
              "История (выполненные задачи)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: getTasks(isCompleted: true),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Ошибка загрузки данных"));
                  }
                  final tasks = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(task["title"]),
                          subtitle: Text("Кабинет: ${task["cabinet"]}"),
                          trailing: Icon(
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
        child: Icon(Icons.add),
      ),
    );
  }
}
