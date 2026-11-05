import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/features/account/models/medium_profile.dart';
import 'package:freedium/features/account/models/medium_profile_parser.dart';

void main() {
  group('MediumProfileParser.parseCount', () {
    test('reads a plain integer', () {
      expect(MediumProfileParser.parseCount('842 Followers'), 842);
    });

    test('reads a grouped integer', () {
      expect(MediumProfileParser.parseCount('1,234 Followers'), 1234);
    });

    test('expands K, M and B suffixes', () {
      expect(MediumProfileParser.parseCount('1.2K Followers'), 1200);
      expect(MediumProfileParser.parseCount('3.4M Followers'), 3400000);
      expect(MediumProfileParser.parseCount('1B Followers'), 1000000000);
    });

    test('is case insensitive about the suffix', () {
      expect(MediumProfileParser.parseCount('1.2k followers'), 1200);
    });

    test('drops a trailing zero fraction', () {
      expect(MediumProfileParser.parseCount('2.0K Posts'), 2000);
    });

    test('returns null when there is no number', () {
      expect(MediumProfileParser.parseCount('Followers'), isNull);
      expect(MediumProfileParser.parseCount(''), isNull);
      expect(MediumProfileParser.parseCount(null), isNull);
    });
  });

  group('MediumProfileParser.fromJson', () {
    test('builds a full profile from a scraped payload', () {
      final profile = MediumProfileParser.fromJson({
        'handle': 'janedoe',
        'title': 'Jane Doe on Medium',
        'description': 'Writing about design systems.',
        'image': 'https://cdn.medium.com/v2/jane.jpg',
        'followers': '1.2K Followers',
        'publications': '42 Posts',
      });

      expect(profile, isNotNull);
      expect(profile!.handle, 'janedoe');
      expect(
        profile.name,
        'Jane Doe',
        reason: 'the "on Medium" suffix is not a name',
      );
      expect(profile.bio, 'Writing about design systems.');
      expect(profile.avatarUrl, 'https://cdn.medium.com/v2/jane.jpg');
      expect(profile.followerCount, 1200);
      expect(profile.publicationCount, 42);
      expect(profile.hasStats, isTrue);
    });

    test('returns null without a handle', () {
      expect(
        MediumProfileParser.fromJson({'title': 'Jane Doe on Medium'}),
        isNull,
      );
      expect(MediumProfileParser.fromJson({'handle': '   '}), isNull);
    });

    test('strips a leading @ from the handle', () {
      final profile = MediumProfileParser.fromJson({
        'handle': '@janedoe',
        'title': 'Jane Doe',
      });

      expect(profile?.handle, 'janedoe');
      expect(profile?.mention, '@janedoe');
    });

    test('falls back to the handle when there is no name', () {
      final profile = MediumProfileParser.fromJson({'handle': 'janedoe'});

      expect(profile?.name, 'janedoe');
    });

    test('falls back to the handle when the name is only a suffix', () {
      final profile = MediumProfileParser.fromJson({
        'handle': 'janedoe',
        'title': 'on Medium',
      });

      expect(profile?.name, 'janedoe');
    });

    test('drops a boilerplate bio', () {
      final profile = MediumProfileParser.fromJson({
        'handle': 'janedoe',
        'description': 'Read free articles on Medium. Get the Medium app.',
      });

      expect(
        profile?.bio,
        isNull,
        reason: 'site copy must not be presented as the author bio',
      );
    });

    test('drops a blank bio', () {
      final profile = MediumProfileParser.fromJson({
        'handle': 'janedoe',
        'description': '   ',
      });

      expect(profile?.bio, isNull);
    });

    test('rejects a non-absolute avatar URL', () {
      final profile = MediumProfileParser.fromJson({
        'handle': 'janedoe',
        'image': '/v2/jane.jpg',
      });

      expect(profile?.avatarUrl, isNull);
    });

    test('reports no stats when Medium rendered no counts', () {
      final profile = MediumProfileParser.fromJson({
        'handle': 'janedoe',
        'followers': 'Followers',
      });

      expect(profile?.followerCount, isNull);
      expect(profile?.publicationCount, isNull);
      expect(profile?.hasStats, isFalse);
    });
  });

  group('MediumProfileParser.fromJsonString', () {
    test('parses the JSON the injected script returns', () {
      final raw = jsonEncode({
        'handle': 'janedoe',
        'title': 'Jane Doe on Medium',
        'followers': '1.2K Followers',
      });

      final profile = MediumProfileParser.fromJsonString(raw);

      expect(profile?.handle, 'janedoe');
      expect(profile?.followerCount, 1200);
    });

    test('returns null for empty and malformed payloads', () {
      expect(MediumProfileParser.fromJsonString(null), isNull);
      expect(MediumProfileParser.fromJsonString(''), isNull);
      expect(MediumProfileParser.fromJsonString('not json'), isNull);
      expect(MediumProfileParser.fromJsonString('"a string"'), isNull);
      expect(MediumProfileParser.fromJsonString('[1,2,3]'), isNull);
    });
  });

  group('MediumProfile', () {
    const profile = MediumProfile(
      handle: 'janedoe',
      name: 'Jane Doe',
      bio: 'Hello',
      avatarUrl: 'https://cdn.medium.com/v2/jane.jpg',
      followerCount: 12,
      publicationCount: 3,
    );

    test('builds the public profile URL', () {
      expect(profile.profileUrl, 'https://medium.com/@janedoe');
    });

    test('round-trips through JSON', () {
      expect(MediumProfile.fromJson(profile.toJson()), profile);
    });

    test('copyWith replaces only what it is given', () {
      final updated = profile.copyWith(followerCount: 99);

      expect(updated.followerCount, 99);
      expect(updated.name, profile.name);
      expect(updated.bio, profile.bio);
    });

    test('survives a JSON round trip through the store', () {
      final decoded = MediumProfile.fromJson(
        jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>,
      );

      expect(decoded, profile);
    });
  });
}
