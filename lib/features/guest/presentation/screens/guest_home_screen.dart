import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:villavibe/features/auth/data/repositories/auth_repository.dart';
import 'package:villavibe/features/bookings/presentation/screens/my_bookings_screen.dart';
import 'package:villavibe/features/favorites/presentation/screens/wishlist_screen.dart';
import 'package:villavibe/features/guest/data/repositories/category_repository.dart';
import 'package:villavibe/features/guest/domain/models/category.dart';
import 'package:villavibe/features/guest/presentation/widgets/authenticated_profile_view.dart';
import 'package:villavibe/features/guest/presentation/widgets/category_selector.dart';
import 'package:villavibe/features/guest/presentation/widgets/login_prompt_view.dart';
import 'package:villavibe/features/guest/presentation/widgets/profile_login_view.dart';
import 'package:villavibe/features/home/presentation/providers/search_provider.dart';
import 'package:villavibe/features/home/presentation/widgets/destination_card.dart';
import 'package:villavibe/features/home/presentation/widgets/search_filter_modal.dart';
import 'package:villavibe/features/home/presentation/widgets/standard_bottom_nav_bar.dart';
import 'package:villavibe/features/properties/data/repositories/property_repository.dart';
import 'package:villavibe/features/properties/domain/models/property.dart';
import 'package:villavibe/features/properties/presentation/widgets/villa_compact_card.dart';
import 'package:villavibe/features/messages/presentation/screens/chat_list_screen.dart';


class GuestHomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const GuestHomeScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends ConsumerState<GuestHomeScreen> {
  int _currentNavIndex = 0;
  bool _isSearchActive = false;
  late ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialIndex;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  void _onNavTapped(int index) {
    setState(() {
      _currentNavIndex = index;
      _isSearchActive = false;
      FocusScope.of(context).unfocus();
    });
  }

  void _onSearchBack() {
    setState(() {
      _isSearchActive = false;
    });
    ref.read(searchFilterStateProvider.notifier).reset();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final allPropertiesAsync = ref.watch(allPropertiesProvider);
    final filteredPropertiesAsync = ref.watch(filteredPropertiesProvider);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    Widget buildBody() {
      switch (_currentNavIndex) {
        case 0:
          return _buildExploreContent(
            filteredPropertiesAsync,
          );
        case 1:
          if (user == null) {
            return const LoginPromptView(
              title: 'Wishlists',
              subtitle: 'Log in to view your wishlists',
              description:
                  'You can create, view, or edit wishlists once you\'ve logged in.',
            );
          }
          return const WishlistScreen();
        case 2:
          if (user == null) {
            return const LoginPromptView(
              title: 'Trips',
              subtitle: 'No trips yet',
              description:
                  'When you\'re ready to plan your next trip, we\'re here to help.',
            );
          }
          return const MyBookingsScreen();
        case 3:
          if (user == null) {
            return const LoginPromptView(
              title: 'Inbox',
              subtitle: 'Log in to see messages',
              description:
                  'Once you login, you\'ll find messages from hosts here.',
            );
          }
          return const ChatListScreen();
        case 4:
          if (user == null) {
            return const ProfileLoginView();
          }
          return const AuthenticatedProfileView();
        default:
          return _buildExploreContent(
            _isSearchActive ? filteredPropertiesAsync : allPropertiesAsync,
          );
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFAFAFA),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey<int>(_currentNavIndex),
          child: buildBody(),
        ),
      ),
      bottomNavigationBar: _isSearchActive
          ? null
          : StandardBottomNavBar(
              currentIndex: _currentNavIndex,
              onTap: _onNavTapped,
            ),
    );
  }

  Widget _buildExploreContent(AsyncValue<List<Property>> propertiesAsync) {
    return CustomScrollView(
      controller: _scrollController,
      key: const PageStorageKey('explore_scroll'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: true,
          snap: true,
          backgroundColor: Colors.white,
          elevation: _isScrolled ? 1 : 0,
          shadowColor: Colors.black.withOpacity(0.1),
          surfaceTintColor: Colors.white,
          toolbarHeight: 80.0,
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: GestureDetector(
              onTap: () {
                context.push('/search');
              },
              child: Hero(
                tag: 'search_bar',
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.search, size: 20),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Where to?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Anywhere · Any week · Add guests',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: const Icon(LucideIcons.slidersHorizontal, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 16),
              ref.watch(categoriesProvider).when(
                    data: (categories) {
                      // Ensure "All" category exists
                      final allCategories = [
                        Category(
                          id: 'all',
                          label: 'All',
                          iconName: 'layoutGrid',
                        ),
                        ...categories.where((c) => c.label != 'All'),
                      ];

                      return CategorySelector(
                        categories: allCategories,
                        selectedCategoryId: ref.watch(searchFilterStateProvider).selectedCategory,
                        onCategoryChanged: (category) {
                          if (category.label == 'All' || category.id == 'all') {
                            ref
                                .read(searchFilterStateProvider.notifier)
                                .setCategory(null);
                          } else {
                            ref
                                .read(searchFilterStateProvider.notifier)
                                .setCategory(category.id);
                          }
                        },
                      );
                    },
                    loading: () => const SizedBox(
                        height: 44,
                        child: Center(child: CircularProgressIndicator())),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
              const SizedBox(height: 24),
              propertiesAsync.when(
                skipLoadingOnReload: true,
                data: (properties) {
                  if (properties.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(LucideIcons.searchX,
                                size: 64, color: Colors.black12),
                            const SizedBox(height: 16),
                            const Text(
                              'No results found',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _onSearchBack,
                              child: const Text('Clear Filters'),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().scale(),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        context,
                        title: _isSearchActive
                            ? 'Search Results'
                            : 'Recommended for you',
                        properties: properties,
                        delay: 200.ms,
                        heroTagPrefix: _isSearchActive ? 'search_' : 'recommended_',
                      ),
                      const SizedBox(height: 40),
                      if (!_isSearchActive) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Discover new places',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5),
                              ),
                              Icon(LucideIcons.arrowRight,
                                  size: 20, color: Colors.grey[400]),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 600.ms)
                            .slideX(begin: -0.1, end: 0),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              _buildAnimatedDestinationCard(
                                  'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?q=80&w=1972&auto=format&fit=crop',
                                  'Bali',
                                  0,
                                  context),
                              _buildAnimatedDestinationCard(
                                  'https://images.unsplash.com/photo-1506953823976-52e1fdc0149a?q=80&w=1935&auto=format&fit=crop',
                                  'Malang',
                                  1,
                                  context),
                              _buildAnimatedDestinationCard(
                                  'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=2070&auto=format&fit=crop',
                                  'Batu',
                                  2,
                                  context),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                      
                      if (!_isSearchActive) ...[
                        const SizedBox(height: 40),

                        // Top Rated Section
                        _buildSection(
                          context,
                          title: 'Top Rated Villas',
                          properties: properties
                              .where((p) => p.rating >= 4.8)
                              .take(6)
                              .toList(),
                          delay: 800.ms,
                          heroTagPrefix: 'top_rated_',
                        ),
                        const SizedBox(height: 32),

                        // Beachfront Section
                        _buildSection(
                          context,
                          title: 'Beachfront Escapes',
                          properties: properties
                              .where((p) =>
                                  p.categoryId == 'beach' ||
                                  p.categoryId == 'tropical')
                              .take(6)
                              .toList(),
                          delay: 900.ms,
                          heroTagPrefix: 'beach_',
                        ),
                        const SizedBox(height: 32),

                        // Mountain Section
                        _buildSection(
                          context,
                          title: 'Mountain Retreats',
                          properties: properties
                              .where((p) =>
                                  p.categoryId == 'mountain' ||
                                  p.categoryId == 'camping')
                              .take(6)
                              .toList(),
                          delay: 1000.ms,
                          heroTagPrefix: 'mountain_',
                        ),

                        const SizedBox(height: 80), // Extra space at bottom
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedDestinationCard(
      String url, String title, int index, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: DestinationCard(
        imageUrl: url,
        title: title,
        onTap: () {
          context.push('/destination', extra: {'name': title, 'image': url});
        },
      ),
    )
        .animate()
        .fadeIn(delay: (600 + (index * 100)).ms)
        .slideY(
          begin: 0.2,
          end: 0,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Property> properties,
    required Duration delay,
    required String heroTagPrefix,
  }) {
    if (properties.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          ),
        ).animate().fadeIn(delay: delay).slideX(
              begin: -0.1,
              end: 0,
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: 16),
        SizedBox(
          height: 320, // Adjusted height for compact card
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: properties.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final property = properties[index];
              return VillaCompactCard(
                property: property,
                heroTagPrefix: heroTagPrefix,
                onTap: () {
                  context.push(
                    '/property/${property.id}',
                    extra: {
                      'property': property,
                      'heroTagPrefix': heroTagPrefix,
                    },
                  );
                },
              )
                  .animate()
                  .fadeIn(delay: (delay + (50 * index).ms))
                  .slideX(
                    begin: 0.2, // Slightly more movement
                    end: 0,
                    curve: Curves.easeOutBack,
                  );
            },
          ),
        ),
      ],
    );
  }
}
