import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jouls_labs_demo_app/sec/feature/home/controller/home_view_controller.dart';
import 'package:jouls_labs_demo_app/sec/feature/utils/app_consts.dart';
import 'package:jouls_labs_demo_app/sec/routes/app_routes.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:image_to_byte/image_to_byte.dart';

class PdfViewer extends StatefulWidget {
  PdfViewer({this.file});

  final File? file;

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  final controller = Get.find<HomeViewController>();

  bool isFixed = false;
  File? imageFile = File('');
  late File file;

  int currentPage = 0;
  createFile() async {
    var dir = await getApplicationDocumentsDirectory();
    file = File('${dir.path}/doc.pdf');
    file.writeAsBytes(file.readAsBytesSync());
    setState(() {});
  }

  @override
  void initState() {
    //createFile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PdfWidget(
      file: widget.file!,
      offset: controller.offset ?? Offset(0.0, 0.0),
      isFixed: isFixed,
      onDragEnd: (offset) {
        controller.offset = offset;
        setState(() {});
      },
    );
  }
}

class PdfWidget extends StatefulWidget {
  PdfWidget({
    Key? key,
    this.signatureBytes,
    required this.file,
    required this.offset,
    required this.onDragEnd,
    required this.isFixed,
  }) : super(key: key);

  Uint8List? signatureBytes;
  final File file;
  final Offset offset;
  final Function(Offset) onDragEnd;
  bool isFixed = false;

  @override
  State<PdfWidget> createState() => _PdfWidgetState();
}

class _PdfWidgetState extends State<PdfWidget> {
  final controller = Get.find<HomeViewController>();
  int currentPage = 0;

  /// Image convert into a Uint8List file.
  void _imageToByte() async {
    Uint8List iByte = await imageToByte(Appconst.dragImageLink);
    setState(() => widget.signatureBytes = iByte);
  }

  Offset convertOffsetToPdfPage(
    Offset widgetOffset,
    double height,
    double width,
    Size pdfPageSize,
  ) {
    // Get the screen dimensions of the device.
    double screenWidth = width;
    double screenHeight = height;

    // Map the widget's offset to the screen's top-left corner (0, 0), assuming
// that the top-left corner of the device's screen corresponds to (0, 0)
// on the top-left corner of the page in the PDF.
    double xRatio = widgetOffset.dx / screenWidth;
    double yRatio = widgetOffset.dy / screenHeight;
// Recalculate the widget's offset based on the PDF page size.

    double xOffset = xRatio * pdfPageSize.width;
    double yOffset = yRatio * pdfPageSize.height;
    // Add a margin for error to the calculated offsets for accuracy.
    xOffset += pdfPageSize.width * 0.05; // Added for margin of error
    yOffset += pdfPageSize.height * 0.08; // Added for margin of error

// As a result, the widget's offset is adjusted based on the device's screen size.
    return Offset(xOffset, yOffset);
  }

  @override
  Widget build(BuildContext context) {
    _imageToByte();

    return Stack(
      children: [
        SfPdfViewer.file(
          widget.file,
          onPageChanged: (page) {
            currentPage = page.newPageNumber;
            setState(() {});
          },
        ),
        // SizedBox(height: 5),

        Visibility(
          visible: controller.isEditable.value,
          child: Positioned(
            top: widget.offset.dy,
            left: widget.offset.dx,
            child: Draggable(
              childWhenDragging: Container(),
              onDragUpdate: (details) {
                setState(() {
                  controller.isSohowPosition.value = true;
                  controller.xPosition.value = details.localPosition.dx;
                  controller.yPosition.value = details.localPosition.dy;
                });
              },
              feedback: Material(
                child: Image.network(
                  Appconst.dragImageLink,
                  height: 100,
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
              onDragEnd: (details) {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                var offset = renderBox.globalToLocal(
                  details.offset,
                );
                controller.isSohowPosition.value = false;
                widget.onDragEnd(offset);
                // print("Before Save file x =${offset.dx}");
                // print("Before Save file y =${offset.dy}");
                setState(() {});
                print(controller.isSohowPosition.value);
              },
              child: Column(
                children: [
                  Image.network(
                    Appconst.dragImageLink,
                    height: 100,
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                  InkWell(
                    onTap: () async {
                      final PdfDocument document = PdfDocument(
                          inputBytes: widget.file.readAsBytesSync());

                      final PdfBitmap image = PdfBitmap(widget.signatureBytes!);
                      var convertedOffset = convertOffsetToPdfPage(
                          widget.offset,
                          document.pages.count == 1
                              ? MediaQuery.of(context).size.height - 120
                              : MediaQuery.of(context).size.height - 150,
                          MediaQuery.of(context).size.width,
                          document.pages[currentPage].size);

                      // RenderBox renderBox =
                      //     context.findRenderObject() as RenderBox;
                      // var offset = renderBox.globalToLocal(
                      //     Offset(widget.offset.dx, widget.offset.dy));
                      document.pages[currentPage].graphics.drawImage(
                        image,
                        Rect.fromLTWH(
                          convertedOffset.dx,
                          convertedOffset.dy,
                          250,
                          150,
                        ),
                      );
                      final directory = await getExternalStorageDirectory();
                      final filePath = '${directory!.path}/edited_pdf.pdf';
                      final file = File(filePath);
                      await file.writeAsBytes(await document.save());
                      // final modifiedBytes = await document.save();
                      // final modifiedFile = File(widget.file.path);
                      // await modifiedFile.writeAsBytes(modifiedBytes);
                      print(file.path);
                      controller.editFilePath.value = file.path;
                      // print("After Save file x =${convertedOffset.dx }");
                      // print("After Save file y =${convertedOffset.dy }");
                      Get.toNamed(
                        Routes.downloadedPdf,
                        arguments: file.path,
                      );
                      document.dispose();
                      widget.isFixed = true;
                      setState(() {});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.black,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.done,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
