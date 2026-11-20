import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:nsysu_ap/utils/app_localizations.dart';

/// Existing announcements have plain descriptions. New rich descriptions use
/// a marked HTML fragment in the same API field.
const String carouselArticleTag = '<article data-carousel="1">';

bool isCarouselArticle(String description) =>
    description.startsWith(carouselArticleTag);

String carouselExcerpt(String description) {
  if (!isCarouselArticle(description)) return description;
  final dom.DocumentFragment fragment = html.parseFragment(description);
  for (final dom.Element block in fragment.querySelectorAll('br,p,li')) {
    block.append(dom.Text(' '));
  }
  return fragment.text?.trim() ?? '';
}

Uri? carouselUrl(String value) {
  final Uri? uri = Uri.tryParse(value.trim());
  return uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.isNotEmpty
      ? uri
      : null;
}

// Only native text formatting is accepted from a remotely supplied article.
String _formattedBody(String source) {
  final dom.DocumentFragment fragment = html.parseFragment(source);
  const Set<String> tags = <String>{
    'article',
    'p',
    'br',
    'strong',
    'em',
    'b',
    'i',
    'ul',
    'ol',
    'li',
    'span',
    'a',
  };
  for (final dom.Element node in fragment.querySelectorAll('*')) {
    if (!tags.contains(node.localName)) {
      node.replaceWith(dom.Text(node.text));
      continue;
    }
    final Uri? href = carouselUrl(node.attributes['href'] ?? '');
    final Iterable<String> styles = (node.attributes['style'] ?? '')
        .split(';')
        .map((String style) => style.trim())
        .where(
          (String style) => RegExp(
            r'^(font-size:\s*(0\.75|1\.5|2\.5)em|padding-(left|right):\s*\d{1,2}(?:\.0)?em)$',
          ).hasMatch(style),
        );
    node.attributes.clear();
    if (styles.isNotEmpty) node.attributes['style'] = styles.join(';');
    if (node.localName == 'a' && href != null) {
      node.attributes['href'] = href.toString();
    }
  }
  return fragment.outerHtml;
}

class CarouselArticlePage extends StatelessWidget {
  const CarouselArticlePage({super.key, required this.item});
  final Announcement item;

  @override
  Widget build(BuildContext context) {
    if (!isCarouselArticle(item.description)) {
      return AnnouncementContentPage(announcement: item);
    }
    return Scaffold(
      appBar: AppBar(title: Text(ap.announcements)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[CarouselArticle(item: item)],
        ),
      ),
    );
  }
}

class CarouselArticle extends StatelessWidget {
  const CarouselArticle({super.key, required this.item});
  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final TextTheme type = Theme.of(context).textTheme;
    final Uri? link = carouselUrl(item.url ?? '');
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (item.imgUrl.isNotEmpty)
              Semantics(
                button: true,
                label: app.carouselZoom,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: Text(item.title)),
                        body: Center(
                          child: InteractiveViewer(
                            maxScale: 5,
                            child: CarouselCover(url: item.imgUrl),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CarouselCover(url: item.imgUrl),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: SelectableText(
                item.title,
                style: type.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (carouselExcerpt(item.description).isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              SelectionArea(
                child: HtmlWidget(
                  _formattedBody(item.description),
                  textStyle: type.bodyLarge,
                  onTapUrl: (String url) async {
                    final Uri? uri = carouselUrl(url);
                    if (uri == null) return false;
                    await PlatformUtil.instance.launchUrl(uri.toString());
                    return true;
                  },
                ),
              ),
            ],
            if (link != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: Text(app.carouselOpenLink),
                  onPressed: () =>
                      PlatformUtil.instance.launchUrl(link.toString()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CarouselCover extends StatelessWidget {
  const CarouselCover({super.key, required this.url});
  final String url;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Image.network(
      url,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (_, Object error, StackTrace? stack) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    ),
  );
}
