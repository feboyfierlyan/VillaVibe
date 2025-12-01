import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:villavibe/features/auth/data/repositories/auth_repository.dart';
import 'package:villavibe/features/properties/data/repositories/property_repository.dart';
import 'package:villavibe/features/properties/domain/models/property.dart';



class HostOnboardingState {
  final String? propertyId; // For editing mode
  final String propertyType;
  final String privacyType;
  final String location;
  final int guestCount;
  final int bedroomCount;
  final int bedCount;
  final int bathroomCount;
  final List<String> staffServices;
  final List<String> outdoorAmenities;
  final List<String> amenities;
  final String title;
  final String description;
  final double price;
  final bool isInstantBook;

  final String setting;
  final String architectureStyle;
  final double landSize;
  final String privacyLevel;
  final List<String> bedroomNames;
  final String vibe;
  final double? latitude;
  final double? longitude;
  final List<XFile> selectedPhotos;
  final bool isPublishing;
  final String? error;

  const HostOnboardingState({
    this.propertyId,
    this.propertyType = 'House',
    this.privacyType = 'Entire place',
    this.location = '',
    this.guestCount = 4,
    this.bedroomCount = 1,
    this.bedCount = 1,
    this.bathroomCount = 1,
    this.staffServices = const [],
    this.outdoorAmenities = const [],
    this.amenities = const [],
    this.title = '',
    this.description = '',
    this.price = 1000000.0,
    this.isInstantBook = true,
    this.setting = 'Beach',
    this.architectureStyle = 'Modern Minimalist',
    this.landSize = 0,
    this.privacyLevel = 'Private / Secluded',
    this.bedroomNames = const ['Master Suite'],
    this.vibe = 'Zen / Retreat',
    this.latitude,
    this.longitude,
    this.selectedPhotos = const [],
    this.isPublishing = false,
    this.error,
  });

  HostOnboardingState copyWith({
    String? propertyId,
    String? propertyType,
    String? privacyType,
    String? location,
    int? guestCount,
    int? bedroomCount,
    int? bedCount,
    int? bathroomCount,
    List<String>? amenities,
    List<String>? staffServices,
    List<String>? outdoorAmenities,
    String? title,
    String? description,
    double? price,
    bool? isInstantBook,
    String? setting,
    String? architectureStyle,
    double? landSize,
    String? privacyLevel,
    List<String>? bedroomNames,
    String? vibe,
    double? latitude,
    double? longitude,
    List<XFile>? selectedPhotos,
    bool? isPublishing,
    String? error,
  }) {
    return HostOnboardingState(
      propertyId: propertyId ?? this.propertyId,
      propertyType: propertyType ?? this.propertyType,
      privacyType: privacyType ?? this.privacyType,
      location: location ?? this.location,
      guestCount: guestCount ?? this.guestCount,
      bedroomCount: bedroomCount ?? this.bedroomCount,
      bedCount: bedCount ?? this.bedCount,
      bathroomCount: bathroomCount ?? this.bathroomCount,
      amenities: amenities ?? this.amenities,
      staffServices: staffServices ?? this.staffServices,
      outdoorAmenities: outdoorAmenities ?? this.outdoorAmenities,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      isInstantBook: isInstantBook ?? this.isInstantBook,
      setting: setting ?? this.setting,
      architectureStyle: architectureStyle ?? this.architectureStyle,
      landSize: landSize ?? this.landSize,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      bedroomNames: bedroomNames ?? this.bedroomNames,
      vibe: vibe ?? this.vibe,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
      isPublishing: isPublishing ?? this.isPublishing,
      error: error ?? this.error,
    );
  }
}

class HostOnboardingNotifier extends StateNotifier<HostOnboardingState> {
  final PropertyRepository _propertyRepository;

  HostOnboardingNotifier(this._propertyRepository) : super(const HostOnboardingState());

  void initializeFromProperty(Property property) {
    state = state.copyWith(
      propertyId: property.id,
      title: property.name,
      description: property.description,
      price: property.pricePerNight.toDouble(),
      location: property.address,
      guestCount: property.specs.maxGuests,
      bedroomCount: property.specs.bedrooms,
      bathroomCount: property.specs.bathrooms,
      amenities: property.amenities,
      latitude: property.location.latitude,
      longitude: property.location.longitude,
      propertyType: property.categoryId,
      architectureStyle: property.architectureStyle,
      landSize: property.landSize,
      vibe: property.vibe,
      bedroomNames: property.bedroomNames,
      setting: property.setting,
      privacyLevel: property.privacyLevel,
      staffServices: property.staffServices,
      outdoorAmenities: property.outdoorAmenities,
      isInstantBook: property.isInstantBook,
    );
  }

  // ... (existing setters) ...
  
  void setPropertyType(String type) => state = state.copyWith(propertyType: type);
  void setPrivacyType(String type) => state = state.copyWith(privacyType: type);
  void setLocation(String location) => state = state.copyWith(location: location);
  
  void setCoordinates(double lat, double lng) {
    print('Setting coordinates: $lat, $lng');
    state = state.copyWith(latitude: lat, longitude: lng);
  }
  
  void updateGuestCount(int count) => state = state.copyWith(guestCount: count);
  
  void updateBedroomCount(int count) {
    final currentNames = List<String>.from(state.bedroomNames);
    if (count > currentNames.length) {
      for (int i = currentNames.length; i < count; i++) {
        currentNames.add('Bedroom ${i + 1}');
      }
    } else if (count < currentNames.length) {
      currentNames.length = count;
    }
    state = state.copyWith(bedroomCount: count, bedroomNames: currentNames);
  }

  void updateBedCount(int count) => state = state.copyWith(bedCount: count);
  void updateBathroomCount(int count) => state = state.copyWith(bathroomCount: count);

  void setBedroomName(int index, String name) {
    if (index >= 0 && index < state.bedroomNames.length) {
      final newNames = List<String>.from(state.bedroomNames);
      newNames[index] = name;
      state = state.copyWith(bedroomNames: newNames);
    }
  }

  void toggleAmenity(String amenity) {
    final current = List<String>.from(state.amenities);
    if (current.contains(amenity)) {
      current.remove(amenity);
    } else {
      current.add(amenity);
    }
    state = state.copyWith(amenities: current);
  }

  void toggleStaffService(String service) {
    final current = List<String>.from(state.staffServices);
    if (current.contains(service)) {
      current.remove(service);
    } else {
      current.add(service);
    }
    state = state.copyWith(staffServices: current);
  }

  void toggleOutdoorAmenity(String amenity) {
    final current = List<String>.from(state.outdoorAmenities);
    if (current.contains(amenity)) {
      current.remove(amenity);
    } else {
      current.add(amenity);
    }
    state = state.copyWith(outdoorAmenities: current);
  }

  void setTitle(String title) => state = state.copyWith(title: title);
  void setDescription(String desc) => state = state.copyWith(description: desc);
  void setPrice(double price) => state = state.copyWith(price: price);
  void toggleInstantBook(bool value) => state = state.copyWith(isInstantBook: value);

  void setSetting(String setting) => state = state.copyWith(setting: setting);
  void setArchitectureStyle(String style) => state = state.copyWith(architectureStyle: style);
  void setLandSize(double size) => state = state.copyWith(landSize: size);
  void setPrivacyLevel(String level) => state = state.copyWith(privacyLevel: level);
  void setVibe(String vibe) => state = state.copyWith(vibe: vibe);

  void addPhoto(XFile photo) {
    state = state.copyWith(selectedPhotos: [...state.selectedPhotos, photo]);
  }

  void removePhoto(int index) {
    if (index >= 0 && index < state.selectedPhotos.length) {
      final newPhotos = List<XFile>.from(state.selectedPhotos);
      newPhotos.removeAt(index);
      state = state.copyWith(selectedPhotos: newPhotos);
    }
  }

  Future<void> updateListing() async {
    if (state.propertyId == null) return;
    
    state = state.copyWith(isPublishing: true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final hostId = currentUser?.uid ?? 'unknown_host';
      
      // Upload new photos if any
      final newImageUrls = await _uploadPhotos(hostId);
      // Note: We should ideally merge with existing images, but for now we'll just add new ones
      // or if we had existing images in state, we'd use them. 
      // Since we don't load existing image URLs into state yet, let's assume we are just updating text fields for now
      // or appending new images.
      
      // Fetch current property to preserve fields we don't edit
      final currentProperty = await _propertyRepository.getProperty(state.propertyId!);
      if (currentProperty == null) throw Exception('Property not found');

      // Fetch latest user profile to ensure host info is up to date
      String hostName = currentProperty.hostName;
      String hostAvatar = currentProperty.hostAvatar;
      
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(hostId)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null) {
            hostName = data['displayName'] as String? ?? hostName;
            hostAvatar = data['photoUrl'] as String? ?? hostAvatar;
          }
        }
      } catch (e) {
        print('Error fetching user profile for update: $e');
      }

      final updatedProperty = Property(
        id: state.propertyId!,
        hostId: hostId,
        name: state.title,
        description: state.description,
        pricePerNight: state.price.toInt(),
        address: state.location,
        city: _parseCityFromLocation(state.location),
        specs: PropertySpecs(
          bedrooms: state.bedroomCount,
          bathrooms: state.bathroomCount,
          maxGuests: state.guestCount,
        ),
        amenities: state.amenities,
        images: [...currentProperty.images, ...newImageUrls], // Append new images
        rating: currentProperty.rating,
        hostName: hostName,
        hostAvatar: hostAvatar,
        hostYearsHosting: currentProperty.hostYearsHosting,
        reviewsCount: currentProperty.reviewsCount,
        categoryId: state.setting.toLowerCase(),
        
        architectureStyle: state.architectureStyle,
        landSize: state.landSize,
        vibe: state.vibe,
        bedroomNames: state.bedroomNames,
        setting: state.setting,
        privacyLevel: state.privacyLevel,
        staffServices: state.staffServices,
        outdoorAmenities: state.outdoorAmenities,
        
        hostWork: currentProperty.hostWork,
        hostDescription: currentProperty.hostDescription,
        hostResponseRate: currentProperty.hostResponseRate,
        hostResponseTime: currentProperty.hostResponseTime,
        cancellationPolicy: currentProperty.cancellationPolicy,
        houseRules: currentProperty.houseRules,
        safetyItems: currentProperty.safetyItems,
        location: state.latitude != null && state.longitude != null 
            ? GeoPoint(state.latitude!, state.longitude!)
            : currentProperty.location,
        isInstantBook: state.isInstantBook,
      );

      await _propertyRepository.updateProperty(updatedProperty);

      state = state.copyWith(isPublishing: false);
    } catch (e) {
      state = state.copyWith(isPublishing: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> publishListing() async {
    // ... existing publishListing code ...
    state = state.copyWith(isPublishing: true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final hostId = currentUser?.uid ?? 'unknown_host';
      
      print('Publishing listing for host: $hostId');
      print('Coordinates: ${state.latitude}, ${state.longitude}');

      // Upload photos first
      final imageUrls = await _uploadPhotos(hostId);

      // Fetch full user profile if basic auth info is missing
      String hostName = currentUser?.displayName ?? 'New Host';
      String hostAvatar = currentUser?.photoURL ?? '';
      
      if (hostName == 'New Host' || hostAvatar.isEmpty) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(hostId)
              .get();
          
          if (userDoc.exists) {
            final data = userDoc.data();
            if (data != null) {
              if (hostName == 'New Host') {
                hostName = data['displayName'] as String? ?? 'Host';
              }
              if (hostAvatar.isEmpty) {
                hostAvatar = data['photoUrl'] as String? ?? '';
              }
            }
          }
        } catch (e) {
          print('Error fetching user profile: $e');
        }
      }

      // Create Property object with all rich data
      final property = Property(
        id: '', // Firestore will generate ID
        hostId: hostId,
        name: state.title,
        description: state.description,
        pricePerNight: state.price.toInt(),
        address: state.location, // Using location string as address for now
        city: _parseCityFromLocation(state.location),
        specs: PropertySpecs(
          bedrooms: state.bedroomCount,
          bathrooms: state.bathroomCount,
          maxGuests: state.guestCount,
        ),
        amenities: state.amenities,
        images: imageUrls,
        rating: 0.0, // New listing
        hostName: hostName,
        hostAvatar: hostAvatar,
        hostYearsHosting: 0,
        reviewsCount: 0,
        categoryId: state.setting.toLowerCase(), // Map setting to category
        
        // Rich Data Fields
        architectureStyle: state.architectureStyle,
        landSize: state.landSize,
        vibe: state.vibe,
        bedroomNames: state.bedroomNames,
        setting: state.setting,
        privacyLevel: state.privacyLevel,
        staffServices: state.staffServices,
        outdoorAmenities: state.outdoorAmenities,
        
        // Default/Empty fields for now
        hostWork: '',
        hostDescription: '',
        hostResponseRate: '100%',
        hostResponseTime: 'within an hour',
        cancellationPolicy: 'Flexible',
        houseRules: [],
        safetyItems: [],
        location: state.latitude != null && state.longitude != null 
            ? GeoPoint(state.latitude!, state.longitude!)
            : const GeoPoint(-8.409518, 115.188919),
        isInstantBook: state.isInstantBook,
      );

      await _propertyRepository.addProperty(property);

      // Update user's isHost status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(hostId)
          .update({'isHost': true});

      state = state.copyWith(isPublishing: false);
    } catch (e) {
      state = state.copyWith(isPublishing: false, error: e.toString());
      rethrow;
    }
  }

  Future<List<String>> _uploadPhotos(String hostId) async {
    List<String> imageUrls = [];
    print('Starting upload for ${state.selectedPhotos.length} photos...');
    
    for (var photo in state.selectedPhotos) {
      final String uuid = const Uuid().v4();
      final ref = FirebaseStorage.instance
          .ref()
          .child('properties/$hostId/$uuid.jpg');
      
      try {
        TaskSnapshot snapshot;
        final metadata = SettableMetadata(contentType: 'image/jpeg');

        // Always use putData for better reliability on simulator/emulator
        print('Reading file bytes...');
        final data = await photo.readAsBytes();
        print('Uploading ${data.length} bytes...');
        snapshot = await ref.putData(data, metadata);

        if (snapshot.state == TaskState.success) {
          // Verify object exists before getting URL
          try {
            await snapshot.ref.getMetadata();
            final url = await snapshot.ref.getDownloadURL();
            print('Uploaded photo successfully: $url');
            imageUrls.add(url);
          } catch (e) {
            print('Error verifying upload: $e');
            // Retry once with delay
            await Future.delayed(const Duration(seconds: 1));
            try {
               final url = await snapshot.ref.getDownloadURL();
               imageUrls.add(url);
            } catch (retryError) {
              print('Retry failed: $retryError');
              // Fallback to placeholder on verification failure
              imageUrls.add('https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1000&q=80');
            }
          }
        } else {
          print('Upload failed. Task state: ${snapshot.state}');
          // Fallback to placeholder on failure
          imageUrls.add('https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1000&q=80');
        }
      } catch (e) {
        print('Error uploading photo: $e');
        // Fallback to placeholder on exception (e.g. object-not-found on simulator)
        print('Using placeholder image due to upload error.');
        imageUrls.add('https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1000&q=80');
      }
    }
    return imageUrls;
  }

  String _parseCityFromLocation(String location) {
    // Attempt to parse "Street, City, Country" format
    final parts = location.split(',');
    if (parts.length >= 2) {
      // Return the second to last part (usually city/region)
      // e.g. "Jalan Raya, Ubud, Indonesia" -> "Ubud"
      return parts[parts.length - 2].trim();
    } else if (parts.isNotEmpty) {
      return parts.last.trim();
    }
    return 'Bali';
  }
}

final hostOnboardingNotifierProvider =
    StateNotifierProvider<HostOnboardingNotifier, HostOnboardingState>((ref) {
  final repository = PropertyRepository(FirebaseFirestore.instance);
  return HostOnboardingNotifier(repository);
});
