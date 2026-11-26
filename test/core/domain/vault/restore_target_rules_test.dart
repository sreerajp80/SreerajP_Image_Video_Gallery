import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/vault/restore_target_rules.dart';

void main() {
  String photo(String path) =>
      RestoreTargetRules.relativePathFor(path, isVideo: false);
  String video(String path) =>
      RestoreTargetRules.relativePathFor(path, isVideo: true);

  const fallback = RestoreTargetRules.fallback;

  group('kept', () {
    test('a camera photo goes back to DCIM/Camera', () {
      expect(photo('/storage/emulated/0/DCIM/Camera/a.jpg'), 'DCIM/Camera');
    });

    test('a Pictures subfolder is kept, also under /sdcard', () {
      expect(
        photo('/sdcard/Pictures/Screenshots/s.png'),
        'Pictures/Screenshots',
      );
    });

    test('a video may go back to Movies', () {
      expect(video('/storage/emulated/0/Movies/Trips/v.mp4'), 'Movies/Trips');
    });

    test('four levels are allowed', () {
      expect(
        photo('/storage/emulated/0/Pictures/a/b/c/x.jpg'),
        'Pictures/a/b/c',
      );
    });
  });

  group('sent to the fallback', () {
    test('a photo cannot go to Movies', () {
      expect(photo('/storage/emulated/0/Movies/x.jpg'), fallback);
    });

    test('Download, another app folder and the storage root', () {
      expect(photo('/storage/emulated/0/Download/x.jpg'), fallback);
      expect(
        photo('/storage/emulated/0/Android/media/com.whatsapp/x.jpg'),
        fallback,
      );
      expect(photo('/storage/emulated/0/x.jpg'), fallback);
    });

    test('an SD card or any other volume', () {
      expect(photo('/storage/1234-5678/DCIM/Camera/x.jpg'), fallback);
    });

    test('no original path, as after a phone move', () {
      expect(photo(''), fallback);
    });

    test('too deep', () {
      expect(photo('/storage/emulated/0/Pictures/a/b/c/d/x.jpg'), fallback);
    });

    test('a hidden folder, a dot folder or a refused character', () {
      expect(photo('/storage/emulated/0/Pictures/.secret/x.jpg'), fallback);
      expect(photo('/storage/emulated/0/DCIM/../Download/x.jpg'), fallback);
      expect(photo('/storage/emulated/0/Pictures/a:b/x.jpg'), fallback);
    });

    test('the fallback itself is allowed for both kinds', () {
      expect(RestoreTargetRules.isAllowed(fallback, isVideo: false), isTrue);
      expect(RestoreTargetRules.isAllowed(fallback, isVideo: true), isTrue);
    });
  });
}
