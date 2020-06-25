import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:foodprint/domain/auth/value_objects.dart';
import 'package:foodprint/domain/foodprint/foodprint_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:foodprint/domain/photos/i_photo_repository.dart';
import 'package:foodprint/domain/photos/photo_detail_entity.dart';
import 'package:foodprint/domain/restaurants/restaurant_entity.dart';
import 'package:foodprint/domain/photos/photo_failure.dart';
import 'package:foodprint/domain/photos/photo_entity.dart';
import 'package:foodprint/infrastructure/core/tokens.dart';
import 'package:foodprint/infrastructure/foodprint/local_foodprint_client.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

// This class is responsible for making requests to the API regarding photo features
@LazySingleton(as: IPhotoRepository)
class RemotePhotosClient implements IPhotoRepository {
  final LocalFoodprintClient _localFoodprintClient;

  RemotePhotosClient(this._localFoodprintClient);

  // Construct the JSON body for saving a photo
  static String createSaveRequestBody(
      UserID id, PhotoEntity photo, RestaurantEntity restaurant) {
    return jsonEncode({
      "userId": id.getOrCrash().toString(),
      "image": {
        "path": photo.storagePath.getOrCrash(),
        "data": Uint8List.fromList(photo.imageData.getOrCrash()).toString(),
        "details": {
          "name": photo.photoDetail.name.getOrCrash(),
          "price": photo.photoDetail.price.getOrCrash().toString(),
          "comments": photo.photoDetail.comments.getOrCrash(),
          "timestamp": photo.timestamp.getOrCrash(),
        },
        "location": {
          "id": restaurant.restaurantID.getOrCrash(),
          "address": restaurant.restaurantAddress.getOrCrash(),
          "name": restaurant.restaurantName.getOrCrash(),
          "rating": restaurant.restaurantRating.getOrCrash().toString(),
          "price_level": restaurant.restaurantPriceLevel.getOrCrash().toString(),
          "lat": restaurant.latitude.getOrCrash().toString(),
          "lng": restaurant.longitude.getOrCrash().toString()
        }
      }
    });
  }

  // Save a new photo
  @override
  Future<Either<PhotoFailure, FoodprintEntity>> saveNewPhoto(
      {@required UserID userID,
      @required PhotoEntity photo,
      @required RestaurantEntity restaurant,
      @required FoodprintEntity oldFoodprint}) async {
    final String requestBody = createSaveRequestBody(userID, photo, restaurant);

    final res = await http.post("$serverIP/api/photos/",
        headers: {"Content-Type": 'application/json'}, body: requestBody);
    if (res.statusCode == 200) {

      // Update local foodprint
      final FoodprintEntity newFoodprint = _localFoodprintClient.addPhotoToFoodprint(
          newPhoto: photo, restaurant: restaurant, oldFoodprint: oldFoodprint);
      return right(newFoodprint);
    } else if (res.statusCode == 401) {
      return left(const PhotoFailure.invalidPhoto());
    } else {
      return left(const PhotoFailure.serverError());
    }
  }

  // Edit a photo
  @override
  Future<Either<PhotoFailure, FoodprintEntity>> updatePhotoDetails(
      {@required PhotoEntity oldPhoto,
      @required PhotoDetailEntity photoDetail,
      @required RestaurantEntity restaurant,
      @required FoodprintEntity oldFoodprint}) async {

    final res = await http.put("$serverIP/api/photos", body: {
      "path": oldPhoto.storagePath.getOrCrash(),
      "photo_name": photoDetail.name.getOrCrash(),
      "price": photoDetail.price.getOrCrash(),
      "comments": photoDetail.comments.getOrCrash()
    });

    if (res.statusCode == 200) {
      final PhotoEntity newPhoto = PhotoEntity(
        storagePath: oldPhoto.storagePath,
        imageData: oldPhoto.imageData,
        photoDetail: photoDetail,
        timestamp: oldPhoto.timestamp,
      );

      final FoodprintEntity newFoodprint = _localFoodprintClient.editPhotoInFoodprint(
          photo: newPhoto, restaurant: restaurant, oldFoodprint: oldFoodprint);
      return right(newFoodprint);
    } else if (res.statusCode == 401) {
      return left(const PhotoFailure.invalidPhoto());
    } else {
      return left(const PhotoFailure.serverError());
    }
  }

  // Delete a photo
  @override
  Future<Either<PhotoFailure, FoodprintEntity>> deletePhoto(
      {@required PhotoEntity photo,
      @required RestaurantEntity restaurant,
      @required FoodprintEntity oldFoodprint}) async {

    final res = await http.delete("$serverIP/api/photos/",
        headers: {"photo_path": photo.storagePath.getOrCrash()});

    if (res.statusCode == 200) {
      final FoodprintEntity newFoodprint = _localFoodprintClient.removePhotoFromFoodprint(
          photo: photo, restaurant: restaurant, oldFoodprint: oldFoodprint);
      return right(newFoodprint);
    } else if (res.statusCode == 401) {
      return left(const PhotoFailure.invalidPhoto());
    } else {
      return left(const PhotoFailure.serverError());
    }
  }
}
