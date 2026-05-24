import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Picks a receipt image and stores it in the private `receipts` bucket under
/// `<userId>/<expenseId>.<ext>`. Display uses short-lived signed URLs.
class ReceiptService {
  ReceiptService(this._client, [ImagePicker? picker])
      : _picker = picker ?? ImagePicker();

  final SupabaseClient _client;
  final ImagePicker _picker;

  static const bucket = 'receipts';

  /// Returns the storage path, or null if the user cancelled.
  Future<String?> pickAndUpload({
    required String userId,
    required String expenseId,
    required ImageSource source,
  }) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';
    final path = '$userId/$expenseId.$ext';
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
          ),
        );
    return path;
  }

  Future<String> signedUrl(String path) =>
      _client.storage.from(bucket).createSignedUrl(path, 3600);

  Future<void> remove(String path) =>
      _client.storage.from(bucket).remove([path]);
}
