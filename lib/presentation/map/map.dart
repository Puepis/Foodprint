import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodprint/application/location/location_bloc.dart';
import 'package:foodprint/application/photos/photo_actions_bloc.dart';
import 'package:foodprint/domain/photos/photo_entity.dart';
import 'package:foodprint/domain/restaurants/restaurant_entity.dart';
import 'package:foodprint/presentation/data/user_data.dart';
import 'package:foodprint/presentation/map/restaurant_preview.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

/// The map displaying the user's visited locations.
class FoodMap extends StatefulWidget {
  const FoodMap({Key key}) : super(key: key);
  @override
  _FoodMapState createState() => _FoodMapState();
}

class _FoodMapState extends State<FoodMap> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng _currentPos;
  LatLng _initialPos;
  Map<String, Marker> _markers = {};
  bool _showRecenterButton = false;
  bool _wasInitial = true;
  MapType _currentMapType = MapType.normal;
  final double mapZoom = 16.0;

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserData>();
    return BlocBuilder<LocationBloc, LocationState>(builder: (_, state) {
      if (state is GetLocationSuccess) {
        _initialPos = state.latlng;
        _currentPos = state.latlng;
      }

      _markers = generateMarkers(userData);

      return Stack(children: [
        GoogleMap(
          mapType: _currentMapType,
          onMapCreated: (controller) => _mapController.complete(controller),
          initialCameraPosition:
              CameraPosition(target: _currentPos, zoom: mapZoom),
          onCameraIdle: () => setState(() {
            _wasInitial = true;
          }),
          onCameraMove: _onCameraMove,
          markers: Set<Marker>.of(_markers.values),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 32),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "map_type",
                  backgroundColor: Colors.white,
                  onPressed: _onMapTypeButtonPressed,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  child: const Icon(Icons.map, size: 32.0),
                ),
                if (_showRecenterButton)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: "recenter",
                        backgroundColor: Colors.white,
                        onPressed: _onRecenterButtonPressed,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        child: const Icon(Icons.gps_fixed, size: 32.0),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ]);
    });
  }

  void _onCameraMove(CameraPosition position) {
    _currentPos = position.target;

    // Moving away from initial position
    if (!_showRecenterButton && !_isInitial(_currentPos) && _wasInitial) {
      setState(() {
        _wasInitial = false;
        _showRecenterButton = true;
      });
    }
  }

  /// Change map type
  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  /// Recenter the map
  Future<void> _onRecenterButtonPressed() async {
    if (_mapController != null) {
      final GoogleMapController controller = await _mapController.future;
      setState(() {
        _wasInitial = false;
        _showRecenterButton = false;
      });
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          zoom: mapZoom,
          target: LatLng(_initialPos.latitude, _initialPos.longitude))));
    }
  }

  Map<String, Marker> generateMarkers(UserData userData) {
    final Map<String, Marker> result = {};
    userData.foodprint.restaurantPhotos
        .forEach((RestaurantEntity restaurant, List<PhotoEntity> photos) {
      final marker = Marker(
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          markerId: MarkerId(restaurant.id.getOrCrash()),
          position: LatLng(restaurant.latitude.getOrCrash(),
              restaurant.longitude.getOrCrash()),
          onTap: () {
            // Show restaurant info
            showModalBottomSheet(
              backgroundColor: Colors.transparent,
              context: context,
              builder: (_) => MultiProvider(
                providers: [
                  BlocProvider.value(value: context.bloc<PhotoActionsBloc>()),
                  ChangeNotifierProvider.value(value: userData),
                ],
                child: RestaurantPreview(
                  restaurant: restaurant,
                  photos: photos,
                ),
              ),
            );
          });
      result[restaurant.id.getOrCrash()] = marker;
    });
    return result;
  }

  bool _isInitial(LatLng pos) {
    final double latDiff = (pos.latitude - _initialPos.latitude).abs();
    final double lngDiff = (pos.longitude - _initialPos.longitude).abs();
    return latDiff < 0.001 && lngDiff < 0.001;
  }
}
