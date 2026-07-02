class Envelop {
  String sender;
  String receiver;
  String intent;
  Map<String, dynamic> payload;
  String traceId;
  String messageId;
  String channelId;
  int ttl;
  Map<String, dynamic> meta;
  String createdAt;

  Envelop({
    this.sender = '',
    this.receiver = '',
    this.intent = '',
    Map<String, dynamic>? payload,
    this.channelId = '',
    this.ttl = 10,
    Map<String, dynamic>? meta,
  })  : payload = payload ?? {},
        meta = meta ?? {},
        traceId = 'tr_${_uuid8()}',
        messageId = 'msg_${_uuid6()}',
        createdAt = DateTime.now().toIso8601String();

  // 对应 Python 的 to_dict()
  Map<String, dynamic> toJson() => {
    'sender': sender,
    'receiver': receiver,
    'intent': intent,
    'payload': payload,
    'trace_id': traceId,
    'message_id': messageId,
    'channel_id': channelId,
    'ttl': ttl,
    'meta': meta,
    'created_at': createdAt,
  };

  // 对应 Python 的 from_dict()
  factory Envelop.fromJson(Map<String, dynamic> json) {
    return Envelop(
      sender: json['sender'] ?? '',
      receiver: json['receiver'] ?? '',
      intent: json['intent'] ?? '',
      payload: json['payload'] ?? {},
      channelId: json['channel_id'] ?? '',
      ttl: json['ttl'] ?? 10,
      meta: json['meta'] ?? {},
    )..traceId = json['trace_id'] ?? 'tr_${_uuid8()}'
     ..messageId = json['message_id'] ?? 'msg_${_uuid6()}'
     ..createdAt = json['created_at'] ?? DateTime.now().toIso8601String();
  }

  Envelop copyWith({Map<String, dynamic>? payload, Map<String, dynamic>? meta}) {
    return Envelop(
      sender: sender,
      receiver: receiver,
      intent: intent,
      payload: payload ?? this.payload,
      channelId: channelId,
      ttl: ttl,
      meta: meta ?? this.meta,
    )..traceId = traceId
     ..messageId = messageId
     ..createdAt = createdAt;
  }

  // 工具函数
  static String _uuid8() => DateTime.now().microsecondsSinceEpoch.toRadixString(36).substring(0, 8);
  static String _uuid6() => DateTime.now().microsecondsSinceEpoch.toRadixString(36).substring(0, 6);
}