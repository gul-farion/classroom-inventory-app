import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomDetailsScreen extends StatefulWidget {
  final String roomId;

  const RoomDetailsScreen({required this.roomId, Key? key}) : super(key: key);

  @override
  _RoomDetailsScreenState createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logHistoryEvent({
    required String event,
    required String equipment,
    required String room,
    String details = '',
  }) async {
    await _firestore.collection('history').add({
      "event": event,
      "equipment": equipment,
      "room": room,
      "details": details,
      "date": DateTime.now().toIso8601String(),
    });
  }

  Future<void> _updateEquipment(String equipmentName, int newQuantity) async {
    await _firestore.collection('rooms').doc(widget.roomId).update({
      equipmentName: newQuantity,
    });

    await logHistoryEvent(
      event: "Изменено",
      equipment: equipmentName,
      room: widget.roomId,
      details: "Количество изменено на $newQuantity",
    );
  }

  Future<void> _deleteEquipment(String equipmentName) async {
    await _firestore.collection('rooms').doc(widget.roomId).update({
      equipmentName: FieldValue.delete(),
    });

    await logHistoryEvent(
      event: "Удалено",
      equipment: equipmentName,
      room: widget.roomId,
      details: "Оборудование удалено",
    );
  }

  void _editEquipmentQuantity(String equipmentName, int currentQuantity) {
    TextEditingController _quantityController =
        TextEditingController(text: currentQuantity.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Изменить количество: $equipmentName"),
          content: TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Новое количество"),
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
                final newQuantity =
                    int.tryParse(_quantityController.text.trim());
                if (newQuantity != null) {
                  _updateEquipment(equipmentName, newQuantity).then((_) {
                    Navigator.pop(context);
                  });
                }
              },
              child: const Text("Сохранить"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateOrAddEquipment(String equipmentName, int quantity) async {
    final roomDoc = _firestore.collection('rooms').doc(widget.roomId);

    final docSnapshot = await roomDoc.get();
    final data = docSnapshot.data() as Map<String, dynamic>? ?? {};

    if (data.containsKey(equipmentName)) {
      await roomDoc.update({
        equipmentName: quantity,
      });

      await logHistoryEvent(
        event: "Изменено",
        equipment: equipmentName,
        room: widget.roomId,
        details: "Количество изменено на $quantity",
      );
    } else {
      await roomDoc.update({
        equipmentName: quantity,
      });

      await logHistoryEvent(
        event: "Добавлено",
        equipment: equipmentName,
        room: widget.roomId,
        details: "Добавлено $quantity штук",
      );
    }
  }

  void _addEquipment() {
    TextEditingController _nameController = TextEditingController();
    TextEditingController _quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Добавить оборудование"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration:
                    const InputDecoration(labelText: "Название оборудования"),
              ),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Количество"),
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
                final name = _nameController.text.trim();
                final quantity = int.tryParse(_quantityController.text.trim());

                if (name.isNotEmpty && quantity != null) {
                  _updateOrAddEquipment(name, quantity).then((_) {
                    Navigator.pop(context);
                  });
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
        title: Text("Оборудование: ${widget.roomId}"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('rooms').doc(widget.roomId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Нет данных для этого кабинета."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final equipment =
              data.entries.where((entry) => entry.value is int).toList();

          if (equipment.isEmpty) {
            return const Center(
                child: Text("В этом кабинете нет оборудования."));
          }

          return ListView.builder(
            itemCount: equipment.length,
            itemBuilder: (context, index) {
              final item = equipment[index];
              final name = item.key;
              final quantity = item.value as int;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text("Количество: $quantity"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEquipment(name),
                  ),
                  onTap: () => _editEquipmentQuantity(name, quantity),
                ),
              );
            },
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
