import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/widgets/app_skeleton.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_picture.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_picture_editor.dart';

void main() {
  testWidgets('shows a skeleton until the first image frame is rendered', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppProfilePicture.imageProvider(
            imageProvider: _DelayedMemoryImage(
              _transparentImageBytes,
              const Duration(milliseconds: 50),
            ),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(AppSkeleton), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();

    expect(find.byType(AppSkeleton), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('renders the edit badge in the editor variant', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppProfilePictureEditor.imageProvider(
            imageProvider: MemoryImage(_transparentImageBytes),
            onEditTap: () {},
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
  });
}

class _DelayedMemoryImage extends ImageProvider<_DelayedMemoryImage> {
  const _DelayedMemoryImage(this.bytes, this.delay);

  final Uint8List bytes;
  final Duration delay;

  @override
  Future<_DelayedMemoryImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_DelayedMemoryImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _DelayedMemoryImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1,
      debugLabel: 'delayed-test-image',
    );
  }

  Future<ui.Codec> _loadAsync(
    _DelayedMemoryImage key,
    ImageDecoderCallback decode,
  ) async {
    await Future<void>.delayed(delay);
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
      key.bytes,
    );
    return decode(buffer);
  }
}

final Uint8List _transparentImageBytes = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xFF,
  0xFF,
  0x3F,
  0x00,
  0x05,
  0xFE,
  0x02,
  0xFE,
  0xDC,
  0xCC,
  0x59,
  0xE7,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);
