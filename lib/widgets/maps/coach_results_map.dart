import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/models/coach.dart';
import 'package:projectbrain/models/location.dart';
import 'package:projectbrain/services/google_maps_native_service.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

class CoachResultsMap extends StatefulWidget {
  final List<Coach> coaches;
  final SearchCenter? searchOrigin;
  final int? searchRadiusMiles;
  final ValueChanged<String>? onSelectCoach;
  final double height;

  const CoachResultsMap({
    super.key,
    required this.coaches,
    this.searchOrigin,
    this.searchRadiusMiles,
    this.onSelectCoach,
    this.height = 420,
  });

  @override
  State<CoachResultsMap> createState() => _CoachResultsMapState();
}

class _CoachResultsMapState extends State<CoachResultsMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  bool _nativeMapsReady = false;
  bool _nativeMapsFailed = false;

  static const double _minZoom = 3;
  static const double _maxZoom = 20;

  @override
  void initState() {
    super.initState();
    _rebuildMapOverlays();
    _ensureNativeMapsReady();
  }

  Future<void> _ensureNativeMapsReady() async {
    final apiKey = AppConfig.googleMapsApiKey;
    if (apiKey.isEmpty) {
      if (!mounted) return;
      setState(() => _nativeMapsFailed = true);
      return;
    }

    await GoogleMapsNativeService.configureApiKey(apiKey);
    if (!mounted) return;
    setState(() {
      _nativeMapsReady = true;
      _nativeMapsFailed = false;
    });
  }

  @override
  void didUpdateWidget(covariant CoachResultsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coaches != widget.coaches ||
        oldWidget.searchOrigin != widget.searchOrigin ||
        oldWidget.searchRadiusMiles != widget.searchRadiusMiles) {
      _rebuildMapOverlays();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  List<Coach> get _mappableCoaches =>
      widget.coaches.where((coach) => coach.hasCoordinates).toList();

  void _rebuildMapOverlays() {
    final markers = <Marker>{};
    final circles = <Circle>{};

    for (final coach in _mappableCoaches) {
      markers.add(
        Marker(
          markerId: MarkerId(coach.profileId),
          position: LatLng(coach.latitude!, coach.longitude!),
          infoWindow: InfoWindow(
            title: coach.fullName,
            snippet: [coach.city, coach.country]
                .whereType<String>()
                .where((part) => part.isNotEmpty)
                .join(', '),
            onTap: widget.onSelectCoach == null
                ? null
                : () => widget.onSelectCoach!(coach.profileId),
          ),
          onTap: widget.onSelectCoach == null
              ? null
              : () => widget.onSelectCoach!(coach.profileId),
        ),
      );
    }

    final origin = widget.searchOrigin;
    if (origin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('search-origin'),
          position: LatLng(origin.latitude, origin.longitude),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Search origin'),
          zIndexInt: 999,
        ),
      );

      final radiusMiles = widget.searchRadiusMiles;
      if (radiusMiles != null && radiusMiles > 0) {
        circles.add(
          Circle(
            circleId: const CircleId('search-radius'),
            center: LatLng(origin.latitude, origin.longitude),
            radius: radiusMiles * 1609.344,
            fillColor: const Color(0x332563EB),
            strokeColor: const Color(0xFF2563EB),
            strokeWidth: 2,
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _circles = circles;
    });

    _fitBounds();
  }

  Future<void> _fitBounds() async {
    final controller = _mapController;
    if (controller == null) return;

    final points = <LatLng>[];
    for (final coach in _mappableCoaches) {
      points.add(LatLng(coach.latitude!, coach.longitude!));
    }
    final origin = widget.searchOrigin;
    if (origin != null) {
      points.add(LatLng(origin.latitude, origin.longitude));
    }

    if (points.isEmpty) return;

    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 12),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
    final zoom = await controller.getZoomLevel();
    if (zoom > 14) {
      await controller.animateCamera(CameraUpdate.zoomTo(14));
    }
  }

  Future<void> _zoomBy(double delta) async {
    final controller = _mapController;
    if (controller == null) return;

    final currentZoom = await controller.getZoomLevel();
    final nextZoom = (currentZoom + delta).clamp(_minZoom, _maxZoom);
    await controller.animateCamera(CameraUpdate.zoomTo(nextZoom));
  }

  Widget _buildMapSurface() {
    return ClipRRect(
      borderRadius: AppRadius.circularMd,
      child: Stack(
        children: [
          GoogleMap(
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            initialCameraPosition: CameraPosition(
              target: widget.searchOrigin != null
                  ? LatLng(
                      widget.searchOrigin!.latitude,
                      widget.searchOrigin!.longitude,
                    )
                  : _mappableCoaches.isNotEmpty
                      ? LatLng(
                          _mappableCoaches.first.latitude!,
                          _mappableCoaches.first.longitude!,
                        )
                      : const LatLng(51.5072, -0.1276),
              zoom: 8,
            ),
            markers: _markers,
            circles: _circles,
            mapType: MapType.normal,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _fitBounds();
            },
          ),
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: _buildZoomControls(Theme.of(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: widget.height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildZoomControls(ThemeData theme) {
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    return Material(
      elevation: 2,
      borderRadius: AppRadius.circularSm,
      color: surface.withValues(alpha: 0.95),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Zoom in',
            icon: Icon(Icons.add, color: onSurface),
            onPressed: () => _zoomBy(1),
          ),
          const Divider(height: 1),
          IconButton(
            tooltip: 'Zoom out',
            icon: Icon(Icons.remove, color: onSurface),
            onPressed: () => _zoomBy(-1),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = AppConfig.googleMapsApiKey;
    if (apiKey.isEmpty) {
      return _buildMessageCard(
        context,
        'Missing GOOGLE_MAPS_API_KEY (required for map view).',
      );
    }

    if (_nativeMapsFailed) {
      return _buildMessageCard(
        context,
        'Google Maps could not be initialized on this device.',
      );
    }

    if (!_nativeMapsReady) {
      return _buildLoadingState();
    }

    final missingCoordsCount = widget.coaches.length - _mappableCoaches.length;

    final mapSurface = _buildMapSurface();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (missingCoordsCount > 0)
          Container(
            margin: AppInsets.listItemBottom,
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: AppRadius.circularSm,
            ),
            child: Text(
              '$missingCoordsCount coach${missingCoordsCount == 1 ? '' : 'es'} '
              'without map coordinates are hidden on the map.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        SizedBox(height: widget.height, child: mapSurface),
      ],
    );
  }

  Widget _buildMessageCard(BuildContext context, String message) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      padding: AppInsets.screen,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.circularMd,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
