import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

//PDF作成クラス
class PdfCreator {
  static pw.Font? regularFont;
  static pw.Font? boldFont;

  // Googleフォントを取得して埋め込むことも可能
  static Future<void> loadCustomFont() async {
    // レギュラーフォントの読み込み
    final regularFontData = await rootBundle.load(
      'assets/fonts/Noto_Sans_JP/NotoSansJP-Regular.ttf',
    );
    regularFont = pw.Font.ttf(regularFontData);

    // ボールドフォントの読み込み
    final boldFontData = await rootBundle.load(
      'assets/fonts/Noto_Sans_JP/NotoSansJP-Bold.ttf',
    );
    boldFont = pw.Font.ttf(boldFontData);
  }

  static Future<pw.Document> createPdf({
    required BuildContext context,
    required String startDate,
    required String endDate,
  }) async {
    final pdf = pw.Document();
    await loadCustomFont(); // フォントの読み込みを待機

    //会社情報
    final companyInfo = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
          ),
          padding: const pw.EdgeInsets.all(10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    color: PdfColors.grey200,
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text('利用者名', style: pw.TextStyle(fontSize: 14)),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '山田太郎',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.black),
              pw.Row(
                children: [
                  pw.Container(
                    color: PdfColors.grey200,
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text(
                      '運動器機能向上訓練計画',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '期間：',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont,
                    ),
                  ),
                  pw.SizedBox(width: 5),
                  pw.Text(startDate, style: pw.TextStyle(fontSize: 14)),
                  pw.Text(' ～ ', style: pw.TextStyle(fontSize: 14)),
                  pw.Text(endDate, style: pw.TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    // `MultiPage`を使用してPDFに内容を追加
    pdf.addPage(
      pw.MultiPage(
        //フォントサイズを指定
        theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(font: regularFont)),
        build: (pw.Context context) {
          return [companyInfo];
        },
        // 必要に応じて他の`MultiPage`の設定をここに追加
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Column(children: [pw.Text('${context.pageNumber}')]),
          );
        },
      ),
    );

    // PDFに内容を追加

    return pdf;
  }
}
