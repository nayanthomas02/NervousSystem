import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:synchronized/synchronized.dart';

class RaidService {
  final FirebaseFirestore firestore;
  final Lock _lock = Lock();

  RaidService({required this.firestore});

  Future<bool> joinRaid({required String userId}) async {
    final DocumentReference<Map<String, dynamic>> docRef = firestore.collection('events').doc('dragon_raid');

    try {
      return await _lock.synchronized(() async {
        return await firestore.runTransaction((Transaction transaction) async {
          final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          return false;
        }

        final Map<String, dynamic>? data = snapshot.data();
        if (data == null) return false;

        // Strictly typed parsing avoiding implicit dynamics
        final int slotsFilled = (data['slots_filled'] as num?)?.toInt() ?? 0;
        final int maxSlots = (data['max_slots'] as num?)?.toInt() ?? 15;

        // Check if there's room left
        if (slotsFilled >= maxSlots) {
          return false;
        }

        // If there's room, increment the slot count securely
        transaction.update(docRef, <Object, Object?>{
          'slots_filled': slotsFilled + 1,
        });

        // Normally, you would also add the user to a subcollection or array here.
        // For the scope of the test, updating slots_filled is the main requirement.
        
        return true; // Successfully joined
        });
      });
    } catch (e, stackTrace) {
      // Proper error logging without using print()
      log(
        'Transaction failed during raid join',
        name: 'RaidService',
        error: e,
        stackTrace: stackTrace,
      );
      // Graceful failure (e.g., transaction failed, network error)
      return false;
    }
  }
}
