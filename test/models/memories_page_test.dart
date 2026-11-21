import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/flashback_memory.dart';
import 'package:in_sreerajp_imgvidgal/models/memories_page.dart';

void main() {
  final memory = FlashbackMemory(
    year: 2025,
    yearsAgo: 1,
    date: DateTime(2025, 8, 29),
    rangeStart: DateTime(2025, 8, 26),
    rangeEnd: DateTime(2025, 9),
    items: const [],
  );

  test('empty page reports itself as empty', () {
    const page = MemoriesPage.empty();

    expect(page.isEmpty, isTrue);
    expect(page.range, MemoriesRange.sameDay);
  });

  test('copyWith and equality behave', () {
    final page = MemoriesPage(
      range: MemoriesRange.sameWeek,
      memories: [memory],
    );

    expect(page.copyWith(), page);
    expect(page.copyWith().hashCode, page.hashCode);
    expect(page.copyWith(range: MemoriesRange.sameDay), isNot(page));
    expect(page.isEmpty, isFalse);
  });
}
