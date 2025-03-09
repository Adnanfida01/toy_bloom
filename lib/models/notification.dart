class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final String type;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      time: (map['time'] as DateTime),
      type: map['type'] as String,
      isRead: map['isRead'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'time': time,
      'type': type,
      'isRead': isRead,
    };
  }
}
