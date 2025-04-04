import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final Telephony telephony = Telephony.instance;
  Map<String, List<SmsMessage>> inboxMessages = {};
  Map<String, List<SmsMessage>> spamMessages = {};
  Map<String, List<SmsMessage>> otpMessages = {};
  List<String> allSenders = [];
  List<Contact> contacts = []; // Store contacts
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  final String apiUrl = "https://6bf7-135-235-210-21.ngrok-free.app/classify";

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  void _checkAndRequestPermissions() async {
    PermissionStatus smsStatus = await Permission.sms.status;
    PermissionStatus contactsStatus = await Permission.contacts.status;

    if (!smsStatus.isGranted) {
      smsStatus = await Permission.sms.request();
    }
    if (!contactsStatus.isGranted) {
      contactsStatus = await Permission.contacts.request();
    }

    if (smsStatus.isGranted && contactsStatus.isGranted) {
      _fetchMessages();
      _fetchContacts(); // Fetch contacts after permission is granted
      Timer.periodic(const Duration(seconds: 2), (Timer timer) {
        _fetchMessages();
      });
    } else {
      debugPrint("Permissions not granted");
    }
  }

  Future<void> _fetchMessages() async {
  bool? permissionsGranted = await telephony.requestSmsPermissions;
  if (permissionsGranted ?? false) {
    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
    );

    // Call API for classification
    List<bool> classifications = await _classifyMessagesWithAPI(messages);

    setState(() {
      inboxMessages.clear();
      spamMessages.clear();
      otpMessages.clear();
      allSenders.clear();

      for (int i = 0; i < messages.length; i++) {
          String sender = messages[i].address ?? "Unknown";
          if (messages[i].body?.toLowerCase().contains("otp") ?? false) {
            _addToCategory(otpMessages, sender, messages[i]);
          } else if (classifications[i] || _isSpam(messages[i].body ?? "")) {
            _addToCategory(spamMessages, sender, messages[i]);
          } else {
            _addToCategory(inboxMessages, sender, messages[i]);
          }
        }

      allSenders = [...inboxMessages.keys, ...spamMessages.keys, ...otpMessages.keys];
    });
  }
}

  Future<List<bool>> _classifyMessagesWithAPI(List<SmsMessage> messages) async {
  const String apiUrl = "https://6bf7-135-235-210-21.ngrok-free.app/classify";
  List<Map<String, String>> smsData = messages
      .take(200) // Send only the latest 200 messages
      .map((msg) => {"sms": msg.body ?? "", "sender": msg.address ?? "Unknown"})
      .toList();

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"messages": smsData}),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.cast<bool>(); // Convert API response to List<bool>
    } else {
      debugPrint("API Error: ${response.statusCode}");
      return List<bool>.filled(messages.length, false); // Default to non-spam if error
    }
  } catch (e) {
    debugPrint("API Call Failed: $e");
    return List<bool>.filled(messages.length, false); // Default to non-spam if exception occurs
  }
}

  bool _isSpam(String message) {
  List<String> spamKeywords = [
    // English Spam Keywords
    "win", "free", "prize", "offer", "congratulations", "money", "loan",
    
    // Hindi Spam Keywords
    "मुफ़्त", "इनाम", "ऋण", "धन", "पुरस्कार", "बधाई", "फ्री", "ऑफर", "अर्जेंट", "कर्ज",
    
    // Telugu Spam Keywords
    "ఉచితం", "బహుమతి", "పరిష్కారం", "ఫ్రీ", "ఆఫర్", "అవకాశం", "సెల్", "ధనం", "రుణం"
  ];

  String normalizedMessage = message.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
  
  return spamKeywords.any((keyword) => normalizedMessage.contains(keyword));
}


  Future<void> _fetchContacts() async {
    if (await Permission.contacts.isGranted) {
      List<Contact> fetchedContacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        contacts = fetchedContacts;
      });
    } else {
      debugPrint("Contacts permission not granted");
    }
  }
  void _addToCategory(Map<String, List<SmsMessage>> category, String sender, SmsMessage message) {
    category.putIfAbsent(sender, () => []).add(message);
  }

  void _openChatScreen(String sender, List<SmsMessage> messages, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          sender: sender,
          messages: messages,
          category: category,
        ),
      ),
    );
  }

  void _openProfileScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileScreen(
        onClose: () => Navigator.pop(context),
        toggleTheme: (bool isDark) {},
      ),
    );
  }

  void _showContactsBottomSheet() {
  TextEditingController contactSearchController = TextEditingController();
  List<Contact> filteredContacts = contacts; // Copy of the contacts list

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // To make it blend smoothly
    builder: (context) {
      return DraggableScrollableSheet(
        expand: true,
        initialChildSize: 1.0, // Full screen
        minChildSize: 0.5, // Allows dragging down
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Title
                const Text(
                  "Select a Contact",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Search Bar
                TextField(
                  controller: contactSearchController,
                  decoration: InputDecoration(
                    hintText: "Search contacts...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (query) {
                    filteredContacts = contacts
                        .where((contact) =>
                            contact.displayName.toLowerCase().contains(query.toLowerCase()))
                        .toList();
                  },
                ),
                const SizedBox(height: 10),

                // Contacts List
                Expanded(
                  child: filteredContacts.isNotEmpty
                      ? ListView.builder(
                          controller: scrollController,
                          itemCount: filteredContacts.length,
                          itemBuilder: (context, index) {
                            Contact contact = filteredContacts[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange[300],
                                child: const Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                contact.displayName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _openChatScreen(contact.displayName, [], "SpamEx");
                              },
                            );
                          },
                        )
                      : const Center(child: Text("No Contacts Found")),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  Widget _buildMessageList(Map<String, List<SmsMessage>> category, Color color, String categoryName) {
    List<String> filteredSenders = isSearching
        ? allSenders.where((sender) => sender.toLowerCase().contains(searchController.text.toLowerCase())).toList()
        : category.keys.toList();

    return ListView.builder(
      itemCount: filteredSenders.length,
      itemBuilder: (context, index) {
        String sender = filteredSenders[index];
        List<SmsMessage> messages = category[sender] ?? [];
        if (messages.isEmpty) return const SizedBox.shrink();
        SmsMessage recentMessage = messages.first;

        return ListTile(
          leading: CircleAvatar(backgroundColor: color, child: const Icon(Icons.message, color: Colors.white)),
          title: Text(sender, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(recentMessage.body ?? "No content", maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(_formatTimestamp(recentMessage.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          onTap: () => _openChatScreen(sender, messages, categoryName),
        );
      },
    );
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return "";
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: isSearching
              ? TextField(
                  controller: searchController,
                  decoration: const InputDecoration(hintText: "Search messages...", border: InputBorder.none),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (query) => setState(() {}),
                )
              : const Text("SpamEx"),
          backgroundColor: Colors.orange[300],
          actions: [
            IconButton(
              icon: Icon(isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  isSearching = !isSearching;
                  if (!isSearching) searchController.clear();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: _openProfileScreen,
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: "Inbox"), Tab(text: "Spam"), Tab(text: "OTP")],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMessageList(inboxMessages, Colors.orange, "Inbox"),
            _buildMessageList(spamMessages, Colors.red, "Spam"),
            _buildMessageList(otpMessages, Colors.green, "OTP"),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showContactsBottomSheet,
          backgroundColor: Colors.orange[300],
          child: const Icon(Icons.chat),
        ),
      ),
    );
  }
}
