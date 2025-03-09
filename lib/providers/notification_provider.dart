import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification.dart';

enum NotificationType { addition, removal, other }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  final String? productId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.productId,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    String? productId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      productId: productId ?? this.productId,
    );
  }
}

class NotificationProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<NotificationItem> _notifications = [];
  bool _hasPermission = false;
  final String _permissionKey = 'notification_permission';
  int _unreadCount = 0;

  List<NotificationItem> get notifications => [..._notifications];
  bool get hasPermission => _hasPermission;
  int get unreadCount => _unreadCount;

  NotificationProvider() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    _hasPermission = prefs.getBool(_permissionKey) ?? false;
    if (_hasPermission) {
      await requestPermission();
    }

    notifyListeners();
  }

  Future<bool> checkPermissionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _hasPermission = prefs.getBool(_permissionKey) ?? false;

    if (_hasPermission) {
      final status = await FirebaseMessaging.instance.getNotificationSettings();
      _hasPermission =
          status.authorizationStatus == AuthorizationStatus.authorized;
      await prefs.setBool(_permissionKey, _hasPermission);
    }

    notifyListeners();
    return _hasPermission;
  }

  Future<bool> requestPermission() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    _hasPermission =
        settings.authorizationStatus == AuthorizationStatus.authorized;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionKey, _hasPermission);

    notifyListeners();
    return _hasPermission;
  }

  void _loadUnreadCount(String userId) {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get()
        .then((snapshot) {
      _unreadCount = snapshot.docs.length;
      notifyListeners();
    });
  }

  void _subscribeToNotifications(String userId) {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      _unreadCount = snapshot.docs.length;
      notifyListeners();
    });
  }

  void _loadNotifications(String userId) {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationItem(
          id: doc.id,
          title: data['title'] ?? 'Notification',
          message: data['message'] ?? '',
          timestamp:
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
          type: data['type'] ?? 'general',
          productId: data['productId'],
        );
      }).toList();
      notifyListeners();
    });
  }

  NotificationType _getNotificationType(String type) {
    switch (type) {
      case 'addition':
        return NotificationType.addition;
      case 'removal':
        return NotificationType.removal;
      default:
        return NotificationType.other;
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
      productId: null,
    );

    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();

    // Store in Firestore if needed
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .set({
        'title': title,
        'message': message,
        'timestamp': DateTime.now(),
        'type': type,
        'isRead': false,
      });
    } catch (e) {
      print('Error storing notification: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      _notifications.removeWhere((n) => n.id == notificationId);
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  // Add a notification when product is added to cart
  Future<void> addCartNotification(String productName) async {
    await addNotification(
      title: 'Added to Cart',
      message: 'You added $productName to your cart',
      type: 'cart',
    );
  }

  // Add a notification when profile is updated
  Future<void> addProfileUpdateNotification() async {
    await addNotification(
      title: 'Profile Updated',
      message: 'Your profile information has been updated successfully',
      type: 'profile',
    );
  }

  // Add an order notification
  Future<void> addOrderNotification(String orderId) async {
    await addNotification(
      title: 'Order Placed',
      message: 'Your order #$orderId has been placed successfully',
      type: 'order',
    );
  }

  Future<void> sendNewProductNotification(
      String productName, String productId) async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final batch = _firestore.batch();

      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc();

        batch.set(notificationRef, {
          'title': 'New Product Available!',
          'message': 'Check out our new product: $productName',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'new_product',
          'productId': productId,
        });
      }

      await batch.commit();
      await loadNotifications(); // Reload notifications after sending
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }

  Future<void> loadNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      _notifications = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationItem(
          id: doc.id,
          title: data['title'] ?? '',
          message: data['message'] ?? '',
          timestamp:
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
          type: data['type'] ?? 'general',
          productId: data['productId'],
        );
      }).toList();

      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }
}
