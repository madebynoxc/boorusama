// Package imports:
import 'package:booru_clients/shimmie2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

// Project imports:
import 'package:boorusama/boorus/shimmie2/posts/parser.dart';

PostDto parseFirst(String xml) => PostDto.fromXml(
  XmlDocument.parse(xml).findAllElements('tag').first,
  baseUrl: 'https://example.com/',
);

void main() {
  group('media type detection', () {
    final cases = [
      (
        desc: 'file name without an extension but a video file url',
        fileName: 'phprqguo7reg33u1BzCnHA',
        fileUrl: '/_images/b16145fd/14671%20-%20tag%20meta%3Avideo.mp4',
        isVideo: true,
      ),
      (
        desc: 'file name without an extension but a webm file url',
        fileName: 'phprqguo7reg33u1BzCnHA',
        fileUrl: '/_images/b16145fd/14671%20-%20tag.webm',
        isVideo: true,
      ),
      (
        desc: 'file name carrying the extension',
        fileName: 'clip.mp4',
        fileUrl: '/_images/b16145fd/clip.mp4',
        isVideo: true,
      ),
      (
        desc: 'a still image',
        fileName: 'phprqguo7reg33u1BzCnHA',
        fileUrl: '/_images/b16145fd/14671%20-%20tag.jpg',
        isVideo: false,
      ),
    ];

    for (final c in cases) {
      test('reports isVideo=${c.isVideo} for ${c.desc}', () {
        final dto = parseFirst(
          "<posts><tag id='1' file_name='${c.fileName}' "
          "file_url='${c.fileUrl}' /></posts>",
        );

        expect(postDtoToPost(dto, null).isVideo, c.isVideo);
      });
    }
  });
}
