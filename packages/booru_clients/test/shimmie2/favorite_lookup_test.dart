import 'dart:io';

import 'package:booru_clients/src/shimmie2/shimmie2_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

String _posts(int total, List<int> ids) =>
    "<posts count='$total' offset='0'>"
    "${ids.map((id) => "<tag id='$id' file_url='/_images/$id/x.jpg' />").join()}"
    '</posts>';

void main() {
  group('favorite lookup', () {
    late HttpServer server;
    late String baseUrl;
    late List<String> receivedTags;
    late List<String?> receivedPages;
    late List<List<int>> pagedResponses;
    late int totalCount;

    setUp(() async {
      receivedTags = [];
      receivedPages = [];
      pagedResponses = [];
      totalCount = 0;

      server = await shelf_io.serve(
        (request) {
          receivedTags.add(request.url.queryParameters['tags'] ?? '');
          receivedPages.add(request.url.queryParameters['page']);

          final page = int.tryParse(request.url.queryParameters['page'] ?? '1');
          final ids =
              pagedResponses.elementAtOrNull((page ?? 1) - 1) ?? const [];

          return Response.ok(
            _posts(totalCount, ids),
            headers: {'content-type': 'application/xml'},
          );
        },
        InternetAddress.loopbackIPv4,
        0,
      );

      baseUrl = 'http://${server.address.host}:${server.port}';
    });

    tearDown(() async => server.close(force: true));

    Shimmie2Client client() => Shimmie2Client(baseUrl: baseUrl);

    test(
      'scopes the query to the user and the id range of the batch',
      () async {
        totalCount = 1;
        pagedResponses = [
          [30],
        ];

        await client().filterFavoritedPostIds(
          username: 'noxc',
          postIds: [50, 10, 30],
        );

        expect(receivedTags.single, 'favorited_by=noxc id>=10 id<=50');
      },
    );

    test(
      'returns only the requested ids that came back as favorited',
      () async {
        totalCount = 3;
        pagedResponses = [
          [30, 50, 41],
        ];

        final result = await client().filterFavoritedPostIds(
          username: 'noxc',
          postIds: [50, 10, 30],
        );

        expect(result, [50, 30]);
      },
    );

    test('keeps paging until every match in the range is collected', () async {
      totalCount = 150;
      pagedResponses = [
        List.generate(100, (i) => i + 1),
        [140, 150],
      ];

      final result = await client().filterFavoritedPostIds(
        username: 'noxc',
        postIds: [5, 140, 150, 999],
      );

      expect(receivedPages, ['1', '2']);
      expect(result, [5, 140, 150]);
    });

    test('makes no request when there is nothing to check', () async {
      final result = await client().filterFavoritedPostIds(
        username: 'noxc',
        postIds: [],
      );

      expect(result, isEmpty);
      expect(receivedTags, isEmpty);
    });

    test('makes no request for an anonymous user', () async {
      final result = await client().filterFavoritedPostIds(
        username: '',
        postIds: [1, 2],
      );

      expect(result, isEmpty);
      expect(receivedTags, isEmpty);
    });
  });
}
