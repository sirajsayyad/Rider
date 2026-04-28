import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/routes.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/services/open_maps_service.dart' as osm;
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons/buttons.dart';
import '../../../../core/widgets/loaders/loaders.dart';
import '../application/route_controller.dart';
import '../widgets/ride_map_view.dart';
import '../../ride/application/ride_controller.dart';
import '../../ride/domain/ride_models.dart';
import 'location_picker_screen.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _pickupController = TextEditingController();
  final _pickupFocusNode = FocusNode();
  final _destinationController = TextEditingController();
  final _destinationFocusNode = FocusNode();
  Timer? _searchDebounce;

  bool _didInitLocation = false;
  bool _isResolvingDestination = false;
  bool _isFetchingCurrentLocation = false;

  final GlobalKey<RideMapViewState> _mapKey = GlobalKey<RideMapViewState>();
  List<_DestinationSuggestion> _suggestions = const [];

  _AssistanceChoice _assistanceChoice = _AssistanceChoice.none;



  @override
  void initState() {
    super.initState();
    final ride = ref.read(rideControllerProvider);
    _pickupController.text =
        ride.pickup?.address ?? '';
    _destinationController.text = ride.destination?.address ?? '';
    _suggestions = _buildLocalSuggestions(_destinationController.text, ride);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitLocation) return;
    _didInitLocation = true;
    Future.microtask(() async {
      final locationService = ref.read(locationServiceProvider);
      final controller = ref.read(rideControllerProvider.notifier);
      await controller.setPickupFromCurrentLocation(locationService);
      await controller.startLiveLocationTracking(locationService);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _pickupController.dispose();
    _pickupFocusNode.dispose();
    _destinationController.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(rideControllerProvider);
    final controller = ref.read(rideControllerProvider.notifier);
    final locationService = ref.read(locationServiceProvider);
    final routeState = ref.watch(routeControllerProvider);
    final routePreview = _RoutePreviewData.fromState(state, routeState);

    if (!_destinationFocusNode.hasFocus &&
        state.destination != null &&
        _destinationController.text != state.destination!.address) {
      _destinationController.text = state.destination!.address;
    }
    if (!_pickupFocusNode.hasFocus &&
        state.pickup != null &&
        _pickupController.text != state.pickup!.address) {
      _pickupController.text = state.pickup!.address;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Booking'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(Routes.paymentMethods),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: Text(_paymentText(state.paymentMethod)),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 136),
            children: [
              const _BookingPromoCarousel(),
              const SizedBox(height: AppSpacing.md),
              _GoogleMapCard(
                mapKey: _mapKey,
                pickup: state.pickup,
                destination: state.destination,
                routeInfo: routeState.routeInfo,
                isLoadingRoute: routeState.isLoading,
                onUseCurrentLocation: () =>
                    _loadCurrentLocation(updateDestination: false),
                onSetPickupOnMap: () => _openLocationPicker(isPickup: true),
                onSetDropOnMap: state.destination != null
                    ? () => _openLocationPicker(isPickup: false)
                    : null,
                onPickupDragEnd: (latLng) async {
                  final resolved =
                      await locationService.getAddressFromCoordinates(
                    latLng.latitude,
                    latLng.longitude,
                  );
                  controller.setPickup(RidePoint(
                    latitude: resolved.latitude,
                    longitude: resolved.longitude,
                    address: resolved.address ?? 'Dropped Pin',
                  ));
                  if (ref.read(rideControllerProvider).destination != null) {
                    await controller.loadQuotes();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _LocationFormCard(
                pickupController: _pickupController,
                destinationController: _destinationController,
                destinationFocusNode: _destinationFocusNode,
                isResolvingDestination: _isResolvingDestination,
                isFetchingCurrentLocation: _isFetchingCurrentLocation,
                suggestions: _suggestions,
                savedPlaces: state.savedPlaces,
                recentSearches: state.recentSearches,
                nearbyLandmarks: state.nearbyLandmarks,
                onDestinationChanged: _onDestinationChanged,
                onDestinationSubmitted: _resolveTypedDestination,
                onSelectSuggestion: _applySuggestion,
                onSelectSavedPlace: (place) =>
                    _applyResolvedDestination(place.point),
                onUseCurrentLocationForDestination: () =>
                    _loadCurrentLocation(updateDestination: true),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(Routes.scheduleRide),
                      icon: const Icon(Icons.schedule_rounded, size: 18),
                      label: const Text('Schedule'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Multi-stop implemented via map pins!')),
                        );
                      },
                      icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                      label: const Text('Add Stops'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (routePreview != null)
                _RouteSummaryCard(routePreview: routePreview)
              else
                const _HintCard(
                  text:
                      'Choose pickup and drop locations to preview the route, distance, ETA, and live fare estimates.',
                ),
              const SizedBox(height: AppSpacing.md),
              _PrivacyInfoCard(safetyState: state.safetyState),
              const SizedBox(height: AppSpacing.md),
              _PreferenceCard(
                preferences: state.preferences,
                onChanged: controller.updatePreferences,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fare estimates', style: theme.textTheme.titleMedium),
                  if (state.selectedQuote != null)
                    TextButton.icon(
                      onPressed: controller.lockFare,
                      icon: const Icon(Icons.lock_clock_outlined),
                      label: Text(
                        state.fareLock?.isActive == true
                            ? 'Fare Locked'
                            : 'Lock Fare',
                      ),
                    ),
                ],
              ),
              if (state.fareLock?.isActive == true)
                _FareLockBanner(fareLock: state.fareLock!),
              const SizedBox(height: AppSpacing.sm),
              if (state.isLoadingQuotes)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: SearchingDriverLoader(),
                )
              else if (routePreview == null)
                const _HintCard(
                  text:
                      'We will show ride types after you confirm both pickup and destination.',
                )
              else if (state.quotes.isEmpty)
                const _HintCard(
                  text:
                      'No fare estimate yet. Try a more specific destination or refresh your pickup.',
                )
              else
                ...state.quotes.map(
                  (quote) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _QuoteTile(
                      quote: quote,
                      selected: state.selectedQuote?.type == quote.type,
                      onTap: () => controller.selectQuote(quote),
                    ),
                  ),
                ),
              if (state.selectedQuote != null) ...[
                const SizedBox(height: AppSpacing.md),
                _FareBreakdownCard(quote: state.selectedQuote!),
                const SizedBox(height: AppSpacing.md),
                _NearbyDriversCard(drivers: state.nearbyDrivers),
              ],
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                MediaQuery.of(context).padding.bottom + AppSpacing.sm,
              ),
              child: PrimaryButton(
                text: state.selectedQuote == null
                    ? 'Confirm Pickup & Destination'
                    : 'Confirm Ride ${Formatters.currency(state.fareLock?.isActive == true ? state.fareLock!.lockedFare : state.selectedQuote!.fare)}',
                onPressed: state.selectedQuote == null
                    ? null
                    : () async {
                        await _confirmAssistanceAndRequestRide(controller);
                      },
                icon: Icons.local_taxi_outlined,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAssistanceAndRequestRide(
      RideController controller) async {
    final choice = await showModalBottomSheet<_AssistanceChoice>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssistanceSheet(selected: _assistanceChoice),
    );

    if (!mounted) return;
    if (choice == null) return;
    setState(() => _assistanceChoice = choice);

    final rideId = await controller.requestRide();
    if (rideId == null || !mounted) return;
    context.go('/passenger/tracking/$rideId');
  }

  void _onDestinationChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _fetchSuggestions(value);
    });
  }

  Future<void> _fetchSuggestions(String value) async {
    final ride = ref.read(rideControllerProvider);
    final localSuggestions = _buildLocalSuggestions(value, ride);

    // Immediately show local suggestions
    if (mounted) {
      setState(() => _suggestions = localSuggestions);
    }

    // Also fetch Google Places predictions (non-blocking)
    final mapsService = ref.read(osm.openMapsServiceProvider);
    if (mapsService.hasApiKey && value.trim().length >= 2) {
      final pickupLatLng = ride.pickup != null
          ? LatLng(ride.pickup!.latitude, ride.pickup!.longitude)
          : null;
      final predictions = await mapsService.getPlacePredictions(
        value.trim(),
        countryCode: 'in',
        location: pickupLatLng,
      );
      if (mounted && predictions.isNotEmpty && _destinationFocusNode.hasFocus) {
        final placeSuggestions = predictions.take(5).map((p) {
          return _DestinationSuggestion.placePrediction(p);
        }).toList();

        setState(() {
          // Merge: keep "Search X" first, then place results, then local
          final merged = <_DestinationSuggestion>[];
          if (localSuggestions.isNotEmpty &&
              localSuggestions.first.type == _SuggestionType.search) {
            merged.add(localSuggestions.first);
          }
          merged.addAll(placeSuggestions);
          for (final s in localSuggestions.skip(1)) {
            final alreadyExists = merged.any(
              (m) => m.subtitle.toLowerCase() == s.subtitle.toLowerCase(),
            );
            if (!alreadyExists) merged.add(s);
          }
          _suggestions = merged.take(8).toList();
        });
      }
    }
  }

  List<_DestinationSuggestion> _buildLocalSuggestions(
      String query, RideState ride) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final normalized = trimmed.toLowerCase();
    final suggestions = <_DestinationSuggestion>[
      _DestinationSuggestion.search(trimmed),
    ];

    void addUnique(_DestinationSuggestion suggestion) {
      final exists = suggestions.any(
        (item) =>
            item.title.toLowerCase() == suggestion.title.toLowerCase() &&
            item.subtitle.toLowerCase() == suggestion.subtitle.toLowerCase(),
      );
      if (!exists) suggestions.add(suggestion);
    }

    for (final place in ride.savedPlaces) {
      if (place.label.toLowerCase().contains(normalized) ||
          place.point.address.toLowerCase().contains(normalized)) {
        addUnique(_DestinationSuggestion.savedPlace(place));
      }
    }

    for (final point in ride.recentSearches) {
      if (point.address.toLowerCase().contains(normalized)) {
        addUnique(_DestinationSuggestion.recent(point));
      }
    }

    for (final landmark in ride.nearbyLandmarks) {
      if (landmark.toLowerCase().contains(normalized)) {
        addUnique(_DestinationSuggestion.landmark(landmark));
      }
    }



    return suggestions.take(6).toList();
  }

  Future<void> _applySuggestion(_DestinationSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    switch (suggestion.type) {
      case _SuggestionType.savedPlace:
      case _SuggestionType.recent:
        if (suggestion.point != null) {
          _destinationController.text = suggestion.point!.address;
          await _applyResolvedDestination(suggestion.point!);
        }
        break;
      case _SuggestionType.placePrediction:
        _destinationController.text = suggestion.query;
        await _resolvePlacePrediction(suggestion);
        break;
      case _SuggestionType.search:
      case _SuggestionType.landmark:
        _destinationController.text = suggestion.query;
        await _resolveTypedDestination(suggestion.query);
        break;
    }
  }

  Future<void> _resolvePlacePrediction(
      _DestinationSuggestion suggestion) async {
    if (suggestion.placeId == null || suggestion.placeId!.isEmpty) {
      await _resolveTypedDestination(suggestion.query);
      return;
    }

    setState(() => _isResolvingDestination = true);
    final mapsService = ref.read(osm.openMapsServiceProvider);
    final details = await mapsService.getPlaceDetails(suggestion.placeId!);
    if (!mounted) return;
    setState(() => _isResolvingDestination = false);

    if (details != null) {
      final point = RidePoint(
        latitude: details.latitude,
        longitude: details.longitude,
        address: details.formattedAddress,
      );
      _destinationController.text = details.formattedAddress;
      await _applyResolvedDestination(point);
    } else {
      // Fallback to text-based geocoding
      await _resolveTypedDestination(suggestion.query);
    }
  }

  Future<void> _resolveTypedDestination(String rawInput) async {
    final query = rawInput.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isResolvingDestination = true);
    final controller = ref.read(rideControllerProvider.notifier);
    final locationService = ref.read(locationServiceProvider);
    final mapsService = ref.read(osm.openMapsServiceProvider);
    final resolved = await controller.resolveDestination(
      query,
      locationService,
      mapsService: mapsService,
    );
    if (!mounted) return;
    setState(() => _isResolvingDestination = false);

    if (resolved == null) {
      // This shouldn't happen anymore, but keep as safety net
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not find that destination. Try a clearer address or landmark.'),
        ),
      );
      return;
    }

    _destinationController.text = resolved.address;
    await _applyResolvedDestination(resolved);
  }

  Future<void> _applyResolvedDestination(RidePoint destination) async {
    final controller = ref.read(rideControllerProvider.notifier);
    controller.setDestination(destination);
    controller.addRecentSearch(destination);
    await controller.loadQuotes();
    if (!mounted) return;
    setState(() {
      _suggestions = const [];
    });
  }

  Future<void> _loadCurrentLocation({required bool updateDestination}) async {
    setState(() => _isFetchingCurrentLocation = true);
    final controller = ref.read(rideControllerProvider.notifier);
    final locationService = ref.read(locationServiceProvider);
    final current = await locationService.getCurrentLocationWithAddress();
    if (!mounted) return;
    setState(() => _isFetchingCurrentLocation = false);

    if (current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Unable to access GPS. You can still set pickup manually on the map.'),
        ),
      );
      return;
    }

    final point = RidePoint(
      latitude: current.latitude,
      longitude: current.longitude,
      address: current.address ?? 'Current Location',
    );

    if (updateDestination) {
      _destinationController.text = point.address;
      await _applyResolvedDestination(point);
      return;
    }

    controller.setPickup(point);
    _mapKey.currentState?.animateToPosition(
      LatLng(point.latitude, point.longitude),
    );
    if (ref.read(rideControllerProvider).destination != null) {
      await controller.loadQuotes();
    }
  }

  Future<void> _openLocationPicker({required bool isPickup}) async {
    final state = ref.read(rideControllerProvider);
    LatLng? initial;
    if (isPickup && state.pickup != null) {
      initial = LatLng(state.pickup!.latitude, state.pickup!.longitude);
    } else if (!isPickup && state.destination != null) {
      initial =
          LatLng(state.destination!.latitude, state.destination!.longitude);
    }

    final result = await Navigator.of(context).push<RidePoint>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          isPickup: isPickup,
          initialPosition: initial,
        ),
      ),
    );

    if (result != null && mounted) {
      if (!isPickup) {
        _destinationController.text = result.address;
        await _applyResolvedDestination(result);
      } else {
        ref.read(rideControllerProvider.notifier).setPickup(result);
        if (ref.read(rideControllerProvider).destination != null) {
          await ref.read(rideControllerProvider.notifier).loadQuotes();
        }
      }
    }
  }

  String _paymentText(RiderPaymentMethod method) {
    switch (method) {
      case RiderPaymentMethod.cash:
        return 'Cash';
      case RiderPaymentMethod.upi:
        return 'UPI';
      case RiderPaymentMethod.card:
        return 'Card';
      case RiderPaymentMethod.wallet:
        return 'Wallet';
      case RiderPaymentMethod.corporate:
        return 'Corporate';
    }
  }
}

enum _AssistanceChoice {
  assistance,
  none,
}

class _AssistanceSheet extends StatelessWidget {
  final _AssistanceChoice selected;

  const _AssistanceSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.large,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Assistance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              'Choose assistance mode for this trip',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _AssistanceOptionTile(
              title: 'Assistance',
              subtitle: 'Share trip updates with support for faster help',
              selected: selected == _AssistanceChoice.assistance,
              icon: Icons.support_agent,
              onTap: () => Navigator.pop(context, _AssistanceChoice.assistance),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AssistanceOptionTile(
              title: 'No Assistance',
              subtitle: 'Continue normally',
              selected: selected == _AssistanceChoice.none,
              icon: Icons.shield_outlined,
              onTap: () => Navigator.pop(context, _AssistanceChoice.none),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _AssistanceOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _AssistanceOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(isDark ? 0.22 : 0.12)
                : (isDark ? AppColors.darkCard : AppColors.lightCard),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark ? Colors.white12 : Colors.black12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingPromoCarousel extends StatefulWidget {
  const _BookingPromoCarousel();

  @override
  State<_BookingPromoCarousel> createState() => _BookingPromoCarouselState();
}

class _BookingPromoCarouselState extends State<_BookingPromoCarousel> {
  late final PageController _controller;
  int _index = 0;

  static const _items = <Map<String, String>>[
    {
      'title': 'Fast pickup',
      'subtitle': 'Smarter matching for quicker arrivals',
      'imageUrl':
          'https://images.unsplash.com/photo-1493238792000-8113da705763?auto=format&fit=crop&w=1600&q=80',
    },
    {
      'title': 'Safer rides',
      'subtitle': 'SOS and live-sharing built in',
      'imageUrl':
          'https://images.unsplash.com/photo-1520975958225-635a3b1b59b9?auto=format&fit=crop&w=1600&q=80',
    },
    {
      'title': 'Better fares',
      'subtitle': 'Transparent breakdown before you book',
      'imageUrl':
          'https://images.unsplash.com/photo-1518544801976-3e159e50e5bb?auto=format&fit=crop&w=1600&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: PageView.builder(
              controller: _controller,
              itemCount: _items.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final item = _items[index];
                final title = item['title'] ?? '';
                final subtitle = item['subtitle'] ?? '';
                final imageUrl = item['imageUrl'] ?? '';

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const _PromoShimmer(),
                      errorWidget: (context, url, error) => Container(
                        color:
                            isDark ? AppColors.darkCard : AppColors.lightCard,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.65),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_items.length, (i) {
            final selected = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: selected ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoShimmer extends StatelessWidget {
  const _PromoShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: base.withOpacity(0.6),
      child: Container(color: base),
    );
  }
}

class _GoogleMapCard extends StatelessWidget {
  const _GoogleMapCard({
    required this.mapKey,
    required this.pickup,
    required this.destination,
    required this.routeInfo,
    required this.isLoadingRoute,
    required this.onUseCurrentLocation,
    required this.onSetPickupOnMap,
    required this.onSetDropOnMap,
    required this.onPickupDragEnd,
  });

  final GlobalKey<RideMapViewState> mapKey;
  final RidePoint? pickup;
  final RidePoint? destination;
  final osm.RouteInfo? routeInfo;
  final bool isLoadingRoute;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onSetPickupOnMap;
  final VoidCallback? onSetDropOnMap;
  final ValueChanged<LatLng> onPickupDragEnd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.large,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 280,
              child: Stack(
                children: [
                  RideMapView(
                    key: mapKey,
                    pickupLatLng: pickup != null
                        ? LatLng(pickup!.latitude, pickup!.longitude)
                        : null,
                    dropLatLng: destination != null
                        ? LatLng(destination!.latitude, destination!.longitude)
                        : null,
                    routeInfo: routeInfo,
                    isPickupDraggable: true,
                    onPickupDragEnd: onPickupDragEnd,
                    showMyLocationButton: false,
                  ),
                  // Route loading indicator
                  if (isLoadingRoute)
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.black : Colors.white)
                                .withOpacity(0.86),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            boxShadow: AppShadows.small,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Fetching route...',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Action chips over the map
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MapModeChip(
                          icon: Icons.gps_fixed_rounded,
                          label: 'Current Location',
                          onTap: onUseCurrentLocation,
                        ),
                        _MapModeChip(
                          icon: Icons.edit_location_alt_outlined,
                          label: 'Set Pickup on Map',
                          onTap: onSetPickupOnMap,
                        ),
                        if (onSetDropOnMap != null)
                          _MapModeChip(
                            icon: Icons.pin_drop_outlined,
                            label: 'Adjust Drop',
                            onTap: onSetDropOnMap!,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationFormCard extends StatelessWidget {
  const _LocationFormCard({
    required this.pickupController,
    required this.destinationController,
    required this.destinationFocusNode,
    required this.isResolvingDestination,
    required this.isFetchingCurrentLocation,
    required this.suggestions,
    required this.savedPlaces,
    required this.recentSearches,
    required this.nearbyLandmarks,
    required this.onDestinationChanged,
    required this.onDestinationSubmitted,
    required this.onSelectSuggestion,
    required this.onSelectSavedPlace,
    required this.onUseCurrentLocationForDestination,
  });

  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final FocusNode destinationFocusNode;
  final bool isResolvingDestination;
  final bool isFetchingCurrentLocation;
  final List<_DestinationSuggestion> suggestions;
  final List<SavedPlace> savedPlaces;
  final List<RidePoint> recentSearches;
  final List<String> nearbyLandmarks;
  final ValueChanged<String> onDestinationChanged;
  final ValueChanged<String> onDestinationSubmitted;
  final ValueChanged<_DestinationSuggestion> onSelectSuggestion;
  final ValueChanged<SavedPlace> onSelectSavedPlace;
  final VoidCallback onUseCurrentLocationForDestination;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTag(
              icon: Icons.pin_drop_outlined, text: 'Location details'),
          const SizedBox(height: AppSpacing.md),
          _InputShell(
            icon: Icons.my_location_outlined,
            iconColor: AppColors.pickupMarker,
            child: TextField(
              controller: pickupController,
              readOnly: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Pickup location',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InputShell(
            icon: Icons.search_rounded,
            iconColor: AppColors.dropMarker,
            child: TextField(
              controller: destinationController,
              focusNode: destinationFocusNode,
              onChanged: onDestinationChanged,
              onSubmitted: onDestinationSubmitted,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter drop location',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: isFetchingCurrentLocation
                          ? null
                          : onUseCurrentLocationForDestination,
                      icon: const Icon(Icons.my_location_rounded),
                      tooltip: 'Use current location as drop',
                    ),
                    if (isResolvingDestination)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.arrow_forward_rounded),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Search destination, choose saved places, or use GPS fallback if location access fails.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (savedPlaces.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Saved places', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: savedPlaces
                  .map(
                    (place) => ActionChip(
                      avatar: Icon(
                        place.label.toLowerCase() == 'home'
                            ? Icons.home_outlined
                            : Icons.work_outline,
                        size: 18,
                      ),
                      label: Text(place.label),
                      onPressed: () => onSelectSavedPlace(place),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SuggestionPanel(
              title: 'Search suggestions',
              suggestions: suggestions,
              onSelect: onSelectSuggestion,
            ),
          ],
          if (recentSearches.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _CompactPointsSection(
              title: 'Recent searches',
              icon: Icons.history_rounded,
              points: recentSearches.take(4).toList(),
              onTap: (point) =>
                  onSelectSuggestion(_DestinationSuggestion.recent(point)),
            ),
          ],
          if (nearbyLandmarks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _NearbyLandmarksSection(
              landmarks: nearbyLandmarks.take(4).toList(),
              onTap: (landmark) =>
                  onSelectSuggestion(_DestinationSuggestion.landmark(landmark)),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({
    required this.routePreview,
  });

  final _RoutePreviewData routePreview;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTag(
              icon: Icons.alt_route_rounded, text: 'Route preview'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.straighten_rounded,
                  title: 'Distance',
                  value: routePreview.distanceText,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricTile(
                  icon: Icons.schedule_rounded,
                  title: 'ETA',
                  value: routePreview.durationText,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: _MetricTile(
                  icon: Icons.route_outlined,
                  title: 'Route',
                  value: 'Live',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _RouteAddressLine(
            icon: Icons.my_location_outlined,
            color: AppColors.pickupMarker,
            text: routePreview.pickupAddress,
          ),
          const SizedBox(height: AppSpacing.sm),
          _RouteAddressLine(
            icon: Icons.location_on_outlined,
            color: AppColors.dropMarker,
            text: routePreview.destinationAddress,
          ),
        ],
      ),
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({
    required this.title,
    required this.suggestions,
    required this.onSelect,
  });

  final String title;
  final List<_DestinationSuggestion> suggestions;
  final ValueChanged<_DestinationSuggestion> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
          ),
          ...suggestions.map(
            (suggestion) => ListTile(
              dense: true,
              leading: Icon(_iconForSuggestion(suggestion.type),
                  color: AppColors.primary),
              title: Text(suggestion.title),
              subtitle: Text(
                suggestion.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onSelect(suggestion),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForSuggestion(_SuggestionType type) {
    switch (type) {
      case _SuggestionType.search:
        return Icons.search_rounded;
      case _SuggestionType.savedPlace:
        return Icons.bookmark_outline_rounded;
      case _SuggestionType.recent:
        return Icons.history_rounded;
      case _SuggestionType.landmark:
        return Icons.place_outlined;
      case _SuggestionType.placePrediction:
        return Icons.location_on_outlined;
    }
  }
}

class _CompactPointsSection extends StatelessWidget {
  const _CompactPointsSection({
    required this.title,
    required this.icon,
    required this.points,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final List<RidePoint> points;
  final ValueChanged<RidePoint> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        ...points.map(
          (point) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(icon, size: 18, color: AppColors.primary),
            title: Text(
              point.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onTap(point),
          ),
        ),
      ],
    );
  }
}

class _NearbyLandmarksSection extends StatelessWidget {
  const _NearbyLandmarksSection({
    required this.landmarks,
    required this.onTap,
  });

  final List<String> landmarks;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nearby landmarks', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: landmarks
              .map(
                (landmark) => ActionChip(
                  avatar: const Icon(Icons.place_outlined, size: 16),
                  label: Text(landmark),
                  onPressed: () => onTap(landmark),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _InputShell extends StatelessWidget {
  const _InputShell({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MapModeChip extends StatelessWidget {
  const _MapModeChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      backgroundColor: Colors.white.withOpacity(0.95),
      labelStyle: const TextStyle(
        color: AppColors.lightText,
        fontWeight: FontWeight.w700,
      ),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

// _MarkerBubble removed – markers are handled natively by Google Maps.

// _InteractiveMapPainter removed – replaced by real Google Maps integration.

class _RouteAddressLine extends StatelessWidget {
  const _RouteAddressLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PrivacyInfoCard extends StatelessWidget {
  const _PrivacyInfoCard({required this.safetyState});

  final SafetyState safetyState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTag(
              icon: Icons.verified_user_outlined, text: 'Privacy and GPS'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            safetyState.privacyModeEnabled
                ? 'Approximate pickup is shown before assignment. Exact location is protected until the ride starts or you allow precise sharing.'
                : 'Exact pickup details may be shared sooner for faster matching.',
          ),
          if (safetyState.lastLocationUpdatedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'GPS updated ${Formatters.relativeTime(safetyState.lastLocationUpdatedAt!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({
    required this.preferences,
    required this.onChanged,
  });

  final RidePreferences preferences;
  final void Function({
    bool? acRide,
    bool? silentRide,
    bool? musicOn,
    bool? femaleOnly,
    bool? petFriendly,
  }) onChanged;

  @override
  Widget build(BuildContext context) {
    final chips =
        <({String label, bool selected, VoidCallback onTap, IconData icon})>[
      (
        label: preferences.acRide ? 'AC Ride' : 'Non-AC',
        selected: preferences.acRide,
        onTap: () => onChanged(acRide: !preferences.acRide),
        icon: Icons.ac_unit,
      ),
      (
        label: 'Silent Ride',
        selected: preferences.silentRide,
        onTap: () => onChanged(silentRide: !preferences.silentRide),
        icon: Icons.volume_off_outlined,
      ),
      (
        label: 'Music',
        selected: preferences.musicOn,
        onTap: () => onChanged(musicOn: !preferences.musicOn),
        icon: Icons.music_note_outlined,
      ),
      (
        label: 'Female Driver',
        selected: preferences.womenOnly,
        onTap: () => onChanged(femaleOnly: !preferences.womenOnly),
        icon: Icons.woman_rounded,
      ),
      (
        label: 'Pet Friendly',
        selected: preferences.petFriendly,
        onTap: () => onChanged(petFriendly: !preferences.petFriendly),
        icon: Icons.pets_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTag(icon: Icons.tune_rounded, text: 'Ride preferences'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (chip) => FilterChip(
                    selected: chip.selected,
                    onSelected: (_) => chip.onTap(),
                    avatar: Icon(chip.icon, size: 18),
                    label: Text(chip.label),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _FareLockBanner extends StatelessWidget {
  const _FareLockBanner({required this.fareLock});
  final FareLock fareLock;

  @override
  Widget build(BuildContext context) {
    final remaining =
        fareLock.expiresAt.difference(DateTime.now()).inMinutes.clamp(0, 5);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_outlined, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Fare locked at ${Formatters.currency(fareLock.lockedFare)} for $remaining more min.',
            ),
          ),
        ],
      ),
    );
  }
}

class _FareBreakdownCard extends StatelessWidget {
  const _FareBreakdownCard({required this.quote});
  final RideTypeQuote quote;

  @override
  Widget build(BuildContext context) {
    final breakdown = quote.breakdown;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTag(
              icon: Icons.receipt_long_outlined, text: 'Fare breakdown'),
          const SizedBox(height: AppSpacing.sm),
          _fareRow('Base fare', breakdown.baseFare),
          _fareRow('Distance', breakdown.distanceFare),
          _fareRow('Time', breakdown.timeFare),
          _fareRow('Surge x${breakdown.surgeMultiplier.toStringAsFixed(2)}',
              breakdown.surgeAmount),
          _fareRow('Platform fee', breakdown.platformFee),
          _fareRow('Tax', breakdown.tax),
          const Divider(height: 22),
          _fareRow('Total', breakdown.total, bold: true),
        ],
      ),
    );
  }

  Widget _fareRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            Formatters.currency(amount),
            style:
                TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _NearbyDriversCard extends StatelessWidget {
  const _NearbyDriversCard({required this.drivers});
  final List<NearbyDriverPreview> drivers;

  @override
  Widget build(BuildContext context) {
    if (drivers.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTag(
              icon: Icons.near_me_outlined, text: 'Nearest available drivers'),
          const SizedBox(height: AppSpacing.sm),
          ...drivers.map(
            (driver) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(driver.name[0]),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${driver.vehicleModel} | ${driver.etaMinutes} min | ${driver.distanceKm.toStringAsFixed(1)} km',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text('${(driver.acceptanceRate * 100).round()}% accept'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(text),
    );
  }
}

class _QuoteTile extends StatelessWidget {
  const _QuoteTile({
    required this.quote,
    required this.selected,
    required this.onTap,
  });

  final RideTypeQuote quote;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(_iconForType(quote.type), color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quote.label,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    '${quote.subtitle} | ${quote.availableDrivers} drivers nearby',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(quote.fare),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text('${quote.etaMinutes} min'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(RideType type) {
    switch (type) {
      case RideType.economy:
        return Icons.directions_car_outlined;
      case RideType.premium:
        return Icons.local_taxi_outlined;
      case RideType.bike:
        return Icons.two_wheeler_outlined;
      case RideType.suv:
        return Icons.airport_shuttle_outlined;
      case RideType.pool:
        return Icons.group_outlined;
    }
  }
}

class _SectionTag extends StatelessWidget {
  const _SectionTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _RoutePreviewData {
  const _RoutePreviewData({
    required this.distanceKm,
    required this.etaMinutes,
    required this.distanceText,
    required this.durationText,
    required this.pickupAddress,
    required this.destinationAddress,
  });

  final double distanceKm;
  final int etaMinutes;
  final String distanceText;
  final String durationText;
  final String pickupAddress;
  final String destinationAddress;

  static _RoutePreviewData? fromState(RideState state, RouteState routeState) {
    final pickup = state.pickup;
    final destination = state.destination;
    if (pickup == null || destination == null) return null;

    // Prefer real route data from Google Directions when available
    if (routeState.routeInfo != null) {
      return _RoutePreviewData(
        distanceKm: routeState.routeInfo!.distanceKm,
        etaMinutes: routeState.routeInfo!.durationMinutes,
        distanceText: routeState.routeInfo!.distanceText,
        durationText: routeState.routeInfo!.durationText,
        pickupAddress: pickup.address,
        destinationAddress: destination.address,
      );
    }

    // Fallback: rough calculation
    final latDiff = destination.latitude - pickup.latitude;
    final lngDiff = destination.longitude - pickup.longitude;
    final distanceKm = math.max(
      1.0,
      math.sqrt((latDiff * latDiff) + (lngDiff * lngDiff)) * 111,
    );
    final quoteEta =
        state.selectedQuote?.etaMinutes ?? state.quotes.firstOrNull?.etaMinutes;
    final eta = quoteEta ?? math.max(6, (distanceKm * 2.8).round());
    return _RoutePreviewData(
      distanceKm: distanceKm,
      etaMinutes: eta,
      distanceText: '${distanceKm.toStringAsFixed(1)} km',
      durationText: '$eta min',
      pickupAddress: pickup.address,
      destinationAddress: destination.address,
    );
  }
}

enum _SuggestionType {
  search,
  savedPlace,
  recent,
  landmark,
  placePrediction,
}

class _DestinationSuggestion {
  const _DestinationSuggestion({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.query,
    this.point,
    this.placeId,
  });

  final _SuggestionType type;
  final String title;
  final String subtitle;
  final String query;
  final RidePoint? point;
  final String? placeId;

  factory _DestinationSuggestion.search(String query) {
    return _DestinationSuggestion(
      type: _SuggestionType.search,
      title: 'Search "$query"',
      subtitle: 'Use this destination',
      query: query,
    );
  }

  factory _DestinationSuggestion.savedPlace(SavedPlace place) {
    return _DestinationSuggestion(
      type: _SuggestionType.savedPlace,
      title: place.label,
      subtitle: place.point.address,
      query: place.point.address,
      point: place.point,
    );
  }

  factory _DestinationSuggestion.recent(RidePoint point) {
    return _DestinationSuggestion(
      type: _SuggestionType.recent,
      title: 'Recent',
      subtitle: point.address,
      query: point.address,
      point: point,
    );
  }

  factory _DestinationSuggestion.landmark(String landmark) {
    return _DestinationSuggestion(
      type: _SuggestionType.landmark,
      title: 'Nearby landmark',
      subtitle: landmark,
      query: landmark,
    );
  }


  factory _DestinationSuggestion.placePrediction(osm.PlacePrediction prediction) {
    return _DestinationSuggestion(
      type: _SuggestionType.placePrediction,
      title: prediction.mainText,
      subtitle: prediction.secondaryText,
      query: prediction.description,
      placeId: prediction.placeId,
    );
  }
}
