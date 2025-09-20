import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  String searchQuery = '';

  void showBanDialog(String uid, String name) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Ban $name?'),
            content: const Text('Are you sure you want to ban this student?'),
            actions: [
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({'banned': true});
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('Ban', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void showUnbanDialog(String uid, String name) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Unban $name?'),
            content: const Text('Are you sure you want to unban this student?'),
            actions: [
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({'banned': false});
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text(
                  'Unban',
                  style: TextStyle(color: Colors.green),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void showDeleteDialog(String uid, String name) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete $name?'),
            content: const Text('This will permanently remove the student.'),
            actions: [
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .delete();
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void showProfileDialog(Map<String, dynamic> data, String uid) async {
    // Fetch quizzes taken by this student (assuming you store attempts in a collection)
    final quizAttemptsSnap =
        await FirebaseFirestore.instance
            .collection('quizAttempts')
            .where('studentId', isEqualTo: uid)
            .get();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(data['name'] ?? 'Student Profile'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${data['email'] ?? ''}'),
                  Text('Grade: ${data['gradeLevel'] ?? ''}'),
                  Text(
                    'Status: ${data['banned'] == true ? "Banned" : "Active"}',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quizzes Taken:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...quizAttemptsSnap.docs.map((doc) {
                    final attempt = doc.data();
                    return Text(
                      '- ${attempt['quizTitle'] ?? 'Quiz'}: Score ${attempt['score'] ?? ''}',
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Students',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search students',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.blueGrey.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final students =
                      snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name =
                            (data['name'] ?? '').toString().toLowerCase();
                        return searchQuery.isEmpty ||
                            name.contains(searchQuery);
                      }).toList();

                  if (students.isEmpty) {
                    return const Center(child: Text('No students found.'));
                  }

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, idx) {
                      final doc = students[idx];
                      final data = doc.data() as Map<String, dynamic>;
                      final banned = data['banned'] == true;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage(
                            'assets/images/student${(idx % 6) + 1}.png',
                          ),
                        ),
                        title: Text(
                          data['name'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(data['gradeLevel'] ?? 'No Grade'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              showDeleteDialog(doc.id, data['name'] ?? '');
                            } else if (value == 'ban') {
                              showBanDialog(doc.id, data['name'] ?? '');
                            } else if (value == 'unban') {
                              showUnbanDialog(doc.id, data['name'] ?? '');
                            } else if (value == 'profile') {
                              showProfileDialog(data, doc.id);
                            }
                          },
                          itemBuilder:
                              (context) => [
                                if (!banned)
                                  const PopupMenuItem(
                                    value: 'ban',
                                    child: Text('Ban Student'),
                                  ),
                                if (banned)
                                  const PopupMenuItem(
                                    value: 'unban',
                                    child: Text('Unban Student'),
                                  ),
                                const PopupMenuItem(
                                  value: 'profile',
                                  child: Text('View Profile'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete Student'),
                                ),
                              ],
                        ),
                        tileColor: banned ? Colors.red.withOpacity(0.08) : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
