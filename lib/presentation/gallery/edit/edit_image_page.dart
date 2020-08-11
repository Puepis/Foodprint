import 'package:flutter/material.dart';
import 'package:foodprint/domain/photos/photo_entity.dart';
import 'package:foodprint/domain/restaurants/restaurant_entity.dart';
import 'package:foodprint/presentation/core/styles/colors.dart';
import 'package:foodprint/presentation/gallery/edit/edit_image_form.dart';

class EditImagePage extends StatefulWidget {
  static const routeName = "/edit_image";
  final PhotoEntity photo;
  final RestaurantEntity restaurant;
  final VoidCallback onEdit;
  const EditImagePage(
      {Key key, @required this.photo, @required this.restaurant, this.onEdit})
      : super(key: key);
  @override
  _EditImagePageState createState() => _EditImagePageState();
}

class _EditImagePageState extends State<EditImagePage> {
  Color get backgroundColor => foodprintPrimaryColorSwatch[50];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            elevation: 0.0,
            backgroundColor: backgroundColor,
          ),
          body: Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    "Edit the details!",
                    style: TextStyle(
                        color: primaryColor,
                        fontSize: 35.0,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  EditImageForm(
                      onEdit: widget.onEdit,
                      photo: widget.photo,
                      restaurant: widget.restaurant),
                ],
              ))),
    );
  }
}
