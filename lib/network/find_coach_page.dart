import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/models/coach.dart';
import 'package:projectbrain/services/coach_service.dart';

/// Page for finding nearby coaches
class FindCoachPage extends StatefulWidget {
  const FindCoachPage({super.key});

  @override
  State<FindCoachPage> createState() => _FindCoachPageState();
}

class _FindCoachPageState extends State<FindCoachPage> {
  final CoachService _coachService = sl<CoachService>();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();

  List<Coach> _coaches = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  // Filter selections
  final Set<String> _selectedTraits = {};
  final Set<String> _selectedAgeGroups = {};

  // Available options
  final List<String> _neurodiverseTraits = [
    'ADHD',
    'Autism',
    'Dyslexia',
    'Dyscalculia',
    'Dyspraxia',
    'Dysgraphia',
    'Tourette Syndrome',
    'OCD',
    'Anxiety',
    'Depression',
    'Bipolar Disorder',
    'Other',
  ];

  final List<String> _ageGroups = [
    'Children (5-12)',
    'Teens (13-17)',
    'Young Adults (18-25)',
    'Adults (26-40)',
    'Middle-aged (41-60)',
    'Seniors (60+)',
  ];

  @override
  void dispose() {
    _postcodeController.dispose();
    _addressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _searchByPostcode() async {
    if (_postcodeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a postcode';
      });
      return;
    }

    await _searchCoaches(postcode: _postcodeController.text.trim());
  }

  Future<void> _searchByAddress() async {
    if (_addressController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an address';
      });
      return;
    }

    await _searchCoaches(address: _addressController.text.trim());
  }

  Future<void> _searchByLocation() async {
    // TODO: Get current location using geolocator or similar
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location search coming soon'),
      ),
    );
  }

  Future<void> _searchCoaches({
    String? postcode,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final coaches = await _coachService.searchCoaches(
        postcode: postcode,
        address: address,
        latitude: latitude,
        longitude: longitude,
        neurodiverseTraits:
            _selectedTraits.isNotEmpty ? _selectedTraits.toList() : null,
        ageGroups:
            _selectedAgeGroups.isNotEmpty ? _selectedAgeGroups.toList() : null,
      );
      setState(() {
        _coaches = coaches;
        _isLoading = false;
      });
      // Scroll to results after a short delay to ensure the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToResults();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to search coaches: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _scrollToResults() {
    final context = _resultsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1, // Scroll to show results near the top
      );
    }
  }

  void _toggleTrait(String trait) {
    setState(() {
      if (_selectedTraits.contains(trait)) {
        _selectedTraits.remove(trait);
      } else {
        _selectedTraits.add(trait);
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
      _selectedTraits.clear();
      _selectedAgeGroups.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Coach'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter by Neurodiverse Traits
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter by Neurodiverse Traits',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedTraits.isNotEmpty)
                            TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select traits to find coaches who specialize in them',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _neurodiverseTraits.map((trait) {
                          final isSelected = _selectedTraits.contains(trait);
                          return FilterChip(
                            label: Text(trait),
                            selected: isSelected,
                            onSelected: (_) => _toggleTrait(trait),
                            selectedColor: theme.colorScheme.primaryContainer,
                            checkmarkColor:
                                theme.colorScheme.onPrimaryContainer,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Filter by Age Groups
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter by Age Groups',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select age groups to find coaches who work with them',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _ageGroups.map((ageGroup) {
                          final isSelected =
                              _selectedAgeGroups.contains(ageGroup);
                          return FilterChip(
                            label: Text(ageGroup),
                            selected: isSelected,
                            onSelected: (_) => _toggleAgeGroup(ageGroup),
                            selectedColor: theme.colorScheme.primaryContainer,
                            checkmarkColor:
                                theme.colorScheme.onPrimaryContainer,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Search by Postcode
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search by Postcode',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _postcodeController,
                        decoration: const InputDecoration(
                          hintText: 'Enter postcode',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _searchByPostcode(),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _searchByPostcode,
                          icon: const Icon(Icons.search),
                          label: const Text('Search by Postcode'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Search by Address
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search by Address',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          hintText: 'Enter address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _searchByAddress(),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _searchByAddress,
                          icon: const Icon(Icons.search),
                          label: const Text('Search by Address'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Search by Current Location
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use Current Location',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _searchByLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Find Nearby Coaches'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Search by Filters Only
              if (_selectedTraits.isNotEmpty || _selectedAgeGroups.isNotEmpty)
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search with Selected Filters',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_selectedTraits.isNotEmpty) ...[
                          Text(
                            'Traits: ${_selectedTraits.join(', ')}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                        if (_selectedAgeGroups.isNotEmpty) ...[
                          Text(
                            'Age Groups: ${_selectedAgeGroups.join(', ')}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : () => _searchCoaches(),
                            icon: const Icon(Icons.filter_alt),
                            label: const Text('Search with Filters'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),

              // Loading indicator
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),

              // Results
              if (_hasSearched && !_isLoading)
                Builder(
                  key: _resultsKey,
                  builder: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Results (${_coaches.length})',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_coaches.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No coaches found',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try a different search term',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._coaches.map((coach) => Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
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
                                onTap: () {
                                  context.push('/network/coaches/${coach.id}');
                                },
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // if (coach.name != null &&
                                    //     coach.bio!.isNotEmpty) ...[
                                    //   const SizedBox(height: 4),
                                    //   Text(
                                    //     coach.bio!,
                                    //     maxLines: 2,
                                    //     overflow: TextOverflow.ellipsis,
                                    //   ),
                                    // ],
                                    if (coach.postalCode != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            coach.postalCode!,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (coach.specialisms != null &&
                                        coach.specialisms!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        children: coach.specialisms!
                                            .take(3)
                                            .map((spec) {
                                          return Chip(
                                            label: Text(spec),
                                            labelStyle:
                                                theme.textTheme.bodySmall,
                                            padding: EdgeInsets.zero,
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                                // isThreeLine:
                                //     coach.bio != null && coach.bio!.isNotEmpty,
                              ),
                            )),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
