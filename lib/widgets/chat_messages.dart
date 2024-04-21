import 'package:chat_app/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (ctx, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // if (chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
        //   return const Center(
        //     child: Text('No messages yet!'),
        //   );
        // }

        if (chatSnapshot.hasError) {
          return const Center(
            child: Text('An error occurred!'),
          );
        }

        final chatDocs = chatSnapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 40, left: 13, right: 13),
          reverse: true,
          itemCount: chatDocs.length,
          itemBuilder: (ctx, index) {
            final chatMessages = chatDocs[index].data();
            final hasNextMessage =
                index + 1 < chatDocs.length ? chatDocs[index + 1].data() : null;

            final currentMessageUserId = chatMessages['userId'];
            final nextMessageUserId =
                hasNextMessage != null ? hasNextMessage['userId'] : null;

            final isSameUser = currentMessageUserId == nextMessageUserId;

            if (isSameUser) {
              return MessageBubble.next(
                message: chatMessages['text'],
                isMe: currentMessageUserId ==
                    FirebaseAuth.instance.currentUser!.uid,
                key: ValueKey(chatDocs[index].id),
              );
            }
            return MessageBubble.first(
                message: chatMessages['text'],
                isMe: currentMessageUserId ==
                    FirebaseAuth.instance.currentUser!.uid,
                key: ValueKey(chatDocs[index].id),
                username: chatMessages['username'],
                userImage: chatMessages['userImage']);
          },
        );
      },
    );
  }
}
