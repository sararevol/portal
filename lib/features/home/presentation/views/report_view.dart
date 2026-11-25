import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../samples/presentation/controllers/sample_controller.dart';
import '../../../samples/presentation/widgets/coa_tree_view_section.dart';

class ReportView extends StatefulWidget {
  final bool isMobile;

  const ReportView({
    super.key,
    required this.isMobile,
  });

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  final SampleController _controller = SampleController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStateChanged);
    _controller.loadPublicCoaReports();
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = widget.isMobile || constraints.maxWidth < 760;
        final horizontalPadding = isCompact
            ? 16.0
            : constraints.maxWidth < 1100
                ? 28.0
                : 48.0;
        final reportCount = _controller.totalCoaCertificatesCount;

        return Container(
          width: double.infinity,
          color: const Color(0xFFF8FAFC),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isCompact ? 20 : 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(isCompact ? 18 : 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: isCompact ? 44 : 52,
                          height: isCompact ? 44 : 52,
                          decoration: BoxDecoration(
                            color: AppColors.activeBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: isCompact ? 22 : 26,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: isCompact ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report library',
                                style: GoogleFonts.montserrat(
                                  fontSize: isCompact ? 20 : 25,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Browse, search, and open available laboratory reports.',
                                style: GoogleFonts.montserrat(
                                  fontSize: isCompact ? 12 : 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isCompact && reportCount > 0) ...[
                          const SizedBox(width: 16),
                          _ReportCountBadge(count: reportCount),
                        ],
                      ],
                    ),
                  ),
                  if (isCompact && reportCount > 0) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _ReportCountBadge(count: reportCount),
                    ),
                  ],
                  SizedBox(height: isCompact ? 14 : 18),
                  CoaTreeViewSection(
                    controller: _controller,
                    isMobile: isCompact,
                    onRefresh: _controller.loadPublicCoaReports,
                    showOpenExternalAction: false,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReportCountBadge extends StatelessWidget {
  final int count;

  const _ReportCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.activeBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count reports',
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
