import 'package:flutter/material.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/ui/widgets/mini_player.dart';

class MusicDockView extends StatelessWidget {
  const MusicDockView({required this.music, required this.child, super.key});

  final MusicController music;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListenableBuilder(
            listenable: music,
            child: child,
            builder: (context, child) => MediaQuery.removePadding(
              context: context,
              removeBottom: music.hasTrack,
              child: child!,
            ),
          ),
        ),
        MiniPlayer(music: music),
      ],
    );
  }
}
