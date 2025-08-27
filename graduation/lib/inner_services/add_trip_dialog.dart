import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTripDialog extends StatefulWidget {
  final String driverId;
  final String? tripId; // Optional tripId for editing
  final Map<String, dynamic>? existingTripData; // Optional existing data for editing

  const AddTripDialog({
    super.key,
    required this.driverId,
    this.tripId,
    this.existingTripData,
  });

  @override
  _AddTripDialogState createState() => _AddTripDialogState();
}

class _AddTripDialogState extends State<AddTripDialog> {
  final TextEditingController _startingPointController = TextEditingController();
  final TextEditingController _endingPointController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.existingTripData != null) {
      // If editing, populate the controllers with existing data
      _startingPointController.text = widget.existingTripData!['startingPoint'];
      _endingPointController.text = widget.existingTripData!['endingPoint'];
      _dateController.text = widget.existingTripData!['date'];
      _hoursController.text = widget.existingTripData!['hours'].toString();
    }
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tripId == null ? "Add Trip" : "Edit Trip"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _startingPointController,
            decoration: const InputDecoration(labelText: "Starting Point"),
          ),
          TextField(
            controller: _endingPointController,
            decoration: const InputDecoration(labelText: "Ending Point"),
          ),
          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: _selectDate,
            decoration: const InputDecoration(
              labelText: "Date",
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
          TextField(
            controller: _hoursController,
            decoration: const InputDecoration(labelText: "Duration (Hours)"),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final tripData = {
              'startingPoint': _startingPointController.text,
              'endingPoint': _endingPointController.text,
              'date': _dateController.text,
              'hours': int.tryParse(_hoursController.text) ?? 0,
              'status': 'Upcoming',
              'createdAt': FieldValue.serverTimestamp(),
            };

            try {
              if (widget.tripId == null) {
                // Add new trip
                await FirebaseFirestore.instance
                    .collection('drivers')
                    .doc(widget.driverId)
                    .collection('trips')
                    .add(tripData);
              } else {
                // Update existing trip
                await FirebaseFirestore.instance
                    .collection('drivers')
                    .doc(widget.driverId)
                    .collection('trips')
                    .doc(widget.tripId)
                    .update(tripData);
              }
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Trip saved successfully")),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error saving trip")),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
