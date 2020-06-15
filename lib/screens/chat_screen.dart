import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = Firestore.instance;
final _auth = FirebaseAuth.instance;
FirebaseUser loggedInUser;
String messageText;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  Future<void> getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageBuilder(firestore: _firestore),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                        'time': FieldValue.serverTimestamp()
                      });
                    },
                    child: Text(
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

class MessageBuilder extends StatelessWidget {
  const MessageBuilder({
    @required Firestore firestore,
  }) : _firestore = firestore;

  final Firestore _firestore;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('messages')
          .orderBy('time', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(
            backgroundColor: loginColor,
          ));
        }
        final messages = snapshot.data.documents.reversed;
        List<MessageBubble> messageList = [];
        for (var message in messages) {
          final messageText = message.data['text'];
          final messageSender = message.data['sender'];

          messageList.add(MessageBubble(
            text: messageText,
            sender: messageSender,
            ifUser: messageSender == loggedInUser.email,
          ));
        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            children: messageList,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({
    @required this.sender,
    @required this.text,
    @required this.ifUser,
  });

  final String sender;
  final String text;
  final bool ifUser;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment:
            ifUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            this.sender,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Material(
            color: ifUser ? loginColor : Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
              topLeft: ifUser ? Radius.circular(20) : Radius.circular(0),
              topRight: ifUser ? Radius.circular(0) : Radius.circular(20),
            ),
            elevation: 3.0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                this.text,
                style: TextStyle(
                  color: ifUser ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
