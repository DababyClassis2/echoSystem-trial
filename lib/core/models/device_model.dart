class DeviceModel {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final bool isOnline;
  final int avatarColor;
  final DateTime lastSeen;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    this.isOnline = true,
    this.avatarColor = 0xFF4A5B6E,
    required this.lastSeen,
  });

  String get displayName => name.length > 20 ? '${name.substring(0, 20)}…' : name;

  DeviceModel copyWith({
    String? id,
    String? name,
    String? ipAddress,
    int? port,
    bool? isOnline,
    int? avatarColor,
    DateTime? lastSeen,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      isOnline: isOnline ?? this.isOnline,
      avatarColor: avatarColor ?? this.avatarColor,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        ipAddress: json['ipAddress'] as String,
        port: json['port'] as int,
        isOnline: json['isOnline'] as bool? ?? true,
        avatarColor: json['avatarColor'] as int? ?? 0xFF4A5B6E,
        lastSeen: DateTime.parse(json['lastSeen'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ipAddress': ipAddress,
        'port': port,
        'isOnline': isOnline,
        'avatarColor': avatarColor,
        'lastSeen': lastSeen.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DeviceModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
