import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../models/trip.dart';
import '../models/cistern.dart';

class PdfService {
  static Future<void> generateTripPdf(Trip trip, List<Cistern> cisterns) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('RSW Fleet Manager - Trip Report',
              style:
              pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('Trip Code: ${trip.tripCode}'),
          pw.Text('Vessel: ${trip.vessel}'),
          pw.Text('Date: ${trip.tripDate}'),
          pw.SizedBox(height: 20),

          pw.Text('Cisterns Summary',
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            headers: [
              'Cistern ID',
              'RSW Tank',
              'Buyer',
              'Weight In (kg)',
              'Weight Out (kg)',
              'Net Weight (kg)'
            ],
            data: cisterns
                .map((c) => [
              c.id,
              c.tank,
              c.buyer,
              c.weightIn,
              c.weightOut,
              c.netWeight,
            ])
                .toList(),
            headerDecoration:
            const pw.BoxDecoration(color: PdfColors.lightBlue),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
          ),

          pw.SizedBox(height: 25),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total Net Weight: ${_computeTotal(cisterns)} kg',
              style:
              pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static double _computeTotal(List<Cistern> cisterns) {
    return cisterns.fold<double>(
        0, (sum, c) => sum + (double.tryParse(c.netWeight) ?? 0));
  }
}
