class ChatUser {
  final int id;
  final String fullname;
  final String profileimageurl;
  final bool showonlinestatus;

  ChatUser({
    required this.id,
    required this.fullname,
    required this.profileimageurl,
    this.showonlinestatus = false,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? 0,
      fullname: json['fullname'] ?? 'Unknown User',
      profileimageurl: json['profileimageurl'] ?? 'https://placehold.co/600x600/E16B3A/white?text=U',
      showonlinestatus: json['showonlinestatus'] ?? false,
    );
  }
}