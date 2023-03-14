import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'login_and_register.dart';
import 'notifications_screen.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? userImage;
  static const id = 'ChatScreen';

  const ChatScreen(
      {super.key,
      required this.otherUserId,
      required this.otherUserName,
      required this.userImage});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _fireStore = FirebaseFirestore.instance;
  String? typingId;

  late User user;
  TextEditingController textSendController = TextEditingController();
  List<RemoteNotification?> notifications = [];
  String token = '';

  late String otherUserId;

  void getCurrentUser() {
    user = _auth.currentUser!;
    print(user.email);
    if (user.email == null) {
      Navigator.pushNamedAndRemoveUntil(
          context, LoginAndRegisterPage.id, (route) => false);
    }
  }

  // void getMessages() async {
  //   messages = await _fireStore.collection('messages').get();
  //   setState(() {});
  //   for (var item in messages.docs) {
  //     print(item['text']);
  //   }
  // }

  void getNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        setState(() {
          notifications.add(message.notification);
        });
        print(
            'Message also contained a notification: ${message.notification!.title}');
      }
    });
  }

  Future<AccessToken> getAccessToken() async {
    final serviceAccount = await rootBundle.loadString(
        'assets/chat-app-c6b60-firebase-adminsdk-w1x0d-87facad419.json');
    final data = await json.decode(serviceAccount);
    print(data);
    final accountCredentials = ServiceAccountCredentials.fromJson({
      "private_key_id": data['private_key_id'],
      "private_key": data['private_key'],
      "client_email": data['client_email'],
      "client_id": data['client_id'],
      "type": data['type'],
    });
    final scopes = ["https://www.googleapis.com/auth/firebase.messaging"];
    final AuthClient authclient = await clientViaServiceAccount(
      accountCredentials,
      scopes,
    )
      ..close(); // Remember to close the client when you are finished with it.

    print(authclient.credentials.accessToken);

    return authclient.credentials.accessToken;
  }

  void sendNotification(String title, String body) async {
    http.Response response = await http.post(
      Uri.parse(
          'https://fcm.googleapis.com/v1/projects/chat-app-c6b60/messages:send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "message": {
          "topic": "breaking_news",
          // "token": fcmToken,
          "notification": {"body": body, "title": title}
        }
      }),
    );
    print('response.body: ${response.body}');
  }

  @override
  void initState() {
    getCurrentUser();
    getNotifications();
    getAccessToken().then((value) => token = value.data);
    super.initState();
  }

  @override
  void dispose() {
    textSendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      print("user id: ${user.uid}, And receiver id: ${widget.otherUserId}");
    });
    return Scaffold(
      appBar: AppBar(
        leading: Row(
          children: [
            const SizedBox(
              width: 8,
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_backspace_rounded),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            widget.userImage != null
                ? CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade400,
                    backgroundImage: NetworkImage(widget.userImage!),
                  )
                : const CircleAvatar(
                    radius: 20,
                    child: Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
            const SizedBox(
              width: 8,
            ),
            Text(
              widget.otherUserName,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ],
        ),
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
        ],
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder(
              stream: _fireStore
                  .collection('Messages')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapShot) {
                if (snapShot.hasData) {
                  List<dynamic> messages = snapShot.data!.docs;

                  return Expanded(
                    child: ListView.builder(
                      reverse: true,
                      shrinkWrap: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        QueryDocumentSnapshot message = messages[index];
                        return MessageBubble(
                          userId: user.uid,
                          otherUserId: widget.otherUserId,
                          message: message,
                          index: index,
                          isMe: message['senderId'] == user.uid,
                        );
                      },
                    ),
                  );
                } else {
                  return const Center(child: Text('loading data ..'));
                }
              },
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: textSendController,
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      //Implement send functionality.
                      if (textSendController.text.isNotEmpty) {
                        _fireStore.collection('Messages').add(
                          {
                            'message': textSendController.text,
                            'senderId': user.uid,
                            'receiverId': widget.otherUserId,
                            'date': DateTime.now().toString(),
                          },
                        );
                        sendNotification('message from ${user.email}',
                            textSendController.text);
                        textSendController.clear();
                        if (typingId != null) {
                          _fireStore
                              .collection('typing_users')
                              .doc(typingId)
                              .delete();
                          typingId = null;
                        }
                      }
                    },
                    child: const Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble(
      {Key? key,
      required this.userId,
      required this.otherUserId,
      required this.message,
      required this.index,
      required this.isMe})
      : super(key: key);

  final String userId;
  final String otherUserId;
  final QueryDocumentSnapshot message;
  final int index;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    if ((message["senderId"] == otherUserId &&
            message["receiverId"] == userId) ||
        message["senderId"] == userId && message["receiverId"] == otherUserId) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Material(
              color: isMe ? Colors.blueAccent : Colors.lightBlueAccent,
              borderRadius: isMe
                  ? const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 15),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${message["message"]}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                        "${message["date"].toString().substring(0, 10)} /${message["date"].toString().substring(10, 16)}"),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}
