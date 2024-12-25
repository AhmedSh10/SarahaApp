import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClient {
  static final client = Supabase.instance.client;
  
  static String? get currentUserId => client.auth.currentUser?.id;
  
  static bool get isAuthenticated => currentUserId != null;
  
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}