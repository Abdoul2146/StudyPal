import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TopicsPage extends StatelessWidget {
  final String grade;
  final String subject;
  const TopicsPage({super.key, required this.grade, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$subject Topics')),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('curriculum')
                .doc(grade)
                .collection('subjects')
                .doc(subject)
                .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final topics = List<String>.from(data['topics'] ?? []);
          return ListView.builder(
            itemCount: topics.length,
            itemBuilder: (context, idx) {
              return ListTile(
                title: Text(topics[idx]),
                // You can add navigation to a lesson page here
              );
            },
          );
        },
      ),
    );
  }
}
