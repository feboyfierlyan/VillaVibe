import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:villavibe/features/auth/presentation/widgets/login_modal.dart';
import 'package:villavibe/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:villavibe/features/properties/domain/models/property.dart';
import 'package:villavibe/features/properties/data/repositories/property_repository.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:villavibe/features/auth/data/repositories/auth_repository.dart';

import 'dart:async';
import 'package:villavibe/core/presentation/widgets/three_dots_loader.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:villavibe/features/bookings/domain/models/booking.dart';
import 'package:villavibe/features/bookings/data/repositories/booking_repository.dart';
import 'package:villavibe/features/guest/presentation/widgets/guest_calendar_view.dart';
import 'package:villavibe/features/messages/presentation/providers/chat_providers.dart';

class VillaDetailScreen extends ConsumerStatefulWidget {
  final Property property;
  final String? heroTagPrefix;

  const VillaDetailScreen({
    super.key,
    required this.property,
    this.heroTagPrefix,
  });

  @override
  ConsumerState<VillaDetailScreen> createState() => _VillaDetailScreenState();
}

class _VillaDetailScreenState extends ConsumerState<VillaDetailScreen> {
  bool _isLoading = true;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    // Simulate network delay for premium feel
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch for updates, but use passed property as initial data
    final propertyAsync = ref.watch(propertyProvider(widget.property.id));
    final authState = ref.watch(authStateProvider);
    // Ensure current user data is loaded
    ref.watch(currentUserProvider);

    // Use the latest data if available, otherwise use the passed property
    final currentProperty = propertyAsync.value ?? widget.property;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildContent(context, currentProperty),
      bottomNavigationBar: _buildBottomBar(
        context,
        currentProperty,
        authState.maybeWhen(
          data: (user) => user != null,
          orElse: () => false,
        ),
      ),
    );
  }

  // ... (existing code)



  Widget _buildContent(BuildContext context, Property property) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildSliverAppBar(context, property),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24), // Standard top padding
                    _buildHeader(property), // Instant Header
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _isLoading
                          ? Container(
                              key: const ValueKey('loader'),
                              height: 200,
                              alignment: Alignment.center,
                              child: const ThreeDotsLoader(size: 10),
                            )
                          : Column(
                              key: const ValueKey('content'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 1),
                                const SizedBox(height: 24),
                                _buildHostSection(property),
                                const Divider(height: 48),
                                _buildHighlights(property),
                                const Divider(height: 48),
                                _buildDescription(property),
                                const Divider(height: 48),
                                _buildAmenities(property),
                                const Divider(height: 48),
                                _buildReviewsSection(property),
                                const Divider(height: 48),
                                _buildMeetYourHost(property),
                                const Divider(height: 48),
                                _buildAvailability(property),
                                const Divider(height: 48),
                                _buildThingsToKnow(property),
                                const Divider(height: 48),
                                _buildLocation(property),
                                const SizedBox(height: 32),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        _buildFixedHeaderIcons(context, property),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Property property) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: '${widget.heroTagPrefix ?? ''}villa_img_${property.id}',
          flightShuttleBuilder: (
            BuildContext flightContext,
            Animation<double> animation,
            HeroFlightDirection flightDirection,
            BuildContext fromHeroContext,
            BuildContext toHeroContext,
          ) {
            return Material(
              type: MaterialType.transparency,
              child: property.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: property.images.first,
                      fit: BoxFit.cover,
                      memCacheWidth: 1000,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => Container(color: Colors.grey[200]),
                    )
                  : Container(color: Colors.grey[200]),
            );
          },
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.antiAlias,
              children: [
                property.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: property.images.first,
                        fit: BoxFit.cover,
                        memCacheWidth: 1000, // Optimize memory usage
                        fadeInDuration: Duration.zero,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child:
                              const Icon(LucideIcons.image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child:
                            const Icon(LucideIcons.image, color: Colors.grey),
                      ),
                if (property.images.isNotEmpty)
                  Positioned(
                    bottom: 40 + 32, // Adjusted for the bottom rounded cap
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '1/${property.images.length}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                // Fake Cap for Hero Transition Smoothness
                Positioned(
                  bottom: -1, // Slight overlap to prevent gaps
                  left: 0,
                  right: 0,
                  height: 33, // +1px to ensure full coverage
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(32),
        child: Container(
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedHeaderIcons(BuildContext context, Property property) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft,
                      color: Colors.black, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ).animate().fadeIn(delay: 200.ms),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(LucideIcons.share,
                          color: Colors.black, size: 20),
                      onPressed: () {},
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: FavoriteButton(
                      villaId: property.id,
                      color: Colors.black,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(width: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          property.name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: Color(0xFF212121), // Dark Grey
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            String displayAddress = property.address;
            // Check if address looks like coordinates (e.g. "-8.409, 115.188")
            final isCoordinates = RegExp(r'^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$').hasMatch(property.address);
            if (isCoordinates) {
              displayAddress = 'Bali';
            }
            
            return Text(
              '${property.setting.isNotEmpty ? property.setting : 'Entire rental unit'} in $displayAddress',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            );
          }
        ),
        const SizedBox(height: 4),
        Text(
          '${property.specs.maxGuests} guests · ${property.specs.bedrooms} bedroom · ${property.specs.bedrooms} bed · ${property.specs.bathrooms} bath${property.landSize > 0 ? ' · ${property.landSize.toStringAsFixed(0)} m²' : ''}',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(LucideIcons.star, size: 16, color: Colors.black),
            const SizedBox(width: 4),
            Text(
              '${property.rating} · ${property.reviewsCount} reviews',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHostSection(Property property) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: property.hostAvatar.isNotEmpty
              ? NetworkImage(property.hostAvatar)
              : null,
          child: property.hostAvatar.isEmpty && property.hostName.isNotEmpty
              ? Text(property.hostName[0])
              : const Icon(LucideIcons.user, size: 24, color: Colors.grey),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hosted by ${property.hostName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${property.hostYearsHosting} years hosting',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlights(Property property) {
    return Column(
      children: [
        if (property.architectureStyle.isNotEmpty) ...[
          _buildHighlightItem(
            LucideIcons.home,
            property.architectureStyle,
            'Designed with a unique architectural style.',
          ),
          const SizedBox(height: 24),
        ],
        if (property.vibe.isNotEmpty) ...[
          _buildHighlightItem(
            LucideIcons.sparkles,
            property.vibe,
            'This property is known for its ${property.vibe.toLowerCase()} vibe.',
          ),
          const SizedBox(height: 24),
        ],
        if (property.privacyLevel.isNotEmpty) ...[
          _buildHighlightItem(
            LucideIcons.shield,
            property.privacyLevel,
            'Enjoy your stay with ${property.privacyLevel.toLowerCase()}.',
          ),
          const SizedBox(height: 24),
        ],
        if (property.amenities.any((a) => a.toLowerCase().contains('pool'))) ...[
          _buildHighlightItem(
            LucideIcons.waves,
            'Dive right in',
            'This is one of the few places in the area with a pool.',
          ),
          const SizedBox(height: 24),
        ],
        if (property.rating >= 4.8) ...[
          _buildHighlightItem(
            LucideIcons.key,
            'Exceptional check-in experience',
            'Recent guests gave the check-in process a 5-star rating.',
          ),
        ],
      ],
    );
  }

  Widget _buildHighlightItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.black87),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F7F7),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Some info has been automatically translated.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Show original',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          property.description,
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _showDescriptionModal(context, property.description),
          child: const Row(
            children: [
              Text(
                'Show more',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              SizedBox(width: 4),
              Icon(LucideIcons.chevronRight, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  void _showDescriptionModal(BuildContext context, String description) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'About this place',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenities(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What this place offers',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 24),
        ...property.amenities.take(5).map((amenity) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(_getAmenityIcon(amenity),
                      size: 24, color: Colors.black87),
                  const SizedBox(width: 16),
                  Text(
                    amenity,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showAmenitiesModal(context, property.amenities),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.black),
            ),
            child: Text(
              'Show all ${property.amenities.length} amenities',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAmenitiesModal(BuildContext context, List<String> amenities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Amenities',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: amenities.length,
                separatorBuilder: (context, index) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final amenity = amenities[index];
                  return Row(
                    children: [
                      Icon(_getAmenityIcon(amenity), size: 32, color: Colors.black54),
                      const SizedBox(width: 16),
                      Text(
                        amenity,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return LucideIcons.wifi;
      case 'pool':
        return LucideIcons.waves;
      case 'kitchen':
        return LucideIcons.utensils;
      case 'gym':
        return LucideIcons.dumbbell;
      case 'ac':
        return LucideIcons.wind; // Approximate for AC
      case 'workspace':
        return LucideIcons.monitor;
      case 'garden':
        return LucideIcons.flower; // Approximate for Garden
      case 'breakfast':
        return LucideIcons.coffee;
      default:
        return LucideIcons.checkCircle;
    }
  }

  Widget _buildReviewsSection(Property property) {
    if (property.reviews.isEmpty) return const SizedBox.shrink();

    final firstReview = property.reviews.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.star, size: 20, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              '${property.rating} · ${property.reviewsCount} reviews',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: firstReview.authorAvatar.isNotEmpty
                        ? NetworkImage(firstReview.authorAvatar)
                        : null,
                    child: firstReview.authorAvatar.isEmpty
                        ? const Icon(LucideIcons.user,
                            size: 20, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstReview.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Verified User',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ...List.generate(
                      5,
                      (index) => const Icon(LucideIcons.star,
                          size: 14, color: Colors.black)),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM yyyy').format(firstReview.date),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                firstReview.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Show more',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showAllReviewsModal(context, property.reviews),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.black),
            ),
            child: Text(
              'Show all ${property.reviewsCount} reviews',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAllReviewsModal(BuildContext context, List<Review> reviews) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Reviews',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: reviews.length,
                separatorBuilder: (context, index) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: review.authorAvatar.isNotEmpty
                                ? NetworkImage(review.authorAvatar)
                                : null,
                            child: review.authorAvatar.isEmpty
                                ? const Icon(LucideIcons.user,
                                    size: 20, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.authorName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(review.date),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(
                            5,
                            (index) => const Icon(LucideIcons.star,
                                size: 14, color: Colors.black)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        review.content,
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetYourHost(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meet your host',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EFE9), // Light beige background
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Flexible(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: property.hostAvatar.isNotEmpty
                              ? NetworkImage(property.hostAvatar)
                              : null,
                          child: property.hostAvatar.isEmpty
                              ? const Icon(LucideIcons.user,
                                  size: 40, color: Colors.grey)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE91E63),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.shieldCheck,
                              color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      property.hostName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Host',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${property.reviewsCount}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text('Reviews', style: TextStyle(fontSize: 12)),
                  const Divider(),
                  Text(
                    '${property.rating}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text('Rating', style: TextStyle(fontSize: 12)),
                  const Divider(),
                  Text(
                    '${property.hostYearsHosting}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text('Years hosting', style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (property.hostWork.isNotEmpty) ...[
          Row(
            children: [
              const Icon(LucideIcons.briefcase, size: 20),
              const SizedBox(width: 12),
              Text('My work: ${property.hostWork}'),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Text(
          property.hostDescription,
          style: const TextStyle(height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text(
          'Host details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text('Response rate: ${property.hostResponseRate}'),
        Text('Responds ${property.hostResponseTime}'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final user = ref.read(authStateProvider).value;
              final appUser = ref.read(currentUserProvider).value;
              
              if (user == null) {
                showLoginModal(context);
                return;
              }

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connecting to host...')),
              );

              final displayName = appUser?.displayName ?? 
                                user.displayName ?? 
                                user.email?.split('@')[0] ?? 
                                'Guest';
              
              final photoUrl = appUser?.photoUrl ?? user.photoURL ?? '';

              final chatId = await ref
                  .read(chatControllerProvider.notifier)
                  .createOrGetChat(
                    user.uid,
                    property.hostId,
                    currentUserData: {
                      'name': displayName,
                      'avatar': photoUrl,
                    },
                    otherUserData: {
                      'name': property.hostName,
                      'avatar': property.hostAvatar,
                    },
                  );

              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                if (chatId != null) {
                  context.push('/chat', extra: {
                    'id': chatId,
                    'name': property.hostName,
                    'image': property.hostAvatar,
                    'userId': property.hostId,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to start chat')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Message host',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(LucideIcons.shieldAlert,
                size: 24,
                color: const Color(0xFFE91E63).withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'To help protect your payment, always use VillaVibe to send money and communicate with hosts.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailability(Property property) {
    String dateText = property.dateRangeText.isNotEmpty
        ? property.dateRangeText
        : 'Select dates';
    
    if (_selectedStartDate != null && _selectedEndDate != null) {
      final start = DateFormat('MMM d').format(_selectedStartDate!);
      final end = DateFormat('MMM d').format(_selectedEndDate!);
      dateText = '$start - $end';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Availability',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        Text(dateText),
        const SizedBox(height: 24),
        // Calendar with blocked dates
        StreamBuilder<List<Booking>>(
          stream: ref.read(bookingRepositoryProvider).getPropertyBookingsStream(property.id),
          builder: (context, snapshot) {
            final bookings = snapshot.data ?? [];
            final activeBookings = bookings.where((b) => 
              b.status != Booking.statusCompleted && 
              b.status != Booking.statusCancelled
            ).toList();
            
            return Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GuestCalendarView(
                  bookings: activeBookings,
                  pricePerNight: property.pricePerNight,
                  customPrices: property.customPrices,
                  onDateRangeSelected: (start, end) {
                    setState(() {
                      _selectedStartDate = start;
                      _selectedEndDate = end;
                    });
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildThingsToKnow(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Things to know',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 24),
        _buildPolicyItem(LucideIcons.calendarX, 'Cancellation policy',
            property.cancellationPolicy),
        const SizedBox(height: 24),
        _buildPolicyItem(LucideIcons.key, 'House rules',
            property.houseRules.take(3).join('\n')),
        const SizedBox(height: 24),
        _buildPolicyItem(LucideIcons.shield, 'Safety & property',
            property.safetyItems.take(3).join('\n')),
        const SizedBox(height: 48),
        TextButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report submitted. We will investigate.')),
            );
          },
          icon: const Icon(LucideIcons.flag, size: 16, color: Colors.black),
          label: const Text(
            'Report this listing',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyItem(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              const Icon(LucideIcons.chevronRight, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocation(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where you\'ll be',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          property.address.isNotEmpty ? property.address : '${property.city}, Indonesia',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        Container(
        height: 240,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: GoogleMap(
          key: ValueKey('map_${property.id}'),
          liteModeEnabled: true, // Re-enable Lite Mode for performance now that API key is fixed
          initialCameraPosition: CameraPosition(
            target: LatLng(property.location.latitude, property.location.longitude),
            zoom: 14,
          ),
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          myLocationButtonEnabled: false,
          markers: {
            Marker(
              markerId: const MarkerId('property'),
              position: LatLng(property.location.latitude, property.location.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          },
        ),
      ),
      ],
    );
  }

  Widget _buildBottomBar(
      BuildContext context, Property property, bool isLoggedIn) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    String dateText = property.dateRangeText.isNotEmpty
        ? property.dateRangeText
        : '${currencyFormat.format(property.pricePerNight)} night';

    if (_selectedStartDate != null && _selectedEndDate != null) {
      final start = DateFormat('MMM d').format(_selectedStartDate!);
      final end = DateFormat('MMM d').format(_selectedEndDate!);
      dateText = '$start - $end';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currencyFormat.format(property.priceTotal > 0 ? property.priceTotal : property.pricePerNight),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (!isLoggedIn) {
                  showLoginModal(context);
                } else {
                  context.push('/booking', extra: {
                    'property': property,
                    'startDate': _selectedStartDate,
                    'endDate': _selectedEndDate,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63), // Pink-red
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Reserve',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
