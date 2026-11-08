import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_service.g.dart';

@Riverpod(keepAlive: true)
MediaService mediaService(Ref ref) => MediaService();

class MediaService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage({required ImageSource source}) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    return picked != null ? File(picked.path) : null;
  }

  Future<List<File>> pickMultipleImages() async {
    final List<XFile> picked = await _picker.pickMultiImage(imageQuality: 80);
    return picked.map((f) => File(f.path)).toList();
  }

  Future<File?> pickVideo({required ImageSource source}) async {
    final XFile? picked = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 60),
    );
    return picked != null ? File(picked.path) : null;
  }

  Future<List<File>> pickMultipleMedia() async {
    final List<XFile> picked = await _picker.pickMultipleMedia(imageQuality: 80);
    return picked.map((f) => File(f.path)).toList();
  }

  Future<File?> cropImage({required File imageFile}) async {
    return cropAvatar(sourcePath: imageFile.path);
  }

  /// Discord/Instagram-style interactive circular crop with drag, zoom, and pan
  Future<File?> cropAvatar({required String sourcePath}) async {
    final CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Avatar',
          toolbarColor: const Color(0xFFD4920E),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFFD4920E),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'Crop Avatar',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          cropStyle: CropStyle.circle,
        ),
      ],
    );
    return cropped != null ? File(cropped.path) : null;
  }

  /// Wide banner interactive crop with drag, zoom, and pan
  Future<File?> cropBanner({
    required String sourcePath,
    double ratioX = 16,
    double ratioY = 6,
  }) async {
    final CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
      compressQuality: 80,
      maxWidth: 1600,
      maxHeight: 600,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Banner',
          toolbarColor: const Color(0xFFD4920E),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFFD4920E),
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Banner',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    return cropped != null ? File(cropped.path) : null;
  }

  /// Square product interactive crop with drag, zoom, and pan
  Future<File?> cropProduct({
    required String sourcePath,
  }) async {
    final CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 85,
      maxWidth: 1080,
      maxHeight: 1080,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Product Photo',
          toolbarColor: const Color(0xFFD4920E),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFFD4920E),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Product Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    return cropped != null ? File(cropped.path) : null;
  }
}
