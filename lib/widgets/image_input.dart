import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageInput extends StatefulWidget {
  final Function(File image) onSelectImage;

  const ImageInput({super.key, required this.onSelectImage});

  @override
  State<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  File? _storedImage;

  Future<void> _takePicture() async {
    final imageFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 150,
      imageQuality: 50,
    );

    if (imageFile == null) {
      return;
    }

    setState(() {
      _storedImage = File(imageFile.path);
      widget.onSelectImage(File(imageFile.path));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey,
          foregroundImage:
              _storedImage != null ? FileImage(_storedImage!) : null,
        ),
        TextButton.icon(
          icon: const Icon(Icons.camera),
          label: Text(
            'Take Picture',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
          onPressed: _takePicture,
        )
      ],
    );
  }
}
