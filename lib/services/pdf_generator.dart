
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';

// Extensión para TimeOfDay que permite formatear sin BuildContext
extension TimeOfDayExtension on TimeOfDay {
  String formatTime(BuildContext? context) {
    if (context != null) {
      return MaterialLocalizations.of(context).formatTimeOfDay(this);
    }
    // Formato manual cuando no hay context disponible
    final hours = hour.toString().padLeft(2, '0');
    final minutes = minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

class PDFGenerator {
  static Future<Uint8List> generateOrdenTrabajo(OrdenTrabajo orden) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter, // Cambiado a tamaño carta
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              _buildHeader('ORDEN DE TRABAJO', boldFont, font),
              pw.SizedBox(height: 20),

              // Información de la orden
              _buildOrderInfo(orden, font, boldFont),
              pw.SizedBox(height: 20),

              // Información del cliente
              _buildClientInfo(orden.cliente, font, boldFont),
              pw.SizedBox(height: 20),

              // Tabla de trabajos
              _buildWorkTable(orden.trabajos, font, boldFont),
              pw.SizedBox(height: 20),

              // Resumen financiero
              _buildFinancialSummary(orden, font, boldFont),
              pw.SizedBox(height: 20),

              // Notas
              if (orden.notas != null && orden.notas!.isNotEmpty)
                _buildNotes(orden.notas!, font, boldFont),

              pw.Spacer(),

              // Pie de página
              _buildFooter(font),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateProforma(OrdenTrabajo orden) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter, // Cambiado a tamaño carta
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              _buildHeader('PROFORMA', boldFont, font),
              pw.SizedBox(height: 20),

              // Información de la proforma
              _buildProformaInfo(orden, font, boldFont),
              pw.SizedBox(height: 20),

              // Información del cliente
              _buildClientInfo(orden.cliente, font, boldFont),
              pw.SizedBox(height: 20),

              // Tabla de trabajos
              _buildWorkTable(orden.trabajos, font, boldFont),
              pw.SizedBox(height: 20),

              // Resumen financiero
              _buildFinancialSummary(orden, font, boldFont),
              pw.SizedBox(height: 20),

              // Términos y condiciones
              _buildTermsAndConditions(font, boldFont),

              pw.Spacer(),

              // Pie de página
              _buildFooter(font),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateNotaVenta(OrdenTrabajo orden) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter, // Cambiado a tamaño carta
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              _buildHeader('NOTA DE VENTA', boldFont, font),
              pw.SizedBox(height: 20),

              // Información de la nota de venta
              _buildNotaVentaInfo(orden, font, boldFont),
              pw.SizedBox(height: 20),

              // Información del cliente
              _buildClientInfo(orden.cliente, font, boldFont),
              pw.SizedBox(height: 20),

              // Tabla de trabajos
              _buildWorkTable(orden.trabajos, font, boldFont),
              pw.SizedBox(height: 20),

              // Resumen financiero con pagos
              _buildFinancialSummaryWithPayments(orden, font, boldFont),
              pw.SizedBox(height: 20),

              // Información de entrega
              _buildDeliveryInfo(orden, font, boldFont),

              pw.Spacer(),

              // Pie de página
              _buildFooter(font),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
      String title, pw.Font boldFont, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green300,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'COTIZADOR PRO',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 24,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 18,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildOrderInfo(
      OrdenTrabajo orden, pw.Font font, pw.Font boldFont) {
    final dateFormat = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES');
    final timeFormat = DateFormat('HH:mm', 'es_ES');

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Orden N°:',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text('#${orden.id.substring(0, 8)}',
                    style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text('Estado:',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(orden.estado.toUpperCase(),
                    style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Fecha de Creación:',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(dateFormat.format(orden.creadoEn),
                    style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text('Fecha de Entrega:',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(
                    '${dateFormat.format(orden.fechaEntrega)} - ${_formatTimeOfDay(orden.horaEntrega)}',
                    style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProformaInfo(
      OrdenTrabajo orden, pw.Font font, pw.Font boldFont) {
    final dateFormat = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES');

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Proforma N°:',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text('PRO-${orden.id.substring(0, 8)}',
                    style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text('Validez:',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text('30 días',
                    style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Fecha:',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(dateFormat.format(DateTime.now()),
                    style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text('Tiempo de Entrega:',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(
                    '${orden.fechaEntrega.difference(DateTime.now()).inDays} días',
                    style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNotaVentaInfo(
      OrdenTrabajo orden, pw.Font font, pw.Font boldFont) {
    final dateFormat = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES');

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Nota de Venta N°:',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text('NV-${orden.id.substring(0, 8)}',
                    style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text('Estado:',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(orden.estado.toUpperCase(),
                    style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Fecha de Venta:',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(dateFormat.format(DateTime.now()),
                    style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text('Método de Pago:',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(orden.adelanto > 0 ? 'Adelanto + Saldo' : 'Contado',
                    style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildClientInfo(
      Cliente cliente, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('INFORMACIÓN DEL CLIENTE',
              style: pw.TextStyle(font: boldFont, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Nombre:',
                        style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    pw.Text(cliente.nombre,
                        style: pw.TextStyle(font: font, fontSize: 12)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Contacto:',
                        style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    pw.Text(cliente.contacto,
                        style: pw.TextStyle(font: font, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildWorkTable(
      List<OrdenTrabajoTrabajo> trabajos, pw.Font font, pw.Font boldFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Descripción', boldFont, isHeader: true),
            _buildTableCell('Ancho', boldFont, isHeader: true),
            _buildTableCell('Alto', boldFont, isHeader: true),
            _buildTableCell('Cant.', boldFont, isHeader: true),
            _buildTableCell('Precio/m²', boldFont, isHeader: true),
            _buildTableCell('Total', boldFont, isHeader: true),
          ],
        ),
        // Trabajos
        ...trabajos.map((trabajo) => pw.TableRow(
              children: [
                _buildTableCell(trabajo.trabajo.nombre, font),
                _buildTableCell('${trabajo.ancho}m', font),
                _buildTableCell('${trabajo.alto}m', font),
                _buildTableCell('${trabajo.cantidad}', font),
                _buildTableCell(
                    'Bs ${trabajo.trabajo.precioM2.toStringAsFixed(2)}', font),
                _buildTableCell(
                    'Bs ${trabajo.precioFinal.toStringAsFixed(2)}', font),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, pw.Font font,
      {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildFinancialSummary(
      OrdenTrabajo orden, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('RESUMEN FINANCIERO',
              style: pw.TextStyle(font: boldFont, fontSize: 14)),
          pw.SizedBox(height: 8),
          _buildFinancialRow('Subtotal:',
              'Bs ${orden.totalBruto.toStringAsFixed(2)}', font, boldFont),
          if (orden.rebaja > 0)
            _buildFinancialRow('Rebaja:',
                '-Bs ${orden.rebaja.toStringAsFixed(2)}', font, boldFont),
          pw.Divider(color: PdfColors.grey400),
          _buildFinancialRow('TOTAL:', 'Bs ${orden.total.toStringAsFixed(2)}',
              font, boldFont,
              isTotal: true),
        ],
      ),
    );
  }

  static pw.Widget _buildFinancialSummaryWithPayments(
      OrdenTrabajo orden, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('RESUMEN FINANCIERO',
              style: pw.TextStyle(font: boldFont, fontSize: 14)),
          pw.SizedBox(height: 8),
          _buildFinancialRow('Subtotal:',
              'Bs ${orden.totalBruto.toStringAsFixed(2)}', font, boldFont),
          if (orden.rebaja > 0)
            _buildFinancialRow('Rebaja:',
                '-Bs ${orden.rebaja.toStringAsFixed(2)}', font, boldFont),
          pw.Divider(color: PdfColors.grey400),
          _buildFinancialRow('TOTAL:', 'Bs ${orden.total.toStringAsFixed(2)}',
              font, boldFont,
              isTotal: true),
          if (orden.adelanto > 0) ...[
            pw.SizedBox(height: 8),
            _buildFinancialRow('Adelanto:',
                'Bs ${orden.adelanto.toStringAsFixed(2)}', font, boldFont),
            _buildFinancialRow('Saldo Pendiente:',
                'Bs ${orden.saldo.toStringAsFixed(2)}', font, boldFont),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildFinancialRow(
      String label, String value, pw.Font font, pw.Font boldFont,
      {bool isTotal = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                font: isTotal ? boldFont : font,
                fontSize: isTotal ? 14 : 12)),
        pw.Text(value,
            style: pw.TextStyle(
                font: isTotal ? boldFont : font,
                fontSize: isTotal ? 14 : 12)),
      ],
    );
  }

  static pw.Widget _buildNotes(String notes, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('NOTAS', style: pw.TextStyle(font: boldFont, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Text(notes, style: pw.TextStyle(font: font, fontSize: 12)),
        ],
      ),
    );
  }

  static pw.Widget _buildTermsAndConditions(pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('TÉRMINOS Y CONDICIONES',
              style: pw.TextStyle(font: boldFont, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Text('• Esta proforma tiene validez de 30 días.',
              style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text('• Los precios incluyen diseño y material.',
              style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text('• Se requiere 50% de adelanto para iniciar el trabajo.',
              style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text('• El tiempo de entrega es estimado y puede variar.',
              style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text('• No incluye instalación salvo especificación contraria.',
              style: pw.TextStyle(font: font, fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildDeliveryInfo(
      OrdenTrabajo orden, pw.Font font, pw.Font boldFont) {
    final dateFormat = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES');

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('INFORMACIÓN DE ENTREGA',
              style: pw.TextStyle(font: boldFont, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Fecha de Entrega:',
                        style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    pw.Text(dateFormat.format(orden.fechaEntrega),
                        style: pw.TextStyle(font: font, fontSize: 12)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Hora de Entrega:',
                        style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    pw.Text(_formatTimeOfDay(orden.horaEntrega),
                        style: pw.TextStyle(font: font, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('COTIZADOR PRO - Sistema de Gestión de Gigantografías',
              style: pw.TextStyle(font: font, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(
              'Generado el ${DateFormat('d/M/yyyy HH:mm', 'es_ES').format(DateTime.now())}',
              style:
                  pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  // Función auxiliar para formatear TimeOfDay
  static String _formatTimeOfDay(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
