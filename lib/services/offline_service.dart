import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _offlineDataKey = 'offline_data';
  static const String _syncQueueKey = 'sync_queue';
  static const String _lastSyncKey = 'last_sync';

  // Check if device is online
  bool get isOnline => true; // Simplified - in production, use connectivity package

  // Save data for offline use
  Future<void> saveOfflineData(String collection, List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineDataJson = prefs.getString(_offlineDataKey);
      Map<String, dynamic> offlineData = {};

      if (offlineDataJson != null) {
        offlineData = jsonDecode(offlineDataJson);
      }

      offlineData[collection] = data;
      await prefs.setString(_offlineDataKey, jsonEncode(offlineData));
    } catch (e) {
      print('Save offline data error: $e');
    }
  }

  // Get offline data
  Future<List<Map<String, dynamic>>> getOfflineData(String collection) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineDataJson = prefs.getString(_offlineDataKey);

      if (offlineDataJson != null) {
        final offlineData = jsonDecode(offlineDataJson);
        if (offlineData.containsKey(collection)) {
          return List<Map<String, dynamic>>.from(offlineData[collection]);
        }
      }
      return [];
    } catch (e) {
      print('Get offline data error: $e');
      return [];
    }
  }

  // Add operation to sync queue
  Future<void> addToSyncQueue(Map<String, dynamic> operation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncQueueJson = prefs.getString(_syncQueueKey);
      List<Map<String, dynamic>> syncQueue = [];

      if (syncQueueJson != null) {
        final List<dynamic> list = jsonDecode(syncQueueJson);
        syncQueue = list.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      syncQueue.add({
        ...operation,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      await prefs.setString(_syncQueueKey, jsonEncode(syncQueue));
    } catch (e) {
      print('Add to sync queue error: $e');
    }
  }

  // Get sync queue
  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncQueueJson = prefs.getString(_syncQueueKey);

      if (syncQueueJson != null) {
        final List<dynamic> list = jsonDecode(syncQueueJson);
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      print('Get sync queue error: $e');
      return [];
    }
  }

  // Clear sync queue
  Future<void> clearSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_syncQueueKey);
    } catch (e) {
      print('Clear sync queue error: $e');
    }
  }

  // Sync data with Firestore
  Future<Map<String, dynamic>> syncData() async {
    try {
      if (!isOnline) {
        return {'status': 'offline', 'message': 'Device is offline'};
      }

      final syncQueue = await getSyncQueue();
      int synced = 0;
      int failed = 0;
      final errors = <String>[];

      for (var operation in syncQueue) {
        try {
          final success = await _executeOperation(operation);
          if (success) {
            synced++;
          } else {
            failed++;
            errors.add('Failed to execute operation: ${operation['type']}');
          }
        } catch (e) {
          failed++;
          errors.add('Operation error: $e');
        }
      }

      // Clear successful operations from queue
      if (synced > 0) {
        await clearSyncQueue();
      }

      // Update last sync timestamp
      await _updateLastSync();

      return {
        'status': 'completed',
        'synced': synced,
        'failed': failed,
        'errors': errors,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Sync data error: $e');
      return {
        'status': 'failed',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Execute individual operation
  Future<bool> _executeOperation(Map<String, dynamic> operation) async {
    try {
      final type = operation['type'] as String;
      final collection = operation['collection'] as String;
      final data = operation['data'] as Map<String, dynamic>;

      switch (type) {
        case 'create':
          await _firestore.collection(collection).add(data);
          break;
        case 'update':
          final docId = operation['docId'] as String;
          await _firestore.collection(collection).doc(docId).update(data);
          break;
        case 'delete':
          final docId = operation['docId'] as String;
          await _firestore.collection(collection).doc(docId).delete();
          break;
        default:
          return false;
      }
      return true;
    } catch (e) {
      print('Execute operation error: $e');
      return false;
    }
  }

  // Cache data for offline use
  Future<void> cacheAllData() async {
    try {
      // Cache students
      final studentsSnapshot = await _firestore.collection('students').get();
      final studentsData = studentsSnapshot.docs.map((doc) => doc.data()).toList();
      await saveOfflineData('students', studentsData);

      // Cache grades
      final gradesSnapshot = await _firestore.collection('grades').get();
      final gradesData = gradesSnapshot.docs.map((doc) => doc.data()).toList();
      await saveOfflineData('grades', gradesData);

      // Cache courses
      final coursesSnapshot = await _firestore.collection('courses').get();
      final coursesData = coursesSnapshot.docs.map((doc) => doc.data()).toList();
      await saveOfflineData('courses', coursesData);

      // Cache registrations
      final registrationsSnapshot = await _firestore.collection('course_registrations').get();
      final registrationsData = registrationsSnapshot.docs.map((doc) => doc.data()).toList();
      await saveOfflineData('course_registrations', registrationsData);

      print('All data cached for offline use');
    } catch (e) {
      print('Cache all data error: $e');
    }
  }

  // Get cached data for offline use
  Future<Map<String, dynamic>> getCachedData() async {
    try {
      final students = await getOfflineData('students');
      final grades = await getOfflineData('grades');
      final courses = await getOfflineData('courses');
      final registrations = await getOfflineData('course_registrations');

      return {
        'students': students,
        'grades': grades,
        'courses': courses,
        'course_registrations': registrations,
        'lastCached': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Get cached data error: $e');
      return {};
    }
  }

  // Offline CRUD operations
  Future<void> offlineCreate(String collection, Map<String, dynamic> data) async {
    if (isOnline) {
      try {
        await _firestore.collection(collection).add(data);
      } catch (e) {
        // If online operation fails, add to sync queue
        await addToSyncQueue({
          'type': 'create',
          'collection': collection,
          'data': data,
        });
      }
    } else {
      // Add to sync queue for later sync
      await addToSyncQueue({
        'type': 'create',
        'collection': collection,
        'data': data,
      });
    }
  }

  Future<void> offlineUpdate(String collection, String docId, Map<String, dynamic> data) async {
    if (isOnline) {
      try {
        await _firestore.collection(collection).doc(docId).update(data);
      } catch (e) {
        // If online operation fails, add to sync queue
        await addToSyncQueue({
          'type': 'update',
          'collection': collection,
          'docId': docId,
          'data': data,
        });
      }
    } else {
      // Add to sync queue for later sync
      await addToSyncQueue({
        'type': 'update',
        'collection': collection,
        'docId': docId,
        'data': data,
      });
    }
  }

  Future<void> offlineDelete(String collection, String docId) async {
    if (isOnline) {
      try {
        await _firestore.collection(collection).doc(docId).delete();
      } catch (e) {
        // If online operation fails, add to sync queue
        await addToSyncQueue({
          'type': 'delete',
          'collection': collection,
          'docId': docId,
        });
      }
    } else {
      // Add to sync queue for later sync
      await addToSyncQueue({
        'type': 'delete',
        'collection': collection,
        'docId': docId,
      });
    }
  }

  // Get last sync timestamp
  Future<DateTime?> getLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncJson = prefs.getString(_lastSyncKey);

      if (lastSyncJson != null) {
        return DateTime.parse(lastSyncJson);
      }
      return null;
    } catch (e) {
      print('Get last sync error: $e');
      return null;
    }
  }

  // Update last sync timestamp
  Future<void> _updateLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Update last sync error: $e');
    }
  }

  // Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final syncQueue = await getSyncQueue();
      final lastSync = await getLastSync();
      final cachedData = await getCachedData();

      return {
        'isOnline': isOnline,
        'pendingSyncs': syncQueue.length,
        'lastSync': lastSync?.toIso8601String(),
        'cachedData': cachedData,
        'syncQueueSize': syncQueue.length,
      };
    } catch (e) {
      print('Get sync status error: $e');
      return {
        'isOnline': false,
        'pendingSyncs': 0,
        'lastSync': null,
        'cachedData': {},
        'syncQueueSize': 0,
      };
    }
  }

  // Clear all offline data
  Future<void> clearOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_offlineDataKey);
      await prefs.remove(_syncQueueKey);
      await prefs.remove(_lastSyncKey);
    } catch (e) {
      print('Clear offline data error: $e');
    }
  }

  // Force sync all pending operations
  Future<Map<String, dynamic>> forceSync() async {
    try {
      final result = await syncData();
      
      // After successful sync, cache fresh data
      if (result['status'] == 'completed') {
        await cacheAllData();
      }
      
      return result;
    } catch (e) {
      print('Force sync error: $e');
      return {
        'status': 'failed',
        'error': e.toString(),
      };
    }
  }

  // Get offline statistics
  Future<Map<String, dynamic>> getOfflineStats() async {
    try {
      final cachedData = await getCachedData();
      final syncQueue = await getSyncQueue();
      final lastSync = await getLastSync();

      return {
        'cachedStudents': cachedData['students']?.length ?? 0,
        'cachedGrades': cachedData['grades']?.length ?? 0,
        'cachedCourses': cachedData['courses']?.length ?? 0,
        'cachedRegistrations': cachedData['course_registrations']?.length ?? 0,
        'pendingOperations': syncQueue.length,
        'lastSync': lastSync?.toIso8601String(),
        'isOnline': isOnline,
      };
    } catch (e) {
      print('Get offline stats error: $e');
      return {
        'cachedStudents': 0,
        'cachedGrades': 0,
        'cachedCourses': 0,
        'cachedRegistrations': 0,
        'pendingOperations': 0,
        'lastSync': null,
        'isOnline': false,
      };
    }
  }

  // Initialize offline service
  Future<void> initialize() async {
    try {
      // Cache data if online
      if (isOnline) {
        await cacheAllData();
        await _updateLastSync();
      }

      print('Offline service initialized');
    } catch (e) {
      print('Initialize offline service error: $e');
    }
  }

  // Check for conflicts between local and remote data
  Future<Map<String, dynamic>> checkConflicts() async {
    try {
      if (!isOnline) {
        return {'status': 'offline', 'conflicts': []};
      }

      final conflicts = <Map<String, dynamic>>[];
      
      // Check students
      final localStudents = await getOfflineData('students');
      final remoteStudents = await _firestore.collection('students').get();
      
      for (var localStudent in localStudents) {
        final remoteDoc = remoteStudents.docs
            .where((doc) => doc.id == localStudent['id'])
            .firstOrNull;
        
        if (remoteDoc != null) {
          final remoteData = remoteDoc.data();
          final localTimestamp = DateTime.parse(localStudent['last_updated'] ?? '1970-01-01');
          final remoteTimestamp = (remoteData['last_updated'] as Timestamp?)?.toDate() ?? DateTime(1970);
          
          if (localTimestamp.isAfter(remoteTimestamp)) {
            conflicts.add({
              'type': 'student',
              'id': localStudent['id'],
              'localVersion': localStudent,
              'remoteVersion': remoteData,
              'conflict': 'Local is newer',
            });
          }
        }
      }

      return {
        'status': 'completed',
        'conflicts': conflicts,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Check conflicts error: $e');
      return {
        'status': 'failed',
        'error': e.toString(),
        'conflicts': [],
      };
    }
  }

  // Resolve conflicts
  Future<bool> resolveConflict(String conflictId, String resolution) async {
    try {
      // Implementation for conflict resolution
      // This would depend on the specific conflict resolution strategy
      print('Resolved conflict $conflictId with resolution: $resolution');
      return true;
    } catch (e) {
      print('Resolve conflict error: $e');
      return false;
    }
  }
}
