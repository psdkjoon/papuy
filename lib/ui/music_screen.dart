import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/library/m3u_import.dart';
import 'package:papuy/library/music_store.dart';
import 'package:papuy/library/track_groups.dart';
import 'package:papuy/library/track_item.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/platform/media_service.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/settings/music_sort.dart';
import 'package:papuy/theme/app_motion.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/ui/name_dialog.dart';
import 'package:papuy/ui/now_playing_screen.dart';
import 'package:papuy/ui/playlist_page.dart';
import 'package:papuy/ui/track_actions_sheet.dart';
import 'package:papuy/ui/track_list_page.dart';
import 'package:papuy/ui/widgets/choice_sheet.dart';
import 'package:papuy/ui/widgets/fade_slide_in.dart';
import 'package:papuy/ui/widgets/page_frame.dart';
import 'package:papuy/ui/widgets/sub_page.dart';
import 'package:papuy/ui/widgets/track_art.dart';
import 'package:papuy/ui/widgets/track_tile.dart';

enum _Tab { songs, albums, artists, playlists }

class MusicScreen extends StatefulWidget {
  const MusicScreen({
    required this.settings,
    required this.library,
    required this.music,
    super.key,
  });

  final AppSettings settings;
  final LibraryController library;
  final MusicController music;

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  static const double _albumExtent = 170;
  static const double _albumText = 56;
  static const double _albumGap = AppSpacing.sm;
  static const double _avatar = 52;

  _Tab _tab = _Tab.songs;
  bool _searching = false;
  String _query = '';

  LibraryController get _library => widget.library;
  MusicController get _music => widget.music;

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
          'Music',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      IconButton(
        tooltip: 'Search'.tr,
        icon: const Icon(Icons.search_rounded),
        onPressed: () => setState(() => _searching = true),
      ),
      if (_tab == _Tab.songs)
        IconButton(
          tooltip: 'Sort by'.tr,
          icon: const Icon(Icons.sort_rounded),
          onPressed: _pickSort,
        ),
    ];
  }

  Future<void> _pickSort() async {
    final picked = await showChoices<MusicSort>(
      context,
      title: 'Sort by',
      value: widget.settings.musicSort,
      options: <MusicSort, String>{
        for (final key in MusicSort.values) key: key.label,
      },
    );
    if (picked != null) widget.settings.musicSort = picked;
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

  Widget _chips() {
    const labels = <_Tab, String>{
      _Tab.songs: 'Songs',
      _Tab.albums: 'Albums',
      _Tab.artists: 'Artists',
      _Tab.playlists: 'Playlists',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          for (final entry in labels.entries)
            ChoiceChip(
              label: Text(entry.value),
              selected: _tab == entry.key,
              onSelected: (_) => setState(() => _tab = entry.key),
            ),
        ],
      ),
    );
  }

  Future<void> _play(List<TrackItem> list, int index) async {
    await _music.playQueue(list, index, resume: true);
    if (mounted) await NowPlayingScreen.open(context, _music);
  }

  Future<void> _shuffle(List<TrackItem> list) async {
    await _music.playShuffled(list);
    if (mounted) await NowPlayingScreen.open(context, _music);
  }

  void _openGroup(String title, List<TrackItem> Function() list) {
    SubPage.open(
      context,
      title: title,
      music: _music,
      child: TrackListPage(tracks: list, music: _music),
    );
  }

  List<Widget> _songs(List<TrackItem> list) {
    return [
      SliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${list.length} songs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.shuffle_rounded),
              label: const Text('Shuffle all'),
              onPressed: () => _shuffle(list),
            ),
          ],
        ),
      ),
      SliverList.builder(
        itemCount: list.length,
        itemBuilder: (context, i) {
          final item = list[i];
          return FadeSlideIn(
            index: i,
            child: TrackTile(
              track: item,
              current: _music.track == item,
              playing: _music.playing,
              onTap: () => _play(list, i),
              onLongPress: () => showTrackActions(context, _music, item),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _albums(List<TrackItem> list) {
    final groups = groupByAlbum(list);
    return [
      SliverLayoutBuilder(
        builder: (context, constraints) {
          final extent = constraints.crossAxisExtent;
          final columns = (extent / _albumExtent).ceil().clamp(2, 8).toInt();
          final width = (extent - _albumGap * (columns - 1)) / columns;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: _albumGap,
              crossAxisSpacing: _albumGap,
              mainAxisExtent: width + _albumText,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _AlbumCard(
                group: groups[i],
                onTap: () => _openGroup(groups[i].name, () => groups[i].tracks),
              ),
              childCount: groups.length,
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _artists(List<TrackItem> list) {
    final groups = groupByArtist(list);
    final theme = Theme.of(context);
    return [
      SliverList.builder(
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final group = groups[i];
          return InkWell(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            onTap: () => _openGroup(group.name, () => group.tracks),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Row(
                spacing: AppSpacing.md,
                children: [
                  TrackArt(
                    track: group.cover,
                    size: _avatar,
                    radius: _avatar / 2,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                        Text(
                          '${group.tracks.length} songs · ${group.albums} albums',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ];
  }

  List<TrackItem> _favoriteTracks() {
    final list = _library.tracksByIds(_music.data.favorites)
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  List<TrackItem> _recentTracks() {
    final ids = _music.data.playedIds.toList()
      ..sort((a, b) => _music.data.lastPlayed(b).compareTo(_music.data.lastPlayed(a)));
    return _library.tracksByIds(ids.take(100));
  }

  List<TrackItem> _topTracks() {
    final ids = _music.data.playedIds.toList()
      ..sort((a, b) => _music.data.plays(b).compareTo(_music.data.plays(a)));
    return _library.tracksByIds(ids.take(100));
  }

  List<TrackItem> _newTracks() {
    final list = List<TrackItem>.of(_library.tracks)
      ..sort((a, b) => b.added.compareTo(a.added));
    return list.take(100).toList();
  }

  Future<void> _importPlaylist() async {
    final picked = await MediaService.pickPlaylist();
    if (picked == null || !mounted) return;
    final result = M3uImport.parse(picked.text, _library.tracks);
    final messenger = ScaffoldMessenger.of(context);
    if (result.ids.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text('No matching songs found'.tr)),
      );
      return;
    }
    final name = await askName(
      context,
      title: 'Import playlist',
      initial: M3uImport.playlistName(picked.name),
      action: 'Import',
    );
    if (name == null || !mounted) return;
    _music.data.create(name, result.ids);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Imported ${result.ids.length} of ${result.total} songs'.tr,
        ),
      ),
    );
  }

  Future<void> _createPlaylist() async {
    final name = await askName(
      context,
      title: 'New playlist',
      action: 'Create',
    );
    if (name == null || !mounted) return;
    final created = _music.data.create(name);
    await PlaylistPage.open(
      context,
      playlist: created,
      music: _music,
      library: _library,
    );
  }

  Widget _listRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            SizedBox.square(
              dimension: _avatar,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _playlists() {
    final needle = _query.trim().toLowerCase();
    final lists = <Playlist>[
      for (final playlist in _music.data.playlists)
        if (needle.isEmpty || playlist.name.toLowerCase().contains(needle))
          playlist,
    ];
    final smart = <(IconData, String, List<TrackItem> Function())>[
      (Icons.favorite_rounded, 'Favorites', _favoriteTracks),
      (Icons.history_rounded, 'Recently played', _recentTracks),
      (Icons.trending_up_rounded, 'Most played', _topTracks),
      (Icons.new_releases_outlined, 'Recently added', _newTracks),
    ];
    return [
      SliverToBoxAdapter(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('New playlist'),
                onPressed: _createPlaylist,
              ),
              TextButton.icon(
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Import .m3u'),
                onPressed: _importPlaylist,
              ),
            ],
          ),
        ),
      ),
      SliverList.list(
        children: [
          for (final entry in smart)
            _listRow(
              icon: entry.$1,
              title: entry.$2,
              subtitle: '${entry.$3().length} songs',
              onTap: () => _openGroup(entry.$2, entry.$3),
            ),
        ],
      ),
      SliverList.builder(
        itemCount: lists.length,
        itemBuilder: (context, i) => _listRow(
          icon: Icons.queue_music_rounded,
          title: lists[i].name,
          subtitle:
              '${_library.tracksByIds(lists[i].tracks).length} songs',
          onTap: () => PlaylistPage.open(
            context,
            playlist: lists[i],
            music: _music,
            library: _library,
          ),
        ),
      ),
    ];
  }

  Widget _body() {
    switch (_library.status) {
      case LibraryStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LibraryStatus.denied:
        return _message(
          'Allow access to your media',
          action: 'Allow',
          onAction: () => _library.load(ask: true),
        );
      case LibraryStatus.failed:
        return _message(
          "Couldn't read your music",
          action: 'Try again',
          onAction: _library.load,
        );
      case LibraryStatus.ready:
        break;
    }
    final list = _library.visibleTracks(_query);
    final slivers = <Widget>[
      SliverToBoxAdapter(child: _chips()),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
    ];
    if (_tab == _Tab.playlists) {
      slivers.addAll(_playlists());
    } else if (list.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text('No music')),
        ),
      );
    } else {
      slivers.addAll(switch (_tab) {
        _Tab.songs => _songs(list),
        _Tab.albums => _albums(list),
        _Tab.artists => _artists(list),
        _Tab.playlists => _playlists(),
      });
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
      child: AnimatedSwitcher(
        duration: AppMotion.d(220),
        child: CustomScrollView(
          key: ValueKey<_Tab>(_tab),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: slivers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_library, _music, _music.data, widget.settings]),
      builder: (context, _) => PopScope(
        canPop: !_searching && _tab == _Tab.songs,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          setState(() {
            _searching = false;
            _query = '';
            _tab = _Tab.songs;
          });
        },
        child: PageFrame(actions: _actions(), child: _body()),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.group, required this.onTap});

  final AlbumGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xxs,
        children: [
          TrackArt(track: group.cover, radius: AppRadius.tile, pixels: 384),
          Text(
            group.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge,
          ),
          Text(
            group.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
