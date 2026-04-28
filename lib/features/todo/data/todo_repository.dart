import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../domain/comment_model.dart';
import '../domain/task_model.dart';
import '../domain/task_status.dart';

class TodoRepository {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  TodoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _tasksCollection => _firestore.collection('tasks');

  Future<String> addTask(TaskModel task) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final newTask = task.copyWith(
      id: id,
      createdAt: now,
      updatedAt: now,
    );
    await _tasksCollection.doc(id).set(newTask.toFirestore());
    return id;
  }

  Future<void> updateTask(TaskModel task) async {
    final updatedTask = task.copyWith(updatedAt: DateTime.now());
    await _tasksCollection.doc(task.id).update(updatedTask.toFirestore());
  }

  Future<void> deleteTask(String taskId) async {
    // Delete comments subcollection first to avoid ghost documents
    final comments = await _tasksCollection
        .doc(taskId)
        .collection('comments')
        .get();
    for (final doc in comments.docs) {
      await doc.reference.delete();
    }
    await _tasksCollection.doc(taskId).delete();
  }

  Future<TaskModel?> getTaskById(String taskId) async {
    final doc = await _tasksCollection.doc(taskId).get();
    if (!doc.exists) return null;
    return TaskModel.fromFirestore(doc);
  }

  Stream<List<TaskModel>> watchMyTasks(String uid) {
    return _tasksCollection
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final tasks =
          snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return tasks;
    });
  }

  Stream<List<TaskModel>> watchSharedTasks(String uid) {
    return _tasksCollection
        .where('sharedWith', arrayContains: uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  Stream<List<CommentModel>> watchComments(String taskId) {
    return _tasksCollection
        .doc(taskId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList());
  }

  Future<void> addComment(String taskId, CommentModel comment) async {
    final id = _uuid.v4();
    await _tasksCollection
        .doc(taskId)
        .collection('comments')
        .doc(id)
        .set(comment.toFirestore());
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final Map<String, dynamic> data = {
      'status': status.value,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (status == TaskStatus.completed) {
      data['completedAt'] = Timestamp.fromDate(DateTime.now());
    } else {
      data['completedAt'] = null;
    }

    await _tasksCollection.doc(taskId).update(data);
  }
}
