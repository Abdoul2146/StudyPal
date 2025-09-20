// ignore_for_file: file_names

// import 'package:agent36/admin/addCurriculum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:agent36/widgets/adminNavBar.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.notifications_none),
        //     onPressed: () {},
        //   ),
        // ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: ListView(
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                FutureBuilder<int>(
                  future: fetchStudentCount(),
                  builder:
                      (context, snapshot) => _SummaryCard(
                        title: 'Total Students',
                        value: '${snapshot.data ?? 0}',
                        subtitle: 'Active students',
                        image: 'assets/images/students.png',
                      ),
                ),
                FutureBuilder<int>(
                  future: fetchGradeCount(),
                  builder:
                      (context, snapshot) => _SummaryCard(
                        title: 'Grades',
                        value: '${snapshot.data ?? 0}',
                        subtitle: 'Grades available',
                        image: 'assets/images/grades.png',
                      ),
                ),
                FutureBuilder<int>(
                  future: fetchSubjectCount(),
                  builder:
                      (context, snapshot) => _SummaryCard(
                        title: 'Subjects',
                        value: '${snapshot.data ?? 0}',
                        subtitle: 'Subjects offered',
                        image: 'assets/images/subjects.png',
                      ),
                ),
                FutureBuilder<int>(
                  future: fetchTopicCount(),
                  builder:
                      (context, snapshot) => _SummaryCard(
                        title: 'Topics',
                        value: '${snapshot.data ?? 0}',
                        subtitle: 'Topics covered',
                        image: 'assets/images/topics.png',
                      ),
                ),
                FutureBuilder<int>(
                  future: fetchQuizCount(),
                  builder:
                      (context, snapshot) => _SummaryCard(
                        title: 'Quizzes',
                        value: '${snapshot.data ?? 0}',
                        subtitle: 'Quizzes available',
                        image: 'assets/images/quizzes.png',
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Students Signed Up',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Student Signups',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Text(
                  '+15%',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Text(
              'Last 30 Days +15%',
              style: TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 16),
            FutureBuilder<int>(
              future: fetchStudentCount(),
              builder: (context, snapshot) {
                final value = (snapshot.data ?? 0) / 100;
                return Container(
                  height: 80,
                  color: Colors.transparent,
                  child: Center(
                    child: LinearProgressIndicator(
                      value: value > 1 ? 1 : value, // cap at 1
                      minHeight: 20,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // const Text(
            //   'Recent Activity',
            //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            // ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('createdAt', descending: true)
                      .limit(5)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Error loading students');
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No recent signups.');
                }
                return Column(
                  children:
                      snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: AssetImage(
                              'assets/images/${data['avatar'] ?? 'default'}.png',
                            ),
                          ),
                          title: Text(
                            data['name'] ?? 'No Name',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('New student added'),
                        );
                      }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            // const Text(
            //   'Quick Actions',
            //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            // ),
            // const SizedBox(height: 8),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     // _ActionButton(label: 'Add Student', onPressed: () {}),
            //     _ActionButton(
            //       label: 'Add Subject',
            //       onPressed: () {
            //         Navigator.pushReplacement(
            //           context,
            //           MaterialPageRoute(
            //             builder: (context) => const CurriculumPage(),
            //           ),
            //         );
            //       },
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 16),
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton(
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.lightBlue,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(32),
            //       ),
            //       padding: const EdgeInsets.symmetric(vertical: 16),
            //     ),
            //     onPressed: () {},
            //     child: const Text(
            //       'Add Quiz',
            //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
      // bottomNavigationBar: AdminNav(initialIndex: 0),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, value, subtitle, image;
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.image,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        vertical: 8,
      ), // Add spacing between cards
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Image.asset(image, width: 48, height: 48),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.blueGrey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// class _ActionButton extends StatelessWidget {
//   final String label;
//   final VoidCallback onPressed;
//   const _ActionButton({required this.label, required this.onPressed});
//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.lightBlue,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//       ),
//       onPressed: onPressed,
//       child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//     );
//   }
// }

Future<int> fetchStudentCount() async {
  final snap = await FirebaseFirestore.instance.collection('users').get();
  return snap.size;
}

Future<int> fetchGradeCount() async {
  final snap = await FirebaseFirestore.instance.collection('curriculum').get();
  return snap.size;
}

Future<int> fetchSubjectCount() async {
  final gradesSnap =
      await FirebaseFirestore.instance.collection('curriculum').get();
  int subjectCount = 0;
  for (var gradeDoc in gradesSnap.docs) {
    final subjectsSnap = await gradeDoc.reference.collection('subjects').get();
    subjectCount += subjectsSnap.size;
  }
  return subjectCount;
}

Future<int> fetchTopicCount() async {
  final gradesSnap =
      await FirebaseFirestore.instance.collection('curriculum').get();
  int topicCount = 0;
  for (var gradeDoc in gradesSnap.docs) {
    final subjectsSnap = await gradeDoc.reference.collection('subjects').get();
    for (var subjectDoc in subjectsSnap.docs) {
      final topics = subjectDoc.data()['topics'] as List<dynamic>? ?? [];
      topicCount += topics.length;
    }
  }
  return topicCount;
}

Future<int> fetchQuizCount() async {
  final snap =
      await FirebaseFirestore.instance.collectionGroup('quizList').get();
  return snap.size;
}
