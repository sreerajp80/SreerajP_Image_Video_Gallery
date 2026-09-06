import 'package:flutter/foundation.dart';

/// Immutable domain model representing a categorization tag for media items.
@immutable
class Tag {
  /// Unique identifier (UUID).
  final String id;

  /// Tag display name (e.g. "Nature", "Family", "Receipts").
  final String name;

  /// 32-bit ARGB color value used for visual chips in UI.
  final int colorValue;

  /// Optional description or notes for the tag.
  final String? description;

  /// Total number of media items currently assigned this tag.
  final int itemCount;

  /// Creation timestamp.
  final DateTime dateCreated;

  const Tag({
    required this.id,
    required this.name,
    required this.colorValue,
    this.description,
    this.itemCount = 0,
    required this.dateCreated,
  });

  /// Creates a copy of [Tag] with updated properties.
  Tag copyWith({
    String? id,
    String? name,
    int? colorValue,
    String? description,
    int? itemCount,
    DateTime? dateCreated,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      description: description ?? this.description,
      itemCount: itemCount ?? this.itemCount,
      dateCreated: dateCreated ?? this.dateCreated,
    );
  }

  /// Converts this [Tag] to a database-ready map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_value': colorValue,
      'description': description,
      'item_count': itemCount,
      'date_created': dateCreated.millisecondsSinceEpoch,
    };
  }

  /// Constructs a [Tag] from a database row or map.
  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      name: map['name'] as String,
      colorValue:
          (map['color_value'] ?? map['colorValue'] ?? 0xFF2196F3) as int,
      description: map['description'] as String?,
      itemCount: (map['item_count'] ?? map['itemCount'] ?? 0) as int,
      dateCreated: map['date_created'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['date_created'] as int)
          : DateTime.parse(map['date_created'].toString()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          colorValue == other.colorValue &&
          description == other.description &&
          itemCount == other.itemCount &&
          dateCreated == other.dateCreated;

  @override
  int get hashCode =>
      Object.hash(id, name, colorValue, description, itemCount, dateCreated);
}
