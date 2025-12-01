import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:villavibe/features/host/presentation/providers/host_onboarding_provider.dart';
import 'package:villavibe/features/host/presentation/widgets/bouncy_button.dart';
import 'package:villavibe/features/host/presentation/widgets/location_picker_modal.dart';

class StepBasics extends ConsumerStatefulWidget {
  const StepBasics({super.key});

  @override
  ConsumerState<StepBasics> createState() => _StepBasicsState();
}

class _StepBasicsState extends ConsumerState<StepBasics> {
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hostOnboardingNotifierProvider);
    final notifier = ref.read(hostOnboardingNotifierProvider.notifier);

    // Sync controller with state if it changed externally (e.g. from map picker)
    ref.listen(hostOnboardingNotifierProvider, (previous, next) {
      if (previous?.location != next.location && _addressController.text != next.location) {
        _addressController.text = next.location;
      }
    });

    // Initialize controller text if empty (first load)
    if (_addressController.text.isEmpty && state.location.isNotEmpty) {
      _addressController.text = state.location;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Describe the setting')
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          _buildSettingGrid(state.setting, notifier)
              .animate()
              .fadeIn(delay: 200.ms)
              .scale(begin: const Offset(0.95, 0.95)),
          const SizedBox(height: 32),
          _buildHeader('Estate Scale')
              .animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          _buildLandSizeInput(state.landSize, notifier)
              .animate()
              .fadeIn(delay: 500.ms),
          const SizedBox(height: 32),
          _buildHeader('Privacy Level')
              .animate()
              .fadeIn(delay: 600.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          _buildPrivacySelector(state.privacyLevel, notifier)
              .animate()
              .fadeIn(delay: 700.ms),
          const SizedBox(height: 48),
          _buildHeader('Where is your place located?')
              .animate()
              .fadeIn(delay: 800.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          _buildMapPlaceholder(context, state, notifier)
              .animate()
              .fadeIn(delay: 900.ms)
              .scale(begin: const Offset(0.95, 0.95)),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Address',
              hintText: 'e.g. Jalan Raya Ubud, Bali',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              prefixIcon: const Icon(Icons.map_outlined),
              helperText: 'You can edit this if the auto-detected address is incorrect.',
            ),
            maxLines: 2,
            onChanged: (val) => notifier.setLocation(val),
          ).animate().fadeIn(delay: 950.ms),
          const SizedBox(height: 48),
          _buildHeader('How many guests can your place accommodate?')
              .animate()
              .fadeIn(delay: 1000.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),
          _buildCounter(
            'Guests',
            state.guestCount,
            (val) => notifier.updateGuestCount(val),
          ).animate().fadeIn(delay: 1100.ms).slideX(begin: 0.1, end: 0),
          const Divider(height: 32),
          _buildCounter(
            'Bedrooms',
            state.bedroomCount,
            (val) => notifier.updateBedroomCount(val),
          ).animate().fadeIn(delay: 1200.ms).slideX(begin: 0.1, end: 0),
          
          if (state.bedroomCount > 0) ...[
            const SizedBox(height: 24),
            const Text(
              'Sleeping Arrangements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            const Text(
              'Give your rooms a name (e.g., "Ocean Master Suite").',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.bedroomNames.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return TextField(
                  controller: TextEditingController(text: state.bedroomNames[index])
                    ..selection = TextSelection.fromPosition(
                        TextPosition(offset: state.bedroomNames[index].length)),
                  decoration: InputDecoration(
                    labelText: 'Bedroom ${index + 1}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => notifier.setBedroomName(index, val),
                ).animate().fadeIn(delay: (150 + (index * 50)).ms).slideX();
              },
            ),
          ],

          const Divider(height: 32),
          _buildCounter(
            'Beds',
            state.bedCount,
            (val) => notifier.updateBedCount(val),
          ).animate().fadeIn(delay: 1300.ms).slideX(begin: 0.1, end: 0),
          const Divider(height: 32),
          _buildCounter(
            'Bathrooms',
            state.bathroomCount,
            (val) => notifier.updateBathroomCount(val),
          ).animate().fadeIn(delay: 1400.ms).slideX(begin: 0.1, end: 0),
          
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSettingGrid(
      String selectedSetting, HostOnboardingNotifier notifier) {
    final settings = [
      {
        'label': 'Beach',
        'image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=500&q=80',
      },
      {
        'label': 'Mountain',
        'image': 'https://images.unsplash.com/photo-1519681393798-38e43269d877?auto=format&fit=crop&w=500&q=80',
      },
      {
        'label': 'City',
        'image': 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?auto=format&fit=crop&w=500&q=80',
      },
      {
        'label': 'Tropical',
        'image': 'https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?auto=format&fit=crop&w=500&q=80',
      },
      {
        'label': 'Camping',
        'image': 'https://images.unsplash.com/photo-1523987355523-c7b5b0dd90a7?auto=format&fit=crop&w=500&q=80',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: settings.length,
      itemBuilder: (context, index) {
        final setting = settings[index];
        final label = setting['label']!;
        final imageUrl = setting['image']!;
        final isSelected = label == selectedSetting;

        return BouncyButton(
          onTap: () {
            HapticFeedback.selectionClick();
            notifier.setSetting(label);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 16, color: Colors.black),
                      ),
                    ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLandSizeInput(double size, HostOnboardingNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.square_foot, color: Colors.black87, size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Land Size',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    hintText: '0',
                    suffixText: 'm²',
                    suffixStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onChanged: (val) {
                    notifier.setLandSize(double.tryParse(val) ?? 0);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySelector(
      String selectedPrivacy, HostOnboardingNotifier notifier) {
    final levels = [
      'Gated Community',
      'Private / Secluded',
      'Shared Grounds',
    ];

    return Wrap(
      spacing: 12,
      children: levels.map((level) {
        final isSelected = level == selectedPrivacy;
        return ChoiceChip(
          label: Text(level),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              HapticFeedback.selectionClick();
              notifier.setPrivacyLevel(level);
            }
          },
          selectedColor: Colors.black.withOpacity(0.05),
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.black : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isSelected ? Colors.black : Colors.grey[300]!,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMapPlaceholder(BuildContext context, HostOnboardingState state, HostOnboardingNotifier notifier) {
    final hasLocation = state.latitude != null && state.longitude != null;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final result = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => LocationPickerModal(
            initialLat: state.latitude,
            initialLng: state.longitude,
          ),
        );

        if (result != null) {
          final latLng = result['latLng'] as LatLng;
          final address = result['address'] as String;
          
          notifier.setCoordinates(latLng.latitude, latLng.longitude);
          notifier.setLocation(address.isNotEmpty ? address : '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}');
        }
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background Image or Map Preview
              if (hasLocation)
                GoogleMap(
                  key: ValueKey('${state.latitude}_${state.longitude}'),
                  initialCameraPosition: CameraPosition(
                    target: LatLng(state.latitude!, state.longitude!),
                    zoom: 15,
                  ),
                  zoomControlsEnabled: false,
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  myLocationButtonEnabled: false,
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: LatLng(state.latitude!, state.longitude!),
                    ),
                  },
                )
              else
                Image.asset(
                  'assets/images/map_placeholder.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  opacity: const AlwaysStoppedAnimation(0.5),
                  errorBuilder: (c, e, s) => Container(color: Colors.blue[50]),
                ),

              // Overlay UI
              if (!hasLocation)
                const Center(
                  child: Icon(Icons.location_on, color: Colors.red, size: 48),
                ),
              
              Positioned(
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasLocation ? Icons.edit_location : Icons.add_location_alt, 
                        size: 16, 
                        color: Colors.black87
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasLocation ? 'Change Location' : 'Pinpoint on Map', 
                        style: const TextStyle(fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Row(
          children: [
            _buildIconButton(
              Icons.remove,
              () {
                if (value > 0) {
                  HapticFeedback.selectionClick();
                  onChanged(value - 1);
                }
              },
              enabled: value > 0,
            ),
            SizedBox(
              width: 40,
              child: Text(
                value.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ).animate(key: ValueKey(value)).scale(duration: 200.ms, curve: Curves.easeOutBack),
            ),
            _buildIconButton(
              Icons.add,
              () {
                HapticFeedback.selectionClick();
                onChanged(value + 1);
              },
              enabled: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed,
      {bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: enabled ? Colors.grey[400]! : Colors.grey[200]!,
        ),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: enabled ? onPressed : null,
        color: enabled ? Colors.black87 : Colors.grey[300],
        splashRadius: 24,
      ),
    );
  }
}
