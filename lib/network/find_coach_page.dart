import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/models/coach.dart';
import 'package:projectbrain/models/location.dart';
import 'package:projectbrain/services/coach_service.dart';
import 'package:projectbrain/services/location_service.dart';
import 'package:projectbrain/services/user_service.dart';
import 'package:projectbrain/widgets/location/city_search_field.dart';
import 'package:projectbrain/widgets/location/country_search_field.dart';
import 'package:projectbrain/widgets/maps/coach_results_map.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

enum ResultsView { list, map }

/// Page for finding nearby coaches
class FindCoachPage extends StatefulWidget {
  const FindCoachPage({super.key});

  @override
  State<FindCoachPage> createState() => _FindCoachPageState();
}

class _FindCoachPageState extends State<FindCoachPage> {
  final CoachService _coachService = sl<CoachService>();
  final LocationService _locationService = sl<LocationService>();
  final UserService _userService = sl<UserService>();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();

  List<Coach> _coaches = [];
  List<CountryOption> _countries = [];
  bool _isLoadingCountries = true;
  bool _isLoading = false;
  bool _isAcquiringLocation = false;
  bool _hasSearched = false;
  String? _errorMessage;

  CountryOption? _selectedCountry;
  CityOption? _selectedCity;
  SearchCenter? _searchCenter;
  int _distanceMiles = 25;
  ResultsView _resultsView = ResultsView.list;
  String? _highlightedCoachId;

  final Set<String> _selectedSpecialisms = {};
  final Set<String> _selectedAgeGroups = {};

  List<String> _specialisms = [];
  bool _isLoadingSpecialisms = true;
  String? _specialismsLoadError;

  final List<String> _ageGroups = [
    'Children (5-12)',
    'Teens (13-17)',
    'Young Adults (18-25)',
    'Adults (26-40)',
    'Middle-aged (41-60)',
    'Seniors (60+)',
  ];

  static const _distanceOptions = [5, 10, 25, 50, 100];

  bool get _canShowMap => _searchCenter != null && _hasSearched && !_isLoading;

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _loadSpecialisms();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await _locationService.getCountries();
      CountryOption? initialCountry;
      try {
        final user = await _userService.getCurrentUser();
        final countryName = user['country']?.toString();
        if (countryName != null && countryName.isNotEmpty) {
          for (final country in countries) {
            if (country.name.toLowerCase() == countryName.toLowerCase()) {
              initialCountry = country;
              break;
            }
          }
        }
      } catch (_) {
        // Ignore profile load failures for default country.
      }

      if (!mounted) return;
      setState(() {
        _countries = countries;
        _selectedCountry = initialCountry;
        _isLoadingCountries = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCountries = false;
        _errorMessage = 'Failed to load countries. Please try again.';
      });
    }
  }

  Future<void> _loadSpecialisms() async {
    try {
      final specialisms = await _coachService.getSpecialisms();
      if (!mounted) return;
      setState(() {
        _specialisms = specialisms;
        _isLoadingSpecialisms = false;
        _specialismsLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _specialisms = [];
        _isLoadingSpecialisms = false;
        _specialismsLoadError =
            'Failed to load specialisms. Please try again later.';
      });
    }
  }

  Future<void> _searchCoaches({
    String? city,
    String? stateProvince,
    String? country,
    double? latitude,
    double? longitude,
    int? distanceMiles,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
      _highlightedCoachId = null;
      if (!_canShowMap) {
        _resultsView = ResultsView.list;
      }
    });

    try {
      final coaches = await _coachService.searchCoaches(
        city: city,
        stateProvince: stateProvince,
        country: country,
        latitude: latitude,
        longitude: longitude,
        distanceMiles: distanceMiles,
        ageGroups: _selectedAgeGroups.isNotEmpty
            ? _selectedAgeGroups.toList()
            : null,
        specialisms: _selectedSpecialisms.isNotEmpty
            ? _selectedSpecialisms.toList()
            : null,
      );

      if (!mounted) return;
      setState(() {
        _coaches = coaches;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToResults();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to search coaches: ${e.toString()}';
        _coaches = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSearch() async {
    if (_searchCenter != null) {
      await _searchCoaches(
        latitude: _searchCenter!.latitude,
        longitude: _searchCenter!.longitude,
        distanceMiles: _distanceMiles,
      );
      return;
    }

    if (_selectedCity != null ||
        (_selectedCountry != null && _selectedCity == null)) {
      await _searchCoaches(
        city: _selectedCity?.city,
        stateProvince: _selectedCity?.stateProvince,
        country: _selectedCountry?.name ?? _selectedCity?.country,
      );
      return;
    }

    await _searchCoaches();
  }

  Future<bool> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      setState(() {
        _errorMessage =
            'Location permission is required to find coaches near you.';
      });
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage =
            'Location permission is permanently denied. Enable it in Settings to use current location.';
      });
      return false;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage =
            'Location services are disabled. Enable them to use current location.';
      });
      return false;
    }

    return true;
  }

  Future<void> _searchByCurrentLocation() async {
    setState(() {
      _isAcquiringLocation = true;
      _errorMessage = null;
      _selectedCity = null;
    });

    try {
      final allowed = await _ensureLocationPermission();
      if (!allowed) {
        setState(() => _isAcquiringLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;
      setState(() {
        _searchCenter = SearchCenter(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _isAcquiringLocation = false;
      });

      await _searchCoaches(
        latitude: position.latitude,
        longitude: position.longitude,
        distanceMiles: _distanceMiles,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAcquiringLocation = false;
        _errorMessage = 'Failed to get your location. Please try again.';
      });
    }
  }

  void _onCountryChanged(CountryOption? country) {
    setState(() {
      _selectedCountry = country;
      _selectedCity = null;
      if (_searchCenter != null) {
        _searchCenter = null;
      }
    });
  }

  void _onCityChanged(CityOption? city) {
    setState(() {
      _selectedCity = city;
      if (city != null) {
        _searchCenter = SearchCenter(
          latitude: city.latitude,
          longitude: city.longitude,
        );
      } else if (_searchCenter != null && !_isAcquiringLocation) {
        _searchCenter = null;
      }
    });
  }

  void _scrollToResults() {
    final context = _resultsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  void _scrollToCoach(String coachProfileId) {
    setState(() {
      _resultsView = ResultsView.list;
      _highlightedCoachId = coachProfileId;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToResults();
    });
  }

  void _toggleSpecialism(String specialism) {
    setState(() {
      if (_selectedSpecialisms.contains(specialism)) {
        _selectedSpecialisms.remove(specialism);
      } else {
        _selectedSpecialisms.add(specialism);
      }
    });
  }

  void _toggleAgeGroup(String ageGroup) {
    setState(() {
      if (_selectedAgeGroups.contains(ageGroup)) {
        _selectedAgeGroups.remove(ageGroup);
      } else {
        _selectedAgeGroups.add(ageGroup);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedSpecialisms.clear();
      _selectedAgeGroups.clear();
    });
  }

  String? _coachLocationLabel(Coach coach) {
    final parts = <String>[];
    if (coach.city != null && coach.city!.isNotEmpty) {
      parts.add(coach.city!);
    }
    if (coach.country != null && coach.country!.isNotEmpty) {
      parts.add(coach.country!);
    }
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    if (coach.postalCode != null && coach.postalCode!.isNotEmpty) {
      return coach.postalCode;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Coach'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFiltersCard(theme),
                  SizedBox(height: AppSpacing.lg),
                  _buildLocationCard(theme),
                  SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleSearch,
                      icon: const Icon(Icons.search),
                      label: const Text('Search Coaches'),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    SizedBox(height: AppSpacing.lg),
                    _buildErrorBanner(theme),
                  ],
                  if (_isLoading)
                    const Padding(
                      padding: AppInsets.screen,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_hasSearched && !_isLoading) _buildResultsHeader(theme),
                ]),
              ),
            ),
            if (_hasSearched && !_isLoading) _buildResultsSliver(theme),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppInsets.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter by Specialisms',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedSpecialisms.isNotEmpty ||
                    _selectedAgeGroups.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Select specialisms to find coaches who specialise in them',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            if (_isLoadingSpecialisms)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Text(
                      'Loading specialisms...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_specialismsLoadError != null)
              Text(
                _specialismsLoadError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              )
            else if (_specialisms.isEmpty)
              Text(
                'No specialisms available.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _specialisms.map((specialism) {
                  final isSelected = _selectedSpecialisms.contains(specialism);
                  return FilterChip(
                    label: Text(specialism),
                    selected: isSelected,
                    onSelected: (_) => _toggleSpecialism(specialism),
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.onPrimaryContainer,
                  );
                }).toList(),
              ),
            SizedBox(height: AppSpacing.s20),
            Text(
              'Filter by Age Groups',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Select age groups to find coaches who work with them',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
              children: _ageGroups.map((ageGroup) {
                final isSelected = _selectedAgeGroups.contains(ageGroup);
                return FilterChip(
                  label: Text(ageGroup),
                  selected: isSelected,
                  onSelected: (_) => _toggleAgeGroup(ageGroup),
                  selectedColor: theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.onPrimaryContainer,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppInsets.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            CountrySearchField(
              countries: _countries,
              value: _selectedCountry,
              onChanged: _onCountryChanged,
              isLoading: _isLoadingCountries,
            ),
            SizedBox(height: AppSpacing.md),
            CitySearchField(
              key: ValueKey(_selectedCountry?.code ?? 'no-country'),
              locationService: _locationService,
              countryCode: _selectedCountry?.code,
              value: _selectedCity,
              onChanged: _onCityChanged,
            ),
            SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int>(
              initialValue: _distanceMiles,
              decoration: InputDecoration(
                labelText: 'Distance',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.social_distance),
                helperText: _searchCenter == null
                    ? 'Select a city or use current location to enable distance search.'
                    : null,
              ),
              items: _distanceOptions
                  .map(
                    (miles) => DropdownMenuItem(
                      value: miles,
                      child: Text('$miles miles'),
                    ),
                  )
                  .toList(),
              onChanged: _searchCenter == null
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _distanceMiles = value);
                      }
                    },
            ),
            SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (_isLoading || _isAcquiringLocation)
                    ? null
                    : _searchByCurrentLocation,
                icon: _isAcquiringLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _isAcquiringLocation
                      ? 'Getting your location…'
                      : 'Use current location',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: AppInsets.screen,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: AppRadius.circularSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _errorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          if (_errorMessage != null &&
              _errorMessage!.contains('Settings')) ...[
            SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: openAppSettings,
              child: const Text('Open Settings'),
            ),
          ],
        ],
      ),
    );
  }

  /// Results header (title + list/map toggle). Carries [_resultsKey] so
  /// `_scrollToResults` can bring it into view.
  Widget _buildResultsHeader(ThemeData theme) {
    return Column(
      key: _resultsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Text(
                'Results (${_coaches.length})',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SegmentedButton<ResultsView>(
              segments: const [
                ButtonSegment(
                  value: ResultsView.list,
                  label: Text('List'),
                  icon: Icon(Icons.list),
                ),
                ButtonSegment(
                  value: ResultsView.map,
                  label: Text('Map'),
                  icon: Icon(Icons.map),
                ),
              ],
              selected: {_resultsView},
              onSelectionChanged: (selection) {
                final next = selection.first;
                if (next == ResultsView.map && !_canShowMap) return;
                setState(() => _resultsView = next);
              },
              emptySelectionAllowed: false,
            ),
          ],
        ),
        if (!_canShowMap)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Map view is available after a location-based search.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  /// Results body as a sliver: empty state, map, or a lazily-built coach list.
  Widget _buildResultsSliver(ThemeData theme) {
    if (_coaches.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _buildEmptyResults(theme),
        ),
      );
    }

    if (_resultsView == ResultsView.map && _canShowMap) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: CoachResultsMap(
            coaches: _coaches,
            searchOrigin: _searchCenter,
            searchRadiusMiles: _distanceMiles,
            onSelectCoach: _scrollToCoach,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList.builder(
        itemCount: _coaches.length,
        itemBuilder: (context, index) =>
            _buildCoachCard(theme, _coaches[index]),
      ),
    );
  }

  Widget _buildEmptyResults(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'No coaches found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Try a different location or adjust your filters',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard(ThemeData theme, Coach coach) {
    final locationLabel = _coachLocationLabel(coach);
    final isHighlighted = _highlightedCoachId == coach.profileId;

    return Card(
      margin: AppInsets.listItemBottom,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circularMd,
        side: isHighlighted
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.person,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          coach.fullName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () => context.push('/network/coaches/${coach.profileId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (locationLabel != null) ...[
              SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      locationLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (coach.specialisms != null && coach.specialisms!.isNotEmpty) ...[
              SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                children: coach.specialisms!.take(3).map((spec) {
                  return Chip(
                    label: Text(spec),
                    labelStyle: theme.textTheme.bodySmall,
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
