// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== DONATIONS ====================
  
  /// Create a new donation
  Future<DocumentReference> createDonation(Map<String, dynamic> donationData) async {
    donationData['createdAt'] = FieldValue.serverTimestamp();
    donationData['updatedAt'] = FieldValue.serverTimestamp();
    donationData['donorId'] = _auth.currentUser?.uid;
    donationData['donorEmail'] = _auth.currentUser?.email;
    donationData['status'] = donationData['status'] ?? 'Logged';
    
    return await _firestore.collection('donations').add(donationData);
  }

  /// Get all donations for current donor
  Stream<QuerySnapshot> getDonorDonations() {
    return _firestore
        .collection('donations')
        .where('donorId', isEqualTo: _auth.currentUser?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get donation by ID
  Future<DocumentSnapshot> getDonation(String donationId) async {
    return await _firestore.collection('donations').doc(donationId).get();
  }

  /// Update donation
  Future<void> updateDonation(String donationId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('donations').doc(donationId).update(data);
  }

  /// Delete donation
  Future<void> deleteDonation(String donationId) async {
    await _firestore.collection('donations').doc(donationId).delete();
  }

  /// Get all available donations (for charities)
  Stream<QuerySnapshot> getAvailableDonations() {
    return _firestore
        .collection('donations')
        .where('status', whereIn: ['Logged', 'Available'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Update donation status
  Future<void> updateDonationStatus(String donationId, String status) async {
    await _firestore.collection('donations').doc(donationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== CHARITIES ====================
  
  /// Create charity profile
  Future<DocumentReference> createCharity(Map<String, dynamic> charityData) async {
    charityData['createdAt'] = FieldValue.serverTimestamp();
    charityData['updatedAt'] = FieldValue.serverTimestamp();
    charityData['userId'] = _auth.currentUser?.uid;
    charityData['email'] = _auth.currentUser?.email;
    charityData['receivedToday'] = 0;
    charityData['totalReceived'] = 0;
    charityData['isActive'] = true;
    
    return await _firestore.collection('charities').add(charityData);
  }

  /// Get charity by user ID
  Future<DocumentSnapshot?> getCharityByUserId() async {
    final snapshot = await _firestore
        .collection('charities')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first;
  }

  /// Get all active charities
  Stream<QuerySnapshot> getActiveCharities() {
    return _firestore
        .collection('charities')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  /// Update charity profile
  Future<void> updateCharity(String charityId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('charities').doc(charityId).update(data);
  }

  /// Increment charity received count
  Future<void> incrementCharityReceived(String charityId) async {
    await _firestore.collection('charities').doc(charityId).update({
      'receivedToday': FieldValue.increment(1),
      'totalReceived': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== USERS ====================
  
  /// Get user profile
  Future<DocumentSnapshot> getUserProfile() async {
    final doc = await _firestore.collection('users').doc(_auth.currentUser?.uid).get();
    if (!doc.exists) {
      // Create user profile if it doesn't exist
      await _firestore.collection('users').doc(_auth.currentUser?.uid).set({
        'email': _auth.currentUser?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'user',
      });
      return await _firestore.collection('users').doc(_auth.currentUser?.uid).get();
    }
    return doc;
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(_auth.currentUser?.uid).update(data);
  }

  /// Update user role
  Future<void> updateUserRole(String role) async {
    await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== MATCHES ====================
  
  /// Create a match record
  Future<DocumentReference> createMatch(Map<String, dynamic> matchData) async {
    matchData['createdAt'] = FieldValue.serverTimestamp();
    matchData['matchedBy'] = _auth.currentUser?.uid;
    
    return await _firestore.collection('matches').add(matchData);
  }

  /// Get matches for a donation
  Stream<QuerySnapshot> getMatchesForDonation(String donationId) {
    return _firestore
        .collection('matches')
        .where('donationId', isEqualTo: donationId)
        .snapshots();
  }

  /// Get matches for a charity
  Stream<QuerySnapshot> getMatchesForCharity(String charityId) {
    return _firestore
        .collection('matches')
        .where('charityId', isEqualTo: charityId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== ANALYTICS ====================
  
  /// Get donor statistics
  Future<Map<String, dynamic>> getDonorStats() async {
    final donations = await _firestore
        .collection('donations')
        .where('donorId', isEqualTo: _auth.currentUser?.uid)
        .get();
    
    double totalKg = 0;
    int completedDonations = 0;
    
    for (var doc in donations.docs) {
      final data = doc.data();
      if (data['quantity'] != null) {
        final qtyStr = data['quantity'].toString().replaceAll(' kg', '');
        totalKg += double.tryParse(qtyStr) ?? 0;
      }
      if (data['status'] == 'Completed' || data['status'] == 'Delivered') {
        completedDonations++;
      }
    }
    
    return {
      'totalDonations': donations.docs.length,
      'totalKg': totalKg,
      'completedDonations': completedDonations,
    };
  }

  /// Get charity statistics
  Future<Map<String, dynamic>> getCharityStats() async {
    final charityDoc = await getCharityByUserId();
    if (charityDoc == null) return {};
    
    final data = charityDoc.data() as Map<String, dynamic>;
    return {
      'receivedToday': data['receivedToday'] ?? 0,
      'totalReceived': data['totalReceived'] ?? 0,
      'hasColdStorage': data['hasColdStorage'] ?? false,
      'capacityRemaining': data['capacityRemaining'] ?? 0,
    };
  }
}
