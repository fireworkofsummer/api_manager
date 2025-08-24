class ApiProvider {
  final String id;
  final String name;
  final String baseUrl;
  final String? iconUrl;
  final bool isCustom;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApiProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.iconUrl,
    this.isCustom = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiProvider.fromJson(Map<String, dynamic> json) {
    return ApiProvider(
      id: json['id'],
      name: json['name'],
      baseUrl: json['baseUrl'],
      iconUrl: json['iconUrl'],
      isCustom: (json['isCustom'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'iconUrl': iconUrl,
      'isCustom': isCustom ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ApiProvider copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? iconUrl,
    bool? isCustom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ApiProvider(id: $id, name: $name, baseUrl: $baseUrl, isCustom: $isCustom)';
  }
}