import 'package:flutter/material.dart';

class EquipmentScreen extends StatefulWidget {
  final String roomName;

  const EquipmentScreen({super.key, required this.roomName});

  @override
  _EquipmentScreenState createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  List<Map<String, String>> equipment = [
    {"name": "Проектор", "status": "Работает"},
    {"name": "Компьютер", "status": "На ремонте"},
    {"name": "Маркерная доска", "status": "Используется"},
  ];

  void _addEquipment() {
    setState(() {
      equipment.add({"name": "Новое оборудование", "status": "Новый"});
    });
  }

  void _editEquipment(int index) {
    setState(() {
      equipment[index] = {
        "name": "${equipment[index]["name"]} (изменено)",
        "status": equipment[index]["status"]!,
      };
    });
  }

  void _deleteEquipment(int index) {
    setState(() {
      equipment.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Оборудование: ${widget.roomName}'),
      ),
      body: ListView.builder(
        itemCount: equipment.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(equipment[index]["name"]!),
            subtitle: Text("Статус: ${equipment[index]["status"]!}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editEquipment(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteEquipment(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEquipment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
