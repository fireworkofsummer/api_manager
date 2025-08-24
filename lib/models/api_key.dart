class ApiKey {
  final String id;
  final String providerId;
  final String keyValue;
  final String? alias;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsed;

  ApiKey({
    required this.id,
    required this.providerId,
    required this.keyValue,
    this.alias,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsed,
  });

  factory ApiKey.fromJson(Map<String, dynamic> json) {
    return ApiKey(
      id: json['id'],
      providerId: json['providerId'],
      keyValue: json['keyValue'],
      alias: json['alias'],
      description: json['description'],
      isActive: (json['isActive'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'keyValue': keyValue,
      'alias': alias,
      'description': description,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }

  ApiKey copyWith({
    String? id,
    String? providerId,
    String? keyValue,
    String? alias,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsed,
  }) {
    return ApiKey(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      keyValue: keyValue ?? this.keyValue,
      alias: alias ?? this.alias,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  String get maskedKey {
    if (keyValue.length <= 8) return '***';
    return '${keyValue.substring(0, 4)}...${keyValue.substring(keyValue.length - 4)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiKey && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ApiKey(id: $id, providerId: $providerId, alias: $alias, isActive: $isActive)';
  }
}
