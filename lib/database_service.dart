import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  // Initialize Firestore instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches product details from the 'products' collection using the barcode as the ID.
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      // Access the document in the 'products' collection
      DocumentSnapshot doc = await _db.collection('products').doc(barcode).get();

      if (doc.exists) {
        // Return the data as a Map
        return doc.data() as Map<String, dynamic>;
      } else {
        print("Product with barcode $barcode not found in Firestore.");
        return null;
      }
    } catch (e) {
      print("Error fetching product: $e");
      return null;
    }
  }
}