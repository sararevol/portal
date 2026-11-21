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
    _controller.loadCoaReports();
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
    final padding = widget.isMobile ? 16.0 : 48.0;

    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: widget.isMobile ? 24 : 44,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: GoogleFonts.montserrat(
                  fontSize: widget.isMobile ? 24 : 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Browse all laboratory reports, search by report number or LIMS ID, and open available certificates.',
                style: GoogleFonts.montserrat(
                  fontSize: widget.isMobile ? 12 : 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              CoaTreeViewSection(
                controller: _controller,
                isMobile: widget.isMobile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
