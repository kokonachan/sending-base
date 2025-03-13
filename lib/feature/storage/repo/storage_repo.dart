import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'storage_repo.g.dart';

@riverpod
class StorageRepo extends _$StorageRepo {
  @override
  Reference build() {
    return FirebaseStorage.instance.ref();
  }

  //storageに契約書PDFアップロードして、URLを取得
  Future<String> pdfUploadGetUrl({required Uint8List pdfInBytes}) async {
    final pdfId = const Uuid().v4();
    final storageRef = state.child('$pdfId.pdf');

    //メタデータの設定
    final metadata = SettableMetadata(
      contentType: 'application/pdf',
      contentDisposition: 'inline', // ここでContent-Dispositionを設定
    );

    // PDFファイルをアップロード
    await storageRef.putData(pdfInBytes, metadata);
    final downloadUrl = await storageRef.getDownloadURL();
    return downloadUrl;
  }
}
