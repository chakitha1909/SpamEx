import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';

class MessageSearch extends SearchDelegate<SmsMessage?> {
  final List<SmsMessage> allMessages;

  MessageSearch(this.allMessages);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = "";
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<SmsMessage> searchResults = allMessages.where((msg) {
      return msg.body!.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        SmsMessage message = searchResults[index];
        return ListTile(
          title: Text(message.address ?? "Unknown"),
          subtitle: Text(message.body ?? ""),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
