import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/coa_report_model.dart';
import '../controllers/sample_controller.dart';
import 'coa_pdf_preview_panel.dart';
import 'sample_status_badge.dart';

class CoaTreeViewSection extends StatefulWidget {
  final SampleController controller;
  final bool isMobile;
  final Future<void> Function()? onRefresh;
  final bool showOpenExternalAction;
  final void Function(CoaSampleNodeModel node, CoaReportItemModel report)? onInspectCoa;
  final void Function(CoaSampleNodeModel node, CoaReportItemModel report)? onViewCoa;

  const CoaTreeViewSection({
    super.key,
    required this.controller,
    required this.isMobile,
    this.onRefresh,
    this.showOpenExternalAction = true,
    this.onInspectCoa,
    this.onViewCoa,
  });

  @override
  State<CoaTreeViewSection> createState() => _CoaTreeViewSectionState();
}

class _CoaTreeViewSectionState extends State<CoaTreeViewSection> {
  final TextEditingController _searchController = TextEditingController();
  CoaSampleNodeModel? _selectedPreviewNode;
  CoaReportItemModel? _selectedPreviewReport;
  bool _isFullscreenPreview = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.controller.coaSearchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectReport(CoaSampleNodeModel node, CoaReportItemModel report) {
    if (widget.onViewCoa != null) {
      widget.onViewCoa!(node, report);
      return;
    }

    if (widget.isMobile || MediaQuery.of(context).size.width < 900) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => FractionallySizedBox(
          heightFactor: 0.92,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: CoaPdfPreviewPanel(
              node: node,
              report: report,
              onClose: () => Navigator.of(ctx).pop(),
              showOpenExternalAction: widget.showOpenExternalAction,
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedPreviewNode = node;
      _selectedPreviewReport = report;
      _isFullscreenPreview = false;
    });
  }

  Future<void> _reloadReports(SampleController controller) {
    return widget.onRefresh?.call() ?? controller.loadCoaReports();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    // Automatically select the first item by default if available and none selected
    final nodes = controller.coaNodes;
    if (nodes.isNotEmpty) {
      if (_selectedPreviewNode == null || !nodes.any((n) => n.id == _selectedPreviewNode!.id)) {
        _selectedPreviewNode = nodes.first;
        _selectedPreviewReport = nodes.first.reports.isNotEmpty ? nodes.first.reports.first : null;
      } else if (_selectedPreviewReport == null && _selectedPreviewNode!.reports.isNotEmpty) {
        _selectedPreviewReport = _selectedPreviewNode!.reports.first;
      }
    } else {
      _selectedPreviewNode = null;
      _selectedPreviewReport = null;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(widget.isMobile ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Control Bar (Search & Filter)
          _buildControlBar(controller),

          const SizedBox(height: 18),

          // 2. Content / State Handlers
          if (controller.isCoaLoading)
            const SizedBox(
              height: 220,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (controller.coaError != null)
            _buildErrorState(controller)
          else if (controller.coaNodes.isEmpty)
            _buildEmptyState(controller)
          else
            _buildMainLayout(controller),
        ],
      ),
    );
  }

  Widget _buildMainLayout(SampleController controller) {
    final listWidget = _buildReportsList(controller);

    return LayoutBuilder(
      builder: (context, constraints) {
        final canShowPreview = !widget.isMobile &&
            constraints.maxWidth >= 900 &&
            _selectedPreviewReport != null;
        if (!canShowPreview) return listWidget;

        final availableHeight = MediaQuery.of(context).size.height - 300;
        final panelHeight = availableHeight.clamp(360.0, 720.0);

        if (_isFullscreenPreview) {
          return SizedBox(
            height: panelHeight,
            child: CoaPdfPreviewPanel(
              node: _selectedPreviewNode!,
              report: _selectedPreviewReport!,
              showOpenExternalAction: widget.showOpenExternalAction,
              isFullscreen: true,
              onToggleFullscreen: () =>
                  setState(() => _isFullscreenPreview = false),
              onClose: () => setState(() => _isFullscreenPreview = false),
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: SizedBox(
                height: panelHeight,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 6),
                    child: listWidget,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 7,
              child: SizedBox(
                height: panelHeight,
                child: CoaPdfPreviewPanel(
                  node: _selectedPreviewNode!,
                  report: _selectedPreviewReport!,
                  showOpenExternalAction: widget.showOpenExternalAction,
                  isFullscreen: false,
                  onToggleFullscreen: () =>
                      setState(() => _isFullscreenPreview = true),
                  onClose: () {},
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlBar(SampleController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = widget.isMobile || constraints.maxWidth < 720;
        final searchField = TextField(
          controller: _searchController,
          onChanged: controller.setCoaSearchQuery,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search by LIMS ID, file name, or report number',
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: AppColors.textSecondary,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      controller.setCoaSearchQuery('');
                    },
                  )
                : null,
          ),
        );

        final statusFilter = DropdownButtonFormField<String>(
          initialValue: controller.selectedCoaStatusFilter,
          isExpanded: true,
          items: controller.availableCoaStatusFilters.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(
                status == 'All' ? 'All statuses' : status,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) controller.setCoaStatusFilter(value);
          },
          decoration: const InputDecoration(
            labelText: 'Status',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );

        final refreshButton = IconButton(
          onPressed: () => _reloadReports(controller),
          icon: const Icon(
            Icons.refresh,
            size: 18,
            color: AppColors.textSecondary,
          ),
          tooltip: 'Refresh reports',
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: statusFilter),
                  const SizedBox(width: 8),
                  refreshButton,
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 14),
            SizedBox(width: 180, child: statusFilter),
            const SizedBox(width: 4),
            refreshButton,
          ],
        );
      },
    );
  }

  Widget _buildReportsList(SampleController controller) {
    final nodes = controller.coaNodes;

    final List<_CoaCardItem> cardItems = [];
    for (final node in nodes) {
      if (node.reports.isEmpty) {
        cardItems.add(_CoaCardItem(
          node: node,
          report: CoaReportItemModel(
            coaId: node.id,
            certificateNo: node.limsId,
            reportDate: '',
            issueDate: '',
            authorizedBy: '',
            status: node.coaStatus,
            downloadUrl: '',
            parameters: [],
          ),
        ));
      } else {
        for (final r in node.reports) {
          cardItems.add(_CoaCardItem(node: node, report: r));
        }
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cardItems.length,
      itemBuilder: (context, index) {
        final item = cardItems[index];
        return _buildReportCard(context, item.node, item.report);
      },
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    CoaSampleNodeModel node,
    CoaReportItemModel report,
  ) {
    final bool isSelected = _selectedPreviewNode?.id == node.id &&
        ((_selectedPreviewReport?.reportNumber.isNotEmpty == true &&
          _selectedPreviewReport?.reportNumber == report.reportNumber) ||
         (_selectedPreviewReport?.fileName.isNotEmpty == true &&
          _selectedPreviewReport?.fileName == report.fileName) ||
         (_selectedPreviewReport?.coaId == report.coaId));

    final statusText = report.reportStatus.isNotEmpty ? report.reportStatus : report.status;
    final fileName = report.fileName.isNotEmpty
        ? report.fileName
        : (report.reportName.isNotEmpty ? report.reportName : 'Certificate of Analysis');
    final limsIdText = node.limsId.isNotEmpty
        ? node.limsId
        : (node.sampleId.isNotEmpty ? node.sampleId : (node.id.isNotEmpty ? node.id : 'N/A'));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderLight,
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectReport(node, report),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. LIMS ID & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'LIMS ID: ',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.primary : AppColors.textMuted,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              limsIdText,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppColors.primary : AppColors.darkBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SampleStatusBadge(status: statusText),
                  ],
                ),
                const SizedBox(height: 8),

                // 2. File Name with PDF Icon
                Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 16,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF1D4ED8) : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(SampleController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.folder_off_outlined, size: 44, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            'No reports found',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different search or status filter.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              controller.setCoaSearchQuery('');
              controller.setCoaStatusFilter('All');
            },
            icon: const Icon(Icons.clear, size: 14),
            label: const Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(SampleController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 42, color: Color(0xFFEF4444)),
          const SizedBox(height: 10),
          Text(
            'Reports could not be loaded',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              controller.coaError ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _reloadReports(controller),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoaCardItem {
  final CoaSampleNodeModel node;
  final CoaReportItemModel report;
  const _CoaCardItem({required this.node, required this.report});
}
