import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/login_and_register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/pass_data.dart';
import 'notifications_screen.dart';

class HomePage extends StatefulWidget {
  static const String id = "HomePage";

  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final _fireStore = FirebaseFirestore.instance;
  List<RemoteNotification?> notifications = [];

  @override
  Widget build(BuildContext context) {
    String? id = Provider.of<PassAllData>(context, listen: false).getUserId();

    User user = _auth.currentUser!;
    print("user.email = ${user.email}");
    if(user.email == null){
      Navigator.pushNamedAndRemoveUntil(context, LoginAndRegisterPage.id, (route) => false);
    }
    return Scaffold(
      // backgroundColor: Colors.grey[400],
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.pushNamed(context, NotificationsScreen.id,
                          arguments: notifications)
                      .then(
                    (value) => setState(() {
                      notifications.clear();
                    }),
                  );
                },
              ),
              notifications.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        '${notifications.length}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _auth.signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, LoginAndRegisterPage.id, (route) => false);
            },
          ),
        ],
        title: const Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            StreamBuilder(
              stream: _fireStore
                  .collection('Users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapShot) {
                if (snapShot.hasData) {
                  List<dynamic> users = snapShot.data!.docs;
                  return Expanded(
                    child: ListView.builder(
                        // reverse: true,
                        shrinkWrap: true,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          return "$id" == "${users[index]["userId"]}"
                              ? const SizedBox()
                              : InkWell(
                                  onTap: () {
                                    Provider.of<PassAllData>(context,
                                            listen: false)
                                        .setOtherUserId(users[index]["userId"]);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                              otherUserId: users[index]["userId"],
                                              otherUserName: users[index]["name"],
                                            userImage: users[index]["imageUrl"],
                                          ),
                                      ),
                                    );
                                  },
                                  child: ListTile(
                                    leading: users[index]["imageUrl"] != null
                                        ? CircleAvatar(
                                            radius: 28,
                                            backgroundColor:
                                                Colors.grey.shade400,
                                            backgroundImage: NetworkImage(
                                                users[index]["imageUrl"]),
                                          )
                                        : const CircleAvatar(
                                            radius: 28,
                                            child: Center(
                                              child: Icon(
                                                Icons.person,
                                                color: Colors.black,
                                                size: 32,
                                              ),
                                            ),
                                          ),
                                    title: Text(
                                      users[index]["name"],
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    subtitle: const Text(
                                      "last message send",
                                    ),
                                  ),
                                );
                        }),
                  );
                }
                return const Center(
                    child: Text(
                  'No any users yet',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ));
              },
            )
          ],
        ),
      ),
    );
  }
}
