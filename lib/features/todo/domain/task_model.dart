import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'task_status.dart';

class TaskModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final String ownerId;
  final String ownerEmail;
  final List<String> sharedWith;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TaskStatus.notStarted,
    required this.ownerId,
    required this.ownerEmail,
    this.sharedWith = const [],
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: TaskStatus.fromString(data['status'] ?? 'notStarted'),
      ownerId: data['ownerId'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      sharedWith: List<String>.from(data['sharedWith'] ?? []),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'status': status.value,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'sharedWith': sharedWith,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    String? ownerId,
    String? ownerEmail,
    List<String>? sharedWith,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      sharedWith: sharedWith ?? this.sharedWith,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        ownerId,
        ownerEmail,
        sharedWith,
        dueDate,
        createdAt,
        updatedAt,
        completedAt,
      ];
}
