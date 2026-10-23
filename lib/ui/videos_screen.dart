import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/library/video_filter.dart';
import 'package:papuy/library/video_item.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/settings/sort_key.dart';
import 'package:papuy/theme/app_motion.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/ui/player_screen.dart';
import 'package:papuy/ui/stream_dialog.dart';
import 'package:papuy/ui/video_actions_sheet.dart';
import 'package:papuy/ui/video_menu_sheet.dart';
import 'package:papuy/ui/widgets/choice_sheet.dart';
import 'package:papuy/ui/widgets/fade_slide_in.dart';
import 'package:papuy/ui/widgets/page_frame.dart';
import 'package:papuy/ui/widgets/video_grid_tile.dart';
import 'package:papuy/ui/widgets/video_tile.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({
    required this.settings,
    required this.library,
    required this.music,
    super.key,
  });

  final AppSettings settings;
  final LibraryController library;
  final MusicController music;

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  static const double _stripHeight = 172;
  static const double _stripTileWidth = 150;
  static const double _gridGap = AppSpacing.sm;
  static const double _tileText = 74;

  final Set<String> _expanded = <String>{};
  bool _searching = false;
  String _query = '';
  VideoFilter _filter = VideoFilter.all;

  AppSettings get _settings => widget.settings;
  LibraryController get _library => widget.library;

  Future<void> _play(List<VideoItem> playlist, int index) {
    return PlayerScreen.open(
      context,
      settings: _settings,
      library: _library,
      playlist: playlist,
      index: index,
    );
  }

  Future<void> _stream() async {
    final url = await askStreamUrl(context);
    if (url == null || url.isEmpty || !mounted) return;
    final name = Uri.tryParse(url)?.pathSegments.lastWhere(
              (segment) => segment.isNotEmpty,
              orElse: () => url,
            ) ??
        url;
    await _play(<VideoItem>[VideoItem.external(url, name)], 0);
  }

  Future<void> _openMenu() async {
    final action = await showVideoMenu(context, _settings);
    if (action == null || !mounted) return;
    switch (action) {
      case VideoMenuAction.sort:
        final picked = await showChoices<SortKey>(
          context,
          title: 'Sort by',
          value: _settings.sort,
          options: <SortKey, String>{
            for (final key in SortKey.values) key: key.label,
          },
        );
        if (picked != null) _settings.sort = picked;
      case VideoMenuAction.stream:
        await _stream();
      case VideoMenuAction.refresh:
        await _library.load();
    }
  }

  List<Widget> _actions() {
    if (_searching) {
      return [
        Expanded(
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search'.tr,
              isDense: true,
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        IconButton(
          tooltip: 'Close'.tr,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => setState(() {
            _searching = false;
            _query = '';
          }),
        ),
      ];
    }
    return [
      Expanded(
        child: Text(
          'Videos',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      IconButton(
        tooltip: 'Search'.tr,
        icon: const Icon(Icons.search_rounded),
        onPressed: () => setState(() => _searching = true),
      ),
      IconButton(
        tooltip: 'More'.tr,
        icon: const Icon(Icons.more_vert_rounded),
        onPressed: _openMenu,
      ),
    ];
  }

  Widget _message(String text, {String? action, VoidCallback? onAction}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          Text(text),
          if (action != null)
            FilledButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }

  Widget _tile(List<VideoItem> list, int index) {
    final video = list[index];
    void tap() => _play(list, index);
    void hold() => showVideoActions(context, _library, video, tap);
    final tile = _settings.grid
        ? VideoGridTile(
            video: video,
            library: _library,
            onTap: tap,
            onLongPress: hold,
          )
        : VideoTile(
            video: video,
            library: _library,
            onTap: tap,
            onLongPress: hold,
          );
    return FadeSlideIn(index: index, child: tile);
  }

  Widget _group(List<VideoItem> list) {
    if (_settings.grid) {
      return SliverPadding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final extent = constraints.crossAxisExtent;
            final columns = (extent / _settings.gridSize).ceil().clamp(1, 12).toInt();
            final width = (extent - _gridGap * (columns - 1)) / columns;
            final height = (width - 2 * VideoGridTile.padding) * 9 / 16 +
                _tileText +
                2 * VideoGridTile.padding;
            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: _gridGap,
                crossAxisSpacing: _gridGap,
                mainAxisExtent: height,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _tile(list, index),
                childCount: list.length,
              ),
            );
          },
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _tile(list, index),
        childCount: list.length,
      ),
    );
  }

  Widget _chips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          for (final filter in VideoFilter.values)
            ChoiceChip(
              label: Text(filter.label),
              selected: _filter == filter,
              onSelected: (_) => setState(() => _filter = filter),
            ),
        ],
      ),
    );
  }

  Widget _continueStrip(List<VideoItem> list) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xxs,
      children: [
        Text(
          'Continue watching',
          style: theme.textTheme.labelLarge
              ?.copyWith(color: theme.colorScheme.primary),
        ),
        SizedBox(
          height: _stripHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) => SizedBox(
              width: _stripTileWidth,
              child: VideoGridTile(
                video: list[index],
                library: _library,
                onTap: () => _play(list, index),
                onLongPress: () => showVideoActions(
                  context,
                  _library,
                  list[index],
                  () => _play(list, index),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    switch (_library.status) {
      case LibraryStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LibraryStatus.denied:
        return _message(
          'Allow access to your videos',
          action: 'Allow',
          onAction: () => _library.load(ask: true),
        );
      case LibraryStatus.failed:
        return _message(
          "Couldn't read your videos",
          action: 'Try again',
          onAction: _library.load,
        );
      case LibraryStatus.ready:
        break;
    }
    final videos = _library.visible(query: _query, filter: _filter);
    final resumable = _filter == VideoFilter.all && _query.isEmpty
        ? _library.resumable()
        : const <VideoItem>[];

    final slivers = <Widget>[
      SliverToBoxAdapter(child: _chips()),
      if (resumable.isNotEmpty)
        SliverToBoxAdapter(child: _continueStrip(resumable)),
    ];
    if (videos.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text('No videos')),
        ),
      );
    } else if (_settings.groupFolders) {
      final searching = _query.trim().isNotEmpty;
      for (final entry in _library.folders(videos).entries) {
        final open = searching || _expanded.contains(entry.key);
        slivers.add(
          SliverToBoxAdapter(
            child: _FolderHeader(
              name: entry.key,
              count: entry.value.length,
              collapsed: !open,
              onTap: () => setState(() {
                if (!_expanded.remove(entry.key)) _expanded.add(entry.key);
              }),
            ),
          ),
        );
        if (open) slivers.add(_group(entry.value));
      }
    } else {
      slivers.add(_group(videos));
    }
    slivers.add(
      SliverToBoxAdapter(
        child: SizedBox(
          height: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
      ),
    );

    return RefreshIndicator(
      onRefresh: _library.load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_library, _settings]),
      builder: (context, _) => PopScope(
        canPop: !_searching,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          setState(() {
            _searching = false;
            _query = '';
          });
        },
        child: PageFrame(actions: _actions(), child: _body()),
      ),
    );
  }
}

class _FolderHeader extends StatelessWidget {
  const _FolderHeader({
    required this.name,
    required this.count,
    required this.collapsed,
    required this.onTap,
  });

  final String name;
  final int count;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Icon(
              collapsed ? Icons.folder_rounded : Icons.folder_open_rounded,
              color: theme.colorScheme.primary,
            ),
            Expanded(child: Text(name, style: theme.textTheme.labelLarge)),
            Text(
              '$count',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AnimatedRotation(
              turns: collapsed ? -0.25 : 0,
              duration: AppMotion.d(150),
              child: const Icon(Icons.expand_more_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
