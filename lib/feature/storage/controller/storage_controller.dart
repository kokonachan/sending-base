import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sending_base_test/feature/storage/repo/storage_repo.dart';

part 'storage_controller.g.dart';

@riverpod
class StorageController extends _$StorageController {
  @override
  AsyncValue build() {
    return const AsyncData(null);
  }

  //storageに契約書のPDFをアップロード（URL取得なし）
  //ex.既存の契約書PDFをアップロードする時に使用する
  Future<String> pdfUploadGetUrl({required Uint8List pdfInBytes}) async {
    state = const AsyncLoading();
    final String pdfUrl = await ref
        .read(storageRepoProvider.notifier)
        .pdfUploadGetUrl(pdfInBytes: pdfInBytes);
    state = const AsyncData(null);
    return pdfUrl;
  }
}
