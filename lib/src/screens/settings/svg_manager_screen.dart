import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../components/category/category_icon.dart';
import '../../components/glass/app_background.dart';
import '../../services/svg/svg_customization_service.dart';
import '../../services/svg/svg_safeguard_service.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../widgets/app_snackbar.dart';
import 'svg_editor_dialog.dart';

class SvgManagerScreen extends StatefulWidget {
  const SvgManagerScreen({super.key});

  @override
  State<SvgManagerScreen> createState() => _SvgManagerScreenState();
}

class _SvgManagerScreenState extends State<SvgManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SvgIconItem> _allIcons = [];
  bool _isLoading = true;
  String _filterType = 'all'; // all, preset, standard, custom

  @override
  void initState() {
    super.initState();
    _loadIcons();
    SvgCustomizationService.instance.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _searchController.dispose();
    SvgCustomizationService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final icons = await SvgCustomizationService.instance.listAllIcons();
    if (mounted) {
      setState(() {
        _allIcons = icons;
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadNewCustomSvg() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svg'],
      );

      // ignore: unnecessary_null_comparison
      if (result != null && result.isNotEmpty) {
        final file = result.first;
        String? content;
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          content = utf8.decode(bytes);
        } else if (file.path != null) {
          content = await File(file.path!).readAsString();
        }

        if (content == null || content.isEmpty) {
          if (mounted) showErrorSnackbar(context, 'Could not read SVG file.');
          return;
        }

        const safeguard = SvgSafeguardService();
        final val = safeguard.validate(content);
        if (!val.isValid || val.sanitizedContent == null) {
          if (mounted) {
            showErrorSnackbar(
                context, val.errorMessage ?? 'Invalid SVG file.');
          }
          return;
        }

        final docsDir = await getApplicationDocumentsDirectory();
        final iconId = await safeguard.saveCustomSvg(
          sanitizedSvg: val.sanitizedContent!,
          baseDir: docsDir,
        );

        await _loadIcons();
        if (mounted) {
          showSuccessSnackbar(context, 'New custom SVG added!');
          final newItem = _allIcons.firstWhere(
            (i) => i.id == iconId,
            orElse: () => SvgIconItem(
              id: iconId,
              label: 'Custom SVG',
              type: SvgIconType.custom,
            ),
          );
          SvgEditorDialog.show(context, newItem);
        }
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Upload failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final query = _searchController.text.toLowerCase().trim();
    final filtered = _allIcons.where((item) {
      if (_filterType == 'preset' && item.type != SvgIconType.preset) {
        return false;
      }
      if (_filterType == 'standard' && item.type != SvgIconType.standard) {
        return false;
      }
      if (_filterType == 'custom' && item.type != SvgIconType.custom) {
        return false;
      }
      if (query.isNotEmpty) {
        return item.label.toLowerCase().contains(query) ||
            item.id.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Scaffold(
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            // Top Bar
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Icon & SVG Manager',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Add Custom SVG',
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: _uploadNewCustomSvg,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Explanatory Banner Card
            WMGlassSurface.tier1(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: WalletMeltColors.brand.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 20,
                      color: WalletMeltColors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Across-the-Board SVG Reflection',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap any SVG icon to edit its color, paths, or code. Saved modifications immediately update every category, budget, and transaction tile.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Box
            Container(
              decoration: BoxDecoration(
                color: isDark ? WalletMeltColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? WalletMeltColors.darkBorder
                      : WalletMeltColors.lightBorder,
                  width: 1.0,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search icons by name...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All Icons (${_allIcons.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('preset', 'Preset SVGs'),
                  const SizedBox(width: 8),
                  _buildFilterChip('standard', 'Standard Categories'),
                  const SizedBox(width: 8),
                  _buildFilterChip('custom', 'Custom Uploads'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Icon List / Grid
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off_rounded,
                          size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'No icons match "$query"',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isCustomized = SvgCustomizationService.instance
                      .isCustomized(item.id);

                  return WMGlassSurface.tier2(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    onTap: () => SvgEditorDialog.show(context, item),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E2430)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCustomized
                                  ? WalletMeltColors.brand
                                  : (isDark
                                      ? Colors.white12
                                      : Colors.black12),
                              width: isCustomized ? 1.5 : 1.0,
                            ),
                          ),
                          child: CategoryIcon(
                            icon: item.id,
                            size: 24,
                            color: isCustomized
                                ? WalletMeltColors.brand
                                : (isDark
                                    ? Colors.white
                                    : WalletMeltColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.type == SvgIconType.custom
                                    ? 'Custom user SVG'
                                    : 'Identifier: ${item.id}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCustomized) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: WalletMeltColors.brand
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'EDITED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: WalletMeltColors.brand,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final isSelected = _filterType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => setState(() => _filterType = type),
      selectedColor: isDark ? WalletMeltColors.brand : WalletMeltColors.textPrimary,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: isSelected
            ? (isDark ? Colors.black : Colors.white)
            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      ),
    );
  }
}
