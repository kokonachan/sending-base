import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:sending_base_test/feature/storage/controller/storage_controller.dart';

import 'package:sending_base_test/function/had_writing.dart';
import 'package:url_launcher/url_launcher_string.dart';

class WriteSavePaf extends HookConsumerWidget {
  const WriteSavePaf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfPath = useState<String?>(null);
    final isLoading = useState<bool>(true);
    final points = useState<List<Offset?>>([]); // 手書きの座標リスト

    useEffect(() {
      _downloadPdf().then((path) {
        pdfPath.value = path;
        isLoading.value = false;
      });
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(title: const Text('PDF Paint')),
      body:
          isLoading.value
              ? const Center(child: CircularProgressIndicator()) // ローディング中
              : Stack(
                children: [
                  PDFView(filePath: pdfPath.value!, fitPolicy: FitPolicy.BOTH),
                  Positioned.fill(
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        points.value = [...points.value, details.localPosition];
                      },
                      onPanEnd: (details) {
                        points.value = [...points.value, null]; // 線を区切るため
                      },
                      child: CustomPaint(
                        painter: HandwritingPainter(points.value),
                        size: Size.infinite,
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _saveAsPDF(points.value, pdfPath.value!, ref, context);
        },
        child: const Icon(Icons.save),
      ),
    );
  }

  /// **Firebase Storage の PDF をローカルにダウンロード**
  Future<String> _downloadPdf() async {
    final url =
        'https://firebasestorage.googleapis.com/v0/b/sending-base-test.firebasestorage.app/o/%E3%82%B5%E3%83%BC%E3%83%92%E3%82%99%E3%82%B9%E6%8F%90%E4%BE%9B%E8%A8%98%E9%8C%B2.pdf?alt=media&token=fd6e1634-b29a-4b12-9996-bfca89c250da';

    final response = await http.get(Uri.parse(url));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/temp.pdf');

    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }

  Future<void> _saveAsPDF(
    List<Offset?> points,
    String filePath, // 既存のPDFのパス
    WidgetRef ref,
    BuildContext context,
  ) async {
    // **手書きの画像を作成**
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = HandwritingPainter(points);
    painter.paint(canvas, Size(600, 800));
    final picture = recorder.endRecording();
    final img = await picture.toImage(600, 800);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    // **既存のPDFを取得**
    final File pdfFile = File(filePath);
    final Uint8List existingPdfBytes = await pdfFile.readAsBytes();

    // **新しいPDFを作成**
    final pdf = pw.Document();

    // **既存のPDFを読み込み**
    final pdfImage = pw.MemoryImage(existingPdfBytes);
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(pdfImage), // 既存のPDFを画像として配置
          );
        },
      ),
    );

    // **手書き画像を追加**
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(pw.MemoryImage(pngBytes)), // 手書き画像を追加
          );
        },
      ),
    );

    // **新しいPDFを保存**
    final pdfBytes = await pdf.save();
    //PDFのURLを取得してstorageにアップロード
    final pdfUrl = await ref
        .read(storageControllerProvider.notifier)
        .pdfUploadGetUrl(pdfInBytes: pdfBytes);

    //ダウンロードリンクを開く
    if (context.mounted) {
      Navigator.pop(context);
      await launchUrlString(pdfUrl);
    }
  }
}
