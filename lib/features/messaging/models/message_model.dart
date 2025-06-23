class Message {
  final int id;
  final int useridfrom;
  final String text;
  final int timecreated;

  Message({
    required this.id,
    required this.useridfrom,
    required this.text,
    required this.timecreated,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      useridfrom: json['useridfrom'] ?? 0,
      text: json['text'] ?? '',
      timecreated: json['timecreated'] ?? 0,
    );
  }
}