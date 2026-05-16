import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String url;
  final String judul;

  const PdfViewerScreen({
    super.key,
    required this.url,
    required this.judul,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          judul,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SfPdfViewer.network(
        url,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat berkas PDF: ${details.description}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }
}
