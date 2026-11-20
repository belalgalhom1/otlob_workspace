import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('AppNetworkAvatar', () {
    test('normalizeHttpUrl accepts http/https and rejects empty or relative URLs', () {
      expect(
        AppNetworkAvatar.normalizeHttpUrl('https://cdn.otlob.test/avatar.png'),
        'https://cdn.otlob.test/avatar.png',
      );
      expect(
        AppNetworkAvatar.normalizeHttpUrl('  http://cdn.otlob.test/logo.webp  '),
        'http://cdn.otlob.test/logo.webp',
      );
      expect(AppNetworkAvatar.normalizeHttpUrl('/media/avatars/a.webp'), isNull);
      expect(AppNetworkAvatar.normalizeHttpUrl('   '), isNull);
      expect(AppNetworkAvatar.normalizeHttpUrl(null), isNull);
    });

    testWidgets('renders CachedNetworkImage for valid URL and fallback for empty/relative URL', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                AppNetworkAvatar(
                  imageUrl: 'https://cdn.otlob.test/user.webp',
                  size: 40,
                  fallbackIcon: Icons.person,
                ),
                AppNetworkAvatar(
                  imageUrl: '/relative/no-host.png',
                  size: 40,
                  borderRadius: 10,
                  fallbackIcon: Icons.storefront,
                ),
                AppNetworkAvatar(
                  imageUrl: null,
                  size: 36,
                  fallbackText: 'Salma',
                  preferInitialFallback: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.byIcon(Icons.storefront), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('InboxConversationTile & ChatBubbleWidget avatars', () {
    testWidgets('renders avatarUrl when provided and falls back cleanly without URL', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                InboxConversationTile(
                  title: 'Order #ORD-1',
                  lastMessageContent: 'On my way',
                  timeStr: '10:15 AM',
                  unreadCount: 1,
                  icon: Icons.storefront,
                  iconColor: Colors.orange,
                  isSupport: false,
                  avatarUrl: 'https://cdn.otlob.test/store.png',
                  isStore: true,
                  onTap: () {},
                ),
                const ChatBubbleWidget(
                  isMe: false,
                  senderName: 'Youssef',
                  senderRole: 'DRIVER',
                  senderAvatarUrl: 'https://cdn.otlob.test/driver.png',
                  content: 'Arriving outside now',
                  type: 'text',
                  uploadingText: 'Uploading...',
                  fileAttachmentText: 'File',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AppNetworkAvatar), findsNWidgets(2));
      expect(find.text('Arriving outside now'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
