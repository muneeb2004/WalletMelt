import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../../services/export/export_file_writer.dart';
import '../../services/export/export_share_service.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/category.dart';
import '../../types/expense.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';
import '../../utils/platform_info.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/receipt_image.dart';

abstract class ReceiptExportService {
  Future<String?> saveReceipt(String uri, String fileName);
}

class FilePickerReceiptExportService implements ReceiptExportService {
  const FilePickerReceiptExportService();

  @override
  Future<String?> saveReceipt(String uri, String fileName) async {
    try {
      if (PlatformInfo.isWeb) {
        if (uri.startsWith('data:image')) {
          final base64Content = uri.split(',').last;
          final bytes = base64Decode(base64Content);
          final savedUri = await FilePicker.saveFile(
            fileName: fileName,
            bytes: bytes,
          );
          return savedUri?.toString();
        }
        return null;
      }
      final filePath = uri.startsWith('file://') ? Uri.parse(uri).toFilePath() : uri;
      final file = io.File(filePath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final savedUri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
      );
      return savedUri?.path ?? savedUri?.toString();
    } catch (_) {
      return null;
    }
  }
}

class ReceiptViewerScreen extends StatefulWidget {
  const ReceiptViewerScreen({
    required this.expenseId,
    this.exportShareService = const SharePlusExportShareService(),
    this.receiptExportService = const FilePickerReceiptExportService(),
    super.key,
  });

  final String expenseId;
  final ExportShareService exportShareService;
  final ReceiptExportService receiptExportService;

  @override
  State<ReceiptViewerScreen> createState() => _ReceiptViewerScreenState();
}

class _ReceiptViewerScreenState extends State<ReceiptViewerScreen>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _animationController;
  Animation<Matrix4>? _matrixAnimation;
  TapDownDetails? _doubleTapDetails;

  bool _showControls = true;
  bool _isLoading = true;
  bool _fileNotFound = false;
  bool _hasError = false;
  String? _errorMessage;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _checkFile();
    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFile() async {
    // Yield to the event loop so that the loading state is rendered first.
    await Future<void>.delayed(Duration.zero);

    if (!mounted) return;

    final state = context.read<AppState>();
    final expense = state.expenses.where((e) => e.id == widget.expenseId).firstOrNull ??
        state.deletedExpenses.where((e) => e.id == widget.expenseId).firstOrNull;

    if (expense == null || expense.receiptImageUri == null) {
      if (mounted) {
        setState(() {
          _fileNotFound = true;
          _isLoading = false;
        });
      }
      return;
    }

    if (PlatformInfo.isWeb) {
      if (mounted) {
        setState(() {
          _fileNotFound = false;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final path = Uri.parse(expense.receiptImageUri!).toFilePath();
      final file = io.File(path);
      final exists = file.existsSync();
      if (mounted) {
        setState(() {
          _fileNotFound = !exists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load receipt image.';
          _isLoading = false;
        });
      }
    }
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _resetHideTimer();
    } else {
      _cancelHideTimer();
    }
  }

  void _handleDoubleTap() {
    _cancelHideTimer();
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    final Matrix4 endMatrix;
    if (currentScale > 1.1) {
      endMatrix = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      final double x = position.dx;
      final double y = position.dy;
      const double targetScale = 3.0;

      endMatrix = Matrix4.translationValues(x, y, 0.0) *
          Matrix4.diagonal3Values(targetScale, targetScale, 1.0) *
          Matrix4.translationValues(-x, -y, 0.0);
    }

    _animateToMatrix(endMatrix);
    _resetHideTimer();
  }

  void _animateToMatrix(Matrix4 targetMatrix) {
    _matrixAnimation?.removeListener(_onAnimationTick);
    _matrixAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _matrixAnimation!.addListener(_onAnimationTick);
    _animationController.forward(from: 0);
  }

  void _onAnimationTick() {
    setState(() {
      _transformationController.value = _matrixAnimation!.value;
    });
  }

  void _resetZoom() {
    _cancelHideTimer();
    _animateToMatrix(Matrix4.identity());
    _resetHideTimer();
  }

  Future<void> _shareReceipt(String uri) async {
    _cancelHideTimer();
    try {
      if (PlatformInfo.isWeb) {
        if (mounted) {
          showErrorSnackbar(context, 'Receipt sharing is not supported on web. Use the download button.');
        }
        return;
      }
      final filePath = uri.startsWith('file://') ? Uri.parse(uri).toFilePath() : uri;
      final file = io.File(filePath);
      final byteCount = file.lengthSync();
      final exportFile = ExportFileResult(
        path: file.path,
        fileName: p.basename(file.path),
        byteCount: byteCount,
        mimeType: 'image/jpeg',
        createdAt: DateTime.now(),
      );
      await widget.exportShareService.shareFile(exportFile);
    } catch (_) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to share receipt image');
      }
    }
    _resetHideTimer();
  }

  Future<void> _exportReceipt(String uri, String title) async {
    _cancelHideTimer();
    final sanitizedTitle = title.replaceAll(RegExp(r'[^\w]'), '_');
    final fileName = 'receipt_$sanitizedTitle.jpg';
    final savedPath = await widget.receiptExportService.saveReceipt(uri, fileName);

    if (mounted) {
      if (savedPath != null) {
        showSuccessSnackbar(context, 'Receipt saved: ${p.basename(savedPath)}');
      } else {
        showErrorSnackbar(context, 'Receipt export cancelled or failed');
      }
    }
    _resetHideTimer();
  }

  void _showDetailsSheet(
      BuildContext context, Expense expense, Category? category, String currency) {
    _cancelHideTimer();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: WMGlassSurface.tier3(
            radius: AppSpacing.radiusLg,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Receipt Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close details',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(context, 'Title', expense.title),
                _buildDetailRow(context, 'Amount', formatMoney(expense.amount, currency)),
                _buildDetailRow(context, 'Date', readableMonth(parseIsoDate(expense.date))),
                _buildDetailRow(context, 'Category', category?.name ?? 'Unknown'),
                if (expense.vendor != null && expense.vendor!.isNotEmpty)
                  _buildDetailRow(context, 'Vendor', expense.vendor!),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    ).then((_) => _resetHideTimer());
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image_rounded,
                color: WalletMeltColors.danger,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load receipt',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: WalletMeltColors.brand,
          ),
        ),
      );
    }

    if (_fileNotFound) {
      return _buildErrorState('The receipt image file could not be found or has been deleted.');
    }

    if (_hasError) {
      return _buildErrorState(_errorMessage ?? 'An unknown error occurred while loading the file.');
    }

    final state = context.watch<AppState>();
    final expense = state.expenses.where((e) => e.id == widget.expenseId).firstOrNull ??
        state.deletedExpenses.where((e) => e.id == widget.expenseId).firstOrNull;

    if (expense == null || expense.receiptImageUri == null) {
      return _buildErrorState('The associated expense could not be found.');
    }

    final category = state.categoryById(expense.categoryId);
    final isZoomed = _transformationController.value.getMaxScaleOnAxis() > 1.05;
    final mediaQueryPadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Immersive Zoomable Image Container
          Positioned.fill(
            child: Semantics(
              label: 'Receipt Image. Double tap to zoom. Pinch to scale.',
              image: true,
              child: GestureDetector(
                onTap: _toggleControls,
                onDoubleTapDown: (details) => _doubleTapDetails = details,
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 5.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  onInteractionStart: (_) => _cancelHideTimer(),
                  onInteractionEnd: (_) => _resetHideTimer(),
                  child: Center(
                    child: Hero(
                      tag: expense.receiptImageUri!,
                      child: ReceiptImage(
                        receiptUri: expense.receiptImageUri,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildErrorState('The file is corrupted or could not be decoded.');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Safe controls overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            top: _showControls ? 0.0 : -100.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              padding: EdgeInsets.only(
                top: mediaQueryPadding.top + 8,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Close viewer',
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => context.pop(),
                      tooltip: 'Close',
                    ),
                  ),
                  if (isZoomed) ...[
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      label: 'Reset Zoom',
                      child: IconButton(
                        icon: const Icon(Icons.zoom_out_map_rounded, color: Colors.white, size: 24),
                        onPressed: _resetZoom,
                        tooltip: 'Reset Zoom',
                      ),
                    ),
                  ],
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: 'Share receipt file',
                    child: IconButton(
                      icon: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 24),
                      onPressed: () => _shareReceipt(expense.receiptImageUri!),
                      tooltip: 'Share',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: 'Save or export receipt file',
                    child: IconButton(
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 24),
                      onPressed: () => _exportReceipt(expense.receiptImageUri!, expense.title),
                      tooltip: 'Save to device',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details Action Floating Panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            bottom: _showControls ? 0.0 : -120.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              padding: EdgeInsets.only(
                top: 16,
                bottom: mediaQueryPadding.bottom + 16,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatMoney(expense.amount, state.settings.currency),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: WalletMeltColors.brand,
                                fontWeight: FontWeight.w800,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Semantics(
                    button: true,
                    label: 'View receipt information details',
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => _showDetailsSheet(
                          context, expense, category, state.settings.currency),
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text('Details'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
