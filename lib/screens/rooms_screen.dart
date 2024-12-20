import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/rooms_data.dart';

class RoomsScreen extends StatefulWidget {
  @override
  _RoomsScreenState createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
  String? selectedFloor; 

  void _goBackToFloors() {
    setState(() {
      selectedFloor = null;
    });
  }

  void _selectFloor(String floor) {
    setState(() {
      selectedFloor = floor;
    });
  }

  Future<void> _addTaskToFirestore(String title, String description, String room) async {
    await _firestore.collection('tasks').add({
      "title": title,
      "body": description,
      "cabinet": room,
      "isCompleted": false,
    });
  }

  void _createTask(BuildContext context, String room) {
    TextEditingController _titleController = TextEditingController();
    TextEditingController _descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Создать задачу"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Кабинет: $room",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Заголовок задачи"),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Описание задачи"),
                maxLines: 3,
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
                final title = _titleController.text.trim();
                final description = _descriptionController.text.trim();
                if (title.isNotEmpty) {
                  _addTaskToFirestore(title, description, room).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Задача для $room создана")),
                    );
                    Navigator.pop(context);
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Ошибка: ${error.toString()}")),
                    );
                  });
                }
              },
              child: const Text("Создать"),
            ),
          ],
        );
      },
    );
  }

  void _addRoom(String floor) {
    TextEditingController _roomController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Добавить кабинет на $floor"),
          content: TextField(
            controller: _roomController,
            decoration: const InputDecoration(labelText: "Название кабинета"),
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
                if (_roomController.text.isNotEmpty) {
                  setState(() {
                    roomsByFloor[floor]?.add(_roomController.text);
                  });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedFloor == null ? "Выберите этаж" : selectedFloor!),
        leading: selectedFloor == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBackToFloors, 
              ),
      ),
      body: selectedFloor == null
          ? ListView.builder(
              itemCount: floors.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(floors[index]),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => _selectFloor(floors[index]), // Выбрать этаж
                );
              },
            )
          : ListView.builder(
              itemCount: roomsByFloor[selectedFloor]?.length ?? 0,
              itemBuilder: (context, index) {
                final room = roomsByFloor[selectedFloor]?[index];
                return ListTile(
                  title: Text(room ?? ""),
                  trailing: const Icon(Icons.add_task),
                  onTap: () {
                    if (room != null) {
                      _createTask(context, room); 
                    }
                  },
                );
              },
            ),
      floatingActionButton: selectedFloor == null
          ? null
          : FloatingActionButton(
              onPressed: () => _addRoom(selectedFloor!),
              child: const Icon(Icons.add),
            ),
    );
  }
}
