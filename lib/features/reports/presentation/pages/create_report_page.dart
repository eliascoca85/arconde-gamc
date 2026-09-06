import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/app_animations.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../data/repositories/emergency_repository.dart';
import '../../../../../mock/models.dart';
import '../../../../../mock/mock_data.dart';
import '../../../../../shared/widgets/basic_widgets.dart';
import '../widgets/report_step_indicator.dart';
import '../widgets/report_success_sheet.dart';
import '../widgets/category_selection_step.dart';
import '../widgets/location_step.dart';
import '../widgets/evidence_step.dart';
import '../widgets/review_step.dart';

class CreateReportPage extends StatefulWidget {
  const CreateReportPage({super.key});

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  final PageController _pageController = PageController();
  final _emergencyRepository = EmergencyRepository();
  int _currentStep = 0;
  final int _totalSteps = 4;

  IncidentCategory? _selectedCategory;
  Location? _selectedLocation;
  List<String> _evidenceUrls = [];
  String _description = '';
  bool _isSubmitting = false;
  Location _userLocation = const Location(
    latitude: AppConstants.defaultMapLatitude,
    longitude: AppConstants.defaultMapLongitude,
    address: '',
    zone: '',
  );

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _userLocation = Location(
          latitude: position.latitude,
          longitude: position.longitude,
          address: '',
          zone: '',
        );
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: AppAnimations.normal,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: AppAnimations.normal,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPageChanged(int step) {
    setState(() => _currentStep = step);
  }

  void _onCategorySelected(IncidentCategory category) {
    setState(() => _selectedCategory = category);
  }

  void _onLocationSelected(Location location) {
    setState(() => _selectedLocation = location);
  }

  void _onEvidenceAdded(List<String> urls) {
    setState(() => _evidenceUrls = urls);
  }

  void _onDescriptionChanged(String description) {
    setState(() => _description = description);
  }

  Future<void> _submitReport() async {
    final location = _selectedLocation ?? _userLocation;
    final categoryLabel = _selectedCategory?.title;
    final description = (categoryLabel != null && categoryLabel.isNotEmpty)
        ? '[$categoryLabel] ${_description.trim()}'
        : _description.trim();

    setState(() => _isSubmitting = true);
    try {
      final emergency = await _emergencyRepository.report(
        description: description,
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
        category: _selectedCategory?.type,
      );

      final localEvidence = _evidenceUrls.where((url) => !url.startsWith('http'));
      for (final path in localEvidence) {
        try {
          await _emergencyRepository.uploadEvidence(
            emergency.pkEmergency,
            File(path),
            fileType: inferEvidenceFileType(path),
          );
        } catch (_) {
          // Evidence upload failures shouldn't block the report confirmation.
        }
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ReportSuccessSheet(
          reportCode: emergency.emergencyCode,
          onViewTracking: () {
            Navigator.pop(context);
            context.go('/reports/my');
          },
          onBackToMap: () {
            Navigator.pop(context);
            context.go('/');
          },
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar el reporte. Intenta nuevamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Nuevo reporte', style: AppTextStyles.titleLarge),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: _previousStep,
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
      ),
      body: Column(
        children: [
          ReportStepIndicator(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                CategorySelectionStep(
                  categories: MockData.incidentCategories,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: _onCategorySelected,
                ),
                LocationStep(
                  selectedLocation: _selectedLocation,
                  onLocationSelected: _onLocationSelected,
                  userLocation: _userLocation,
                ),
                EvidenceStep(
                  evidenceUrls: _evidenceUrls,
                  onEvidenceChanged: _onEvidenceAdded,
                ),
                ReviewStep(
                  category: _selectedCategory,
                  location: _selectedLocation,
                  evidenceUrls: _evidenceUrls,
                  description: _description,
                  onDescriptionChanged: _onDescriptionChanged,
                  onSubmit: _submitReport,
                ),
              ],
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
        border: Border(top: BorderSide(color: AppColors.borderPrimary, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: AppOutlinedButton(
                  label: 'Atrás',
                  onPressed: _previousStep,
                  icon: Icons.arrow_back,
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: _currentStep == _totalSteps - 1 ? 'Enviar reporte' : 'Siguiente',
                onPressed: _currentStep == _totalSteps - 1 ? _submitReport : _nextStep,
                icon: _currentStep == _totalSteps - 1 ? Icons.send : Icons.arrow_forward,
                trailingIcon: _currentStep == _totalSteps - 1 ? null : Icons.arrow_forward,
                isLoading: _isSubmitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}