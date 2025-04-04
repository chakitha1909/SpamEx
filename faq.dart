import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> faqs = const [
    {"question": "What sections does SpamEx have?", "answer": "SpamEx includes Inbox, Spam, OTP, and Trash Bin sections for message organization."},
    {"question": "Can I customize the settings in SpamEx?","answer": "SpamEx is an advanced SMS spam detection app designed to filter spam messages and organize your inbox. It provides personalized settings, a trash bin for discarded messages, and features to enhance your overall messaging experience."},
    {"question": "How do I get help with the app?","answer": "You can call customer service or use the chat option for assistance."},
    {"question": "What should I do if a message is wrongly classified?", "answer": "You can manually move messages between Inbox and Spam for better classification."},
    {"question": "How does SpamEx detect spam messages?",  "answer": "SpamEx utilizes pre-trained language models to filter spam messages accurately."},
    {"question": "Can I permanently delete messages?", "answer": "Messages in Trash Bin can be permanently deleted after 30 days."},
    {"question": "Is SpamEx free to use?", "answer": "SpamEx offers free and premium versions with additional features."},
    {"question": "How does SpamEx protect my privacy?", "answer": "SpamEx processes messages locally without storing or sharing them."},
    {"question": "Can SpamEx detect SMS phishing attempts?", "answer": "SpamEx identifies phishing attempts and warns users."},
    {"question": "Will SpamEx work on my device?", "answer": "Ensure your OS is up to date for best performance."},
    {"question": "How do I report an issue with SpamEx?", "answer": "Issues can be reported via customer service or the website."},
    {"question": "Can I customize the spam detection rules?", "answer": "SpamEx plans to introduce user-defined spam filtering options."},
    {"question": "Does SpamEx require an internet connection?","answer": "Initial setup requires internet, but spam detection works offline."},
    {"question": "How do I update SpamEx?", "answer": "Update SpamEx via your device’s app store notifications."},
    {"question": "What happens to deleted spam messages?", "answer": "Deleted spam messages are stored in the Trash Bin before permanent removal."},
    {"question": "Can I use SpamEx on multiple devices?", "answer": "Multi-device syncing may be available in future versions."},
    {"question": "How do I restore messages from the Trash Bin?","answer": "Messages in Trash Bin can be restored before 30-day expiry."},
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text(
              faqs[index]['question']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(faqs[index]['answer']!),
              ),
            ],
          );
        },
      ),
    );
  }
}
