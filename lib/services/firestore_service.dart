import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';

final _auth = fb_auth.FirebaseAuth.instance;
final _db = FirebaseFirestore.instance;

class FirestoreService {
  static fb_auth.User? get _user => _auth.currentUser;
  static String get _uid => _user?.uid ?? '';
  static String get _username {
    final displayName = _user?.displayName;
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = _user?.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'User';
  }

  static const int maxActiveBorrows = 5;

  // ── In-memory rating cache ──
  static final Map<String, Map<String, dynamic>> _ratingCache = {};
  static final Map<String, DateTime> _ratingCacheTime = {};
  static const _ratingCacheDuration = Duration(minutes: 5);

  static Future<int> getActiveBorrowCount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return 0;
    try {
      final snap = await _db
          .collection('exchanges')
          .where('holderId', isEqualTo: uid)
          .where('status', whereIn: ['active', 'pending_receipt'])
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      debugPrint('getActiveBorrowCount error: $e');
      return 0;
    }
  }

  static Future<bool> canBorrowMore() async {
    final count = await getActiveBorrowCount();
    return count < maxActiveBorrows;
  }

  static Future<Map<String, dynamic>> getUserRating(String userId) async {
    if (userId.isEmpty) return {'positive': 0, 'total': 0, 'percentage': 0, 'average': 0.0};
    final cacheTime = _ratingCacheTime[userId];
    if (cacheTime != null && DateTime.now().difference(cacheTime) < _ratingCacheDuration) {
      return _ratingCache[userId]!;
    }
    try {
      final results = await Future.wait([
        _db.collection('feedback').where('toUserId', isEqualTo: userId).where('isPositive', isEqualTo: true).count().get(),
        _db.collection('feedback').where('toUserId', isEqualTo: userId).count().get(),
      ]);
      final positive = results[0].count ?? 0;
      final total = results[1].count ?? 0;
      final percentage = total > 0 ? (positive / total * 100).round() : 0;
      final average = total > 0 ? (positive / total) : 0.0;
      final result = {'positive': positive, 'total': total, 'percentage': percentage, 'average': average};
      _ratingCache[userId] = result;
      _ratingCacheTime[userId] = DateTime.now();
      return result;
    } catch (e) {
      debugPrint('getUserRating error: $e');
      return {'positive': 0, 'total': 0, 'percentage': 0, 'average': 0.0};
    }
  }

  static Stream<QuerySnapshot> streamUserFeedback(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    return _db
        .collection('feedback')
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) => debugPrint('streamUserFeedback error: $e'));
  }

  static Stream<QuerySnapshot> streamMyToys() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return const Stream.empty();
    return _db
        .collection('toys')
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) => debugPrint('streamMyToys error: $e'));
  }

  static Stream<QuerySnapshot> streamAvailableToys() {
    return _db
        .collection('toys')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .handleError((e) => debugPrint('streamAvailableToys error: $e'));
  }

  static Future<void> addToy(Map<String, dynamic> data) async {
    await _db.collection('toys').add({
      ...data,
      'ownerId': _uid,
      'ownerName': _username,
      'isAvailable': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteToy(String docId) async {
    await _db.collection('toys').doc(docId).delete();
  }

  static Stream<QuerySnapshot> streamRequestsReceived() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return const Stream.empty();
    return _db
        .collection('requests')
        .where('ownerId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) => debugPrint('streamRequestsReceived error: $e'));
  }

  static Stream<bool> streamHasRequested(String toyDocId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return Stream.value(false);
    return _db
        .collection('requests')
        .where('toyId', isEqualTo: toyDocId)
        .where('requesterId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.isNotEmpty)
        .handleError((_) => false);
  }

  static Future<void> requestToy({
    required String toyDocId,
    required String toyName,
    required String ownerUid,
    required String message,
  }) async {
    if (ownerUid == _uid) throw Exception('Cannot request your own toy');
    final existing = await _db
        .collection('requests')
        .where('toyId', isEqualTo: toyDocId)
        .where('requesterId', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) throw Exception('already_requested');
    final canBorrow = await canBorrowMore();
    if (!canBorrow) throw Exception('You have reached the maximum limit of $maxActiveBorrows active borrows.');
    await _db.collection('requests').add({
      'toyId': toyDocId,
      'toyName': toyName,
      'ownerId': ownerUid,
      'requesterId': _uid,
      'requesterName': _username,
      'status': 'pending',
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _createNotification(
      userId: ownerUid,
      title: '📦 New Request',
      body: '$_username wants to borrow your toy "$toyName".',
      type: 'request_received',
    );
  }

  static Future<void> respondToRequest({
    required String requestDocId,
    required String toyDocId,
    required bool accept,
  }) async {
    final reqSnap = await _db.collection('requests').doc(requestDocId).get();
    if (!reqSnap.exists) throw Exception('Request not found');
    final req = reqSnap.data()!;
    if (accept) {
      final toySnap = await _db.collection('toys').doc(toyDocId).get();
      if (!toySnap.exists) throw Exception('Toy not found');
      final toy = toySnap.data()!;
      final batch = _db.batch();
      batch.update(_db.collection('requests').doc(requestDocId), {'status': 'accepted'});
      batch.update(_db.collection('toys').doc(toyDocId), {
        'isAvailable': false,
        'toyStatus': 'exchanged',
        'currentHolderId': req['requesterId'],
        'currentHolderName': req['requesterName'],
      });
      final exchangeRef = _db.collection('exchanges').doc();
      batch.set(exchangeRef, {
        'toyId': toyDocId,
        'toyName': req['toyName'] ?? '',
        'ownerId': _uid,
        'ownerName': _username,
        'holderId': req['requesterId'],
        'holderName': req['requesterName'],
        'type': toy['type'] ?? 'exchange',
        'status': 'active',
        'receiveDate': toy['receiveDate'],
        'returnDate': toy['returnDate'],
        'startedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'disputeId': null,
        'disputeReason': null,
      });
      await batch.commit();
      await _createNotification(
        userId: req['requesterId'],
        title: '🎉 Request Accepted!',
        body: '$_username accepted your request for "${req['toyName']}".',
        type: 'request_accepted',
      );
      final others = await _db
          .collection('requests')
          .where('toyId', isEqualTo: toyDocId)
          .where('status', isEqualTo: 'pending')
          .get();
      for (final doc in others.docs) {
        if (doc.id == requestDocId) continue;
        await doc.reference.update({'status': 'rejected'});
        final requesterId = doc.data()['requesterId'];
        if (requesterId != null) {
          await _createNotification(
            userId: requesterId,
            title: '❌ Request Declined',
            body: 'Your request for "${req['toyName']}" was not accepted.',
            type: 'request_rejected',
          );
        }
      }
    } else {
      await _db.collection('requests').doc(requestDocId).update({'status': 'rejected'});
      final requesterId = req['requesterId'];
      if (requesterId != null) {
        await _createNotification(
          userId: requesterId,
          title: '❌ Request Declined',
          body: '$_username declined your request for "${req['toyName']}".',
          type: 'request_rejected',
        );
      }
    }
  }

  static Stream<QuerySnapshot> streamExchangesOwned() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return const Stream.empty();
    return _db
        .collection('exchanges')
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) => debugPrint('streamExchangesOwned error: $e'));
  }

  static Stream<QuerySnapshot> streamExchangesHeld() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return const Stream.empty();
    return _db
        .collection('exchanges')
        .where('holderId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) => debugPrint('streamExchangesHeld error: $e'));
  }

  static Future<void> checkReturnDateReminders() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    try {
      final holderSnap = await _db
          .collection('exchanges')
          .where('holderId', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .get();
      for (final doc in holderSnap.docs) {
        final data = doc.data();
        final returnDateStr = data['returnDate'] as String?;
        if (returnDateStr == null) continue;
        final returnDate = DateTime.tryParse(returnDateStr);
        if (returnDate == null) continue;
        final now2 = DateTime.now();
        final diff = returnDate.difference(now2);
        final daysLeft = returnDate.difference(todayStart).inDays;
        final toyName = data['toyName'] ?? 'A toy';
        final ownerName = data['ownerName'] ?? 'the owner';
        final durationMode = data['durationMode'] ?? 'days';
        final existingToday = await _db
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .where('relatedId', isEqualTo: doc.id)
            .where('type', whereIn: ['return_reminder', 'return_overdue'])
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        if (existingToday.docs.isNotEmpty) {
          final lastTs = existingToday.docs.first.data()['createdAt'] as Timestamp?;
          if (lastTs != null) {
            final lastDate = lastTs.toDate();
            final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
            if (lastDay == todayStart) continue;
          }
        }
        if (daysLeft < 0) {
          await _createNotification(userId: uid, title: '⚠️ Overdue Return',
            body: '"$toyName" was due ${daysLeft.abs()} day(s) ago. Please return it to $ownerName.',
            type: 'return_overdue', relatedId: doc.id);
          final ownerUid = data['ownerId'] as String?;
          if (ownerUid != null && ownerUid.isNotEmpty) {
            final holderName = data['holderName'] ?? 'The borrower';
            await _createNotification(userId: ownerUid, title: '⚠️ Return Overdue',
              body: '"$toyName" lent to $holderName is ${daysLeft.abs()} day(s) overdue.',
              type: 'return_overdue', relatedId: doc.id);
          }
        } else if (durationMode == 'hours' && diff.inMinutes <= 30 && diff.inMinutes > 0) {
          await _createNotification(userId: uid, title: '⏰ Return Due Soon',
            body: '"$toyName" is due back to $ownerName in ${diff.inMinutes} minutes.',
            type: 'return_reminder', relatedId: doc.id);
        } else if (daysLeft == 0) {
          await _createNotification(userId: uid, title: '📅 Return Due Today',
            body: '"$toyName" is due back to $ownerName today.',
            type: 'return_reminder', relatedId: doc.id);
        } else if (daysLeft == 1) {
          await _createNotification(userId: uid, title: '⏰ Return Due Tomorrow',
            body: '"$toyName" is due back to $ownerName tomorrow.',
            type: 'return_reminder', relatedId: doc.id);
        } else if (daysLeft <= 3) {
          await _createNotification(userId: uid, title: '📅 Return Reminder',
            body: '"$toyName" is due back in $daysLeft days.',
            type: 'return_reminder', relatedId: doc.id);
        }
      }
    } catch (e) {
      debugPrint('checkReturnDateReminders error: $e');
    }
  }

  static Future<void> returnToy({
    required String exchangeDocId,
    required String toyDocId,
    required String ownerUid,
    required String toyName,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('exchanges').doc(exchangeDocId), {
      'status': 'pending_receipt',
      'returnInitiatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('toys').doc(toyDocId), {'toyStatus': 'pending_receipt'});
    await batch.commit();
    await _createNotification(
      userId: ownerUid,
      title: '🔄 Toy Being Returned',
      body: '$_username has initiated the return of "$toyName". Please confirm receipt.',
      type: 'toy_returned',
      relatedId: exchangeDocId,
    );
  }

  static Future<void> confirmToyReceipt({
    required String exchangeDocId,
    required String toyDocId,
    required String holderUid,
    required String toyName,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('exchanges').doc(exchangeDocId), {
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('toys').doc(toyDocId), {
      'isAvailable': true,
      'toyStatus': 'available',
      'currentHolderId': FieldValue.delete(),
      'currentHolderName': FieldValue.delete(),
    });
    await batch.commit();
    await _createNotification(
      userId: holderUid,
      title: '✅ Return Confirmed',
      body: 'The owner has confirmed receipt of "$toyName". Exchange complete!',
      type: 'request_accepted',
      relatedId: exchangeDocId,
    );
  }

  static Future<void> reportDispute({
    required String exchangeDocId,
    required String toyDocId,
    required String otherPartyId,
    required String otherPartyName,
    required String reason,
  }) async {
    if (exchangeDocId.isEmpty) throw Exception('Invalid exchange ID');
    final batch = _db.batch();
    final disputeRef = _db.collection('disputes').doc();
    batch.set(disputeRef, {
      'exchangeId': exchangeDocId,
      'reporterId': _uid,
      'reporterName': _username,
      'otherPartyId': otherPartyId,
      'otherPartyName': otherPartyName,
      'reason': reason.trim(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    });
    batch.update(_db.collection('exchanges').doc(exchangeDocId), {
      'status': 'disputed',
      'disputeId': disputeRef.id,
      'disputeReason': reason.trim(),
    });
    if (toyDocId.isNotEmpty) {
      batch.update(_db.collection('toys').doc(toyDocId), {'toyStatus': 'disputed'});
    }
    await batch.commit();
    if (otherPartyId.isNotEmpty) {
      await _createNotification(
        userId: otherPartyId,
        title: '⚠️ Dispute Reported',
        body: '$_username has reported an issue with the exchange.',
        type: 'dispute_opened',
        relatedId: exchangeDocId,
      );
    }
  }

  static Stream<QuerySnapshot> streamMessages(String exchangeId) {
    if (exchangeId.isEmpty) return const Stream.empty();
    return _db
        .collection('messages')
        .where('exchangeId', isEqualTo: exchangeId)
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .handleError((e) => debugPrint('streamMessages error: $e'));
  }

  static Stream<int> streamUnreadMessageCount(String exchangeId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return Stream.value(0);
    return _db
        .collection('messages')
        .where('exchangeId', isEqualTo: exchangeId)
        .where('receiverId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length)
        .handleError((_) => 0);
  }

  static Future<void> markMessagesRead(String exchangeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      final unread = await _db
          .collection('messages')
          .where('exchangeId', isEqualTo: exchangeId)
          .where('receiverId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();
      if (unread.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('markMessagesRead error: $e');
    }
  }

  static Future<void> sendMessage({
    required String exchangeId,
    required String text,
    String receiverId = '',
    String receiverName = '',
  }) async {
    if (text.trim().isEmpty) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) throw Exception('Not logged in');
    await _db.collection('messages').add({
      'exchangeId': exchangeId,
      'senderId': uid,
      'senderName': _username,
      'receiverId': receiverId,
      'text': text.trim(),
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (receiverId.isNotEmpty) {
      await _createNotification(
        userId: receiverId,
        title: '💬 New Message from $_username',
        body: text.trim().length > 60 ? '${text.trim().substring(0, 60)}…' : text.trim(),
        type: 'new_message',
        relatedId: exchangeId,
      );
    }
  }

  static Stream<QuerySnapshot> streamNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return const Stream.empty();
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .handleError((e) => debugPrint('streamNotifications error: $e'));
  }

  static Future<void> markAllRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    final unread = await _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;
    const chunkSize = 500;
    for (var i = 0; i < unread.docs.length; i += chunkSize) {
      final end = (i + chunkSize < unread.docs.length) ? i + chunkSize : unread.docs.length;
      final batch = _db.batch();
      for (final doc in unread.docs.sublist(i, end)) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }

  static Future<void> markRead(String docId) async {
    await _db.collection('notifications').doc(docId).update({'isRead': true});
  }

  static Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    if (userId.isEmpty) return;
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId ?? '',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('createNotification error: $e');
    }
  }

  static Future<Map<String, int>> getDashboardStats() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return {'toys': 0, 'exchanges': 0, 'requests': 0};
    try {
      final results = await Future.wait([
        _db.collection('toys').where('ownerId', isEqualTo: uid).count().get(),
        _db.collection('exchanges')
            .where('ownerId', isEqualTo: uid)
            .where('status', whereIn: ['active', 'pending_receipt'])
            .count().get(),
        _db.collection('requests')
            .where('ownerId', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .count().get(),
      ]);
      return {
        'toys': results[0].count ?? 0,
        'exchanges': results[1].count ?? 0,
        'requests': results[2].count ?? 0,
      };
    } catch (e) {
      debugPrint('getDashboardStats error: $e');
      return {'toys': 0, 'exchanges': 0, 'requests': 0};
    }
  }

  static Future<Map<String, int>> getProfileStats() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return {'toys': 0, 'exchanges': 0, 'feedback': 0};
    try {
      final results = await Future.wait([
        _db.collection('toys').where('ownerId', isEqualTo: uid).count().get(),
        _db.collection('exchanges').where('ownerId', isEqualTo: uid).where('status', isEqualTo: 'completed').count().get(),
        _db.collection('feedback').where('toUserId', isEqualTo: uid).where('isPositive', isEqualTo: true).count().get(),
      ]);
      return {
        'toys': results[0].count ?? 0,
        'exchanges': results[1].count ?? 0,
        'feedback': results[2].count ?? 0,
      };
    } catch (e) {
      debugPrint('getProfileStats error: $e');
      return {'toys': 0, 'exchanges': 0, 'feedback': 0};
    }
  }

  static Future<void> blacklistUser(String targetUid, String targetName) async {
    if (targetUid.isEmpty) return;
    await _db.collection('blacklist').doc('${_uid}_$targetUid').set({
      'userId': _uid,
      'blockedUserId': targetUid,
      'blockedUsername': targetName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeFromBlacklist(String targetUid) async {
    await _db.collection('blacklist').doc('${_uid}_$targetUid').delete();
  }

  static Future<List<DocumentSnapshot>> getBlacklistedUsers() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return [];
    try {
      final snap = await _db
          .collection('blacklist')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs;
    } catch (e) {
      debugPrint('getBlacklistedUsers error: $e');
      return [];
    }
  }

  static Future<void> giveFeedback({
    required String targetUserId,
    required bool isPositive,
    required String comment,
    required String exchangeId,
    String toyName = '',
    int rating = 5,
  }) async {
    if (targetUserId.isEmpty) return;
    _ratingCache.remove(targetUserId);
    _ratingCacheTime.remove(targetUserId);
    await _db.collection('feedback').add({
      'fromUserId': _uid,
      'fromUserName': _username,
      'toUserId': targetUserId,
      'exchangeId': exchangeId,
      'toyName': toyName,
      'isPositive': isPositive,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> streamToyHistory(String toyId) {
    return _db
        .collection('exchanges')
        .where('toyId', isEqualTo: toyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) => debugPrint('streamToyHistory error: $e'));
  }

  static Stream<QuerySnapshot> streamDisputes() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return const Stream.empty();
    return _db
        .collection('disputes')
        .where('reporterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) => debugPrint('streamDisputes error: $e'));
  }
}
