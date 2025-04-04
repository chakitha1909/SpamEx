import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';

class ChatScreen extends StatefulWidget {
  final String sender;
  final List<SmsMessage> messages;
  final String category; // Inbox, Spam, OTP

  const ChatScreen({
    super.key,
    required this.sender,
    required this.messages,
    required this.category,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final Telephony telephony = Telephony.instance;
  List<String> sentMessages = []; // Store sent messages manually

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sender),
        backgroundColor: Colors.orange[300],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: widget.messages.length + sentMessages.length,
              itemBuilder: (context, index) {
                bool isSentMessage = index < sentMessages.length;

                String messageBody = isSentMessage
                    ? sentMessages[index]
                    : widget.messages[index - sentMessages.length].body ?? "No content";

                bool isUserMessage = isSentMessage;

                return Align(
                  alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUserMessage ? Colors.blue[200] : _getMessageColor(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(messageBody),
                        if (!isUserMessage)
                          Text(
                            _formatTimestamp(widget.messages[index - sentMessages.length].date),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildMessageInputField(), // Add message input field
        ],
      ),
    );
  }

  // Function to build message input field with send button
  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, spreadRadius: 2),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.orange),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  // Function to send an SMS message
  void _sendMessage() async {
    String messageText = _messageController.text.trim();

    if (messageText.isNotEmpty) {
      bool? permissionsGranted = await telephony.requestSmsPermissions;
      if (permissionsGranted!) {
        await telephony.sendSms(to: widget.sender, message: messageText);

        setState(() {
          sentMessages.insert(0, messageText); // Store message locally for UI update
        });

        _messageController.clear(); // Clear text field after sending
      } else {
        debugPrint("SMS permission not granted!");
      }
    }
  }

  // Function to determine the message color based on category
  Color _getMessageColor() {
    switch (widget.category) {
      case 'Spam':
        return Colors.red[200]!;
      case 'OTP':
        return Colors.green[200]!;
      default:
        return Colors.orange[200]!;
    }
  }

  // Timestamp formatter
  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return "";
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.hour}:${date.minute}";
  }
}
