import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tic_tac_toc_game/models/user_model.dart';

class RankPage extends StatelessWidget {
  const RankPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rankings'),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('wins', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data?.docs
                  .map((doc) => UserModel.fromMap(
                      {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
                  .toList() ??
              [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20, // Resize the CircleAvatar
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    user.displayName ?? user.email ?? 'Anonymous',
                    style: const TextStyle(
                      fontSize: 18, // Change font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Total Games: ${user.totalGames}',
                    style: const TextStyle(
                      fontSize: 14, // Change font size
                      color: Colors.grey,
                    ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                          255, 48, 148, 52), // Change container color
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${user.wins} wins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
