import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/column_value_rules.dart';

/// Existing databases hold the allowed values as they were when they were
/// created or upgraded. If an enum gains a value, those databases will refuse
/// it until a migration updates their CHECK or triggers.
///
/// **If this test fails, you changed an enum that the database stores.** Add
/// a schema migration that replaces the triggers (and say how a v5 CHECK
/// database is handled), then update the lists below.
void main() {
  test('MediaType values are the ones the schema allows', () {
    expect(MediaType.values.map((t) => t.name).toList(), <String>[
      'image',
      'video',
      'gif',
      'rawImage',
      'svg',
    ]);
  });

  test('AlbumType values are the ones the schema allows', () {
    expect(AlbumType.values.map((t) => t.name).toList(), <String>[
      'physicalFolder',
      'virtualAlbum',
      'smartFavorites',
      'smartVideos',
      'smartGifs',
      'smartRaw',
      'smartPanoramas',
      'smartRecentlyAdded',
      'smartTrash',
    ]);
  });

  test('a rule builds a CHECK and a pair of triggers', () {
    const rule = ColumnValueRule.mediaIsTrash;
    expect(rule.check, 'CHECK (is_trash IN (0,1))');
    expect(rule.triggerSql, hasLength(2));
    expect(rule.triggerSql.first, contains('BEFORE INSERT ON media_items'));
    expect(rule.triggerSql.last, contains('BEFORE UPDATE OF is_trash'));
    expect(rule.triggerSql.every((t) => t.contains('RAISE(ABORT')), isTrue);
  });

  test('the out-of-reach flag allows only 0 and 1', () {
    expect(
      ColumnValueRule.mediaIsOutOfReach.check,
      'CHECK (is_out_of_reach IN (0,1))',
    );
    expect(ColumnValueRule.all, contains(ColumnValueRule.mediaIsOutOfReach));
    expect(
      ColumnValueRule.addedAfterV5,
      contains(ColumnValueRule.mediaIsOutOfReach),
    );
  });

  test('a quote inside a value is escaped', () {
    expect(ColumnValueRule.quoted(<String>["it's"]), "'it''s'");
  });
}
