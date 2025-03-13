import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sending_base_test/feature/storage/controller/storage_controller.dart';
import 'package:sending_base_test/function/had_writing.dart';
import 'package:sending_base_test/feature/pdf/pdf_creater.dart';
import 'package:sending_base_test/routing/router_utils.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:ui' as ui;
import 'package:pdf/widgets.dart' as pw;

class TextSavePdf extends HookConsumerWidget {
  const TextSavePdf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ValueNotifier<String> startDate = useState('yyyy/mm/dd');
    final ValueNotifier<String> endDate = useState('yyyy/mm/dd');
    final points = useState<List<Offset?>>([]);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('PDF出力'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('利用者名'),
                            ),
                          ),
                          const Text(
                            '山田太郎',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.black, height: 1),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('運動器機能向上訓練計画'),
                            ),
                          ),
                          const Text(
                            '期間：',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                selectDate(context, true, startDate, endDate);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  startDate.value,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                          const Text('～'),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                selectDate(context, false, startDate, endDate);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  endDate.value,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.black, height: 1),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('生年月日'),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                points.value = [
                                  ...points.value,
                                  details.localPosition,
                                ];
                              },
                              onPanEnd: (details) {
                                points.value = [
                                  ...points.value,
                                  null,
                                ]; // 線を区切るため
                              },
                              child: CustomPaint(
                                painter: HandwritingPainter(points.value),
                                size: Size(double.infinity, 150),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    () => generatePDF(
                      ref,
                      context,
                      startDate: startDate.value,
                      endDate: endDate.value,
                    ),
                child: const Text('テキストPDF出力'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _saveAsPDF(points.value, ref, context);
                },
                child: const Text('手書きPDF出力'),
              ),
              ElevatedButton(
                onPressed: () {
                  //手書きPDF出力画面へ
                  context.goNamed(AppRoute.writeSavePdf.name);
                },
                child: const Text('PDF上書きPDF出力画面へ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 手書きを画像化し、PDF に変換
  Future<void> _saveAsPDF(
    List<Offset?> points,
    WidgetRef ref,
    BuildContext context,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = HandwritingPainter(points);
    painter.paint(canvas, Size(600, 800));
    final picture = recorder.endRecording();
    final img = await picture.toImage(600, 800);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    final pdf = pw.Document();
    final image = pw.MemoryImage(pngBytes);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(child: pw.Image(image));
        },
      ),
    );

    final pdfInBytes = await pdf.save();

    //PDFのURLを取得してstorageにアップロード
    final pdfUrl = await ref
        .read(storageControllerProvider.notifier)
        .pdfUploadGetUrl(pdfInBytes: pdfInBytes);

    //ダウンロードリンクを開く
    if (context.mounted) {
      await launchUrlString(pdfUrl);
    }
  }

  /// カレンダーで日付を選択し、Text に表示する関数
  Future<void> selectDate(
    BuildContext context,
    bool isStartDate,
    ValueNotifier<String> startDate,
    ValueNotifier<String> endDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('ja'),
      initialDatePickerMode: DatePickerMode.day,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final formattedDate = DateFormat('yyyy/MM/dd').format(picked);
      if (isStartDate) {
        startDate.value = formattedDate;
      } else {
        endDate.value = formattedDate;
      }
    }
  }

  /// PDFを生成し、プレビューする関数
  Future<void> generatePDF(
    WidgetRef ref,
    BuildContext context, {
    required String startDate,
    required String endDate,
  }) async {
    final pdf = await PdfCreator.createPdf(
      context: context,
      startDate: startDate,
      endDate: endDate,
    );

    final pdfInBytes = await pdf.save();

    //PDFのURLを取得してstorageにアップロード
    final pdfUrl = await ref
        .read(storageControllerProvider.notifier)
        .pdfUploadGetUrl(pdfInBytes: pdfInBytes);

    //ダウンロードリンクを開く
    if (context.mounted) {
      Navigator.pop(context);
      await launchUrlString(pdfUrl);
    }
  }
}
