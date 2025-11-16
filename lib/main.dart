import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:ui';
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.musique.player.channel.audio',
    androidNotificationChannelName: 'Music Playback',
    androidNotificationOngoing: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lecteur Audio Complet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MusicPlayerPage(),
    );
  }
}

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  late AudioPlayer _player;
  final List<String> _playlist = [
    'assets/sounds/song1.mp3',
    'assets/sounds/song2.mp3',
    'assets/sounds/song3.mp3',
    'assets/sounds/song4.mp3',
  ];

  int _currentIndex = 0;

  final List<String> _covers = [
    'assets/images/cover1.jpg',
    'assets/images/cover2.jpg',
    'assets/images/cover3.jpg',
    'assets/images/cover4.jpg',
  ];

  final List<String> _artists = [
    'Artiste 1',
    'Artiste 2',
    'Artiste 3',
    'Artiste 4',
  ];

  LoopMode _loopMode = LoopMode.off;
  final Set<int> _likedSongs = {};

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
    _updateDominantColor();
  }

  Future<void> _initPlayer() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final List<AudioSource> sources = [];

      for (int i = 0; i < _playlist.length; i++) {
        sources.add(
          AudioSource.asset(
            _playlist[i],
            tag: MediaItem(
              id: i.toString(),
              title: "Morceau ${i + 1}",
              artist: _artists[i],
              //artUri: Uri.parse('${_covers[i]}')
            ),
          ),
        );
      }

      await _player.setAudioSource(ConcatenatingAudioSource(children: sources));

      _player.currentIndexStream.listen((index) {
        if (index != null) {
          setState(() => _currentIndex = index);
          _updateDominantColor();
        }
      });

      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _nextTrack();
        }
      });
    });
  }

  Future<void> _updateDominantColor() async {
    setState(() {});
  }

  void _playPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
    setState(() {});
  }

  void _nextTrack() {
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      _player.seek(Duration.zero, index: _currentIndex);
      _player.play();
    }
    setState(() {});
  }

  void _previousTrack() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _player.seek(Duration.zero, index: _currentIndex);
      _player.play();
    }
    setState(() {});
  }

  void _toggleLike() {
    setState(() {
      if (_likedSongs.contains(_currentIndex)) {
        _likedSongs.remove(_currentIndex);
      } else {
        _likedSongs.add(_currentIndex);
      }
    });
  }

  void _changeRepeatMode() {
    setState(() {
      if (_loopMode == LoopMode.off) {
        _loopMode = LoopMode.one;
      } else if (_loopMode == LoopMode.one) {
        _loopMode = LoopMode.all;
      } else {
        _loopMode = LoopMode.off;
      }
    });

    _player.setLoopMode(_loopMode);
  }

  void _shuffle() async {
    await _player.setShuffleModeEnabled(true);
    await _player.shuffle();
    setState(() {});
  }

  void _openLikedSongsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              color: Colors.black.withOpacity(0.3),
              child: _likedSongs.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucune musique likée pour le moment ❤️",
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _likedSongs.length,
                      itemBuilder: (context, index) {
                        int songIndex = _likedSongs.elementAt(index);
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                _covers[songIndex],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              "Morceau ${songIndex + 1}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              _artists[songIndex],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }

  void _openAllSongsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              color: Colors.black.withOpacity(0.3),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _playlist.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          _covers[index],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        "Morceau ${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _artists[index],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest2<Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.durationStream,
        (position, duration) =>
            PositionData(position, duration ?? Duration.zero),
      );

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isPlaying = _player.playing;
    bool isLiked = _likedSongs.contains(_currentIndex);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_covers[_currentIndex], fit: BoxFit.cover),
          ),
          // Positioned.fill(
          //   child: BackdropFilter(
          //     filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          //     child: Container(color: Colors.black.withOpacity(0.3)),
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 80),
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.asset(
                    _covers[_currentIndex],
                    width: double.infinity,
                    height: 350,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Morceau ${_currentIndex + 1}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _artists[_currentIndex],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      iconSize: 32,
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                      ),
                      onPressed: _toggleLike,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                StreamBuilder<PositionData>(
                  stream: _positionDataStream,
                  builder: (context, snapshot) {
                    final data =
                        snapshot.data ??
                        PositionData(
                          Duration.zero,
                          _player.duration ?? Duration.zero,
                        );

                    return Column(
                      children: [
                        Slider(
                          min: 0,
                          max: data.duration.inMilliseconds.toDouble(),
                          value: data.position.inMilliseconds
                              .clamp(0, data.duration.inMilliseconds)
                              .toDouble(),
                          onChanged: (value) => _player.seek(
                            Duration(milliseconds: value.toInt()),
                          ),
                          activeColor: Colors.greenAccent,
                          inactiveColor: Colors.white30,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(data.position),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              _formatDuration(data.duration),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 35,
                      icon: const Icon(Icons.shuffle, color: Colors.white),
                      onPressed: _shuffle,
                    ),
                    IconButton(
                      iconSize: 40,
                      onPressed: _previousTrack,
                      icon: const Icon(
                        Icons.skip_previous,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),
                    GestureDetector(
                      onTap: _playPause,
                      child: Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.green.shade400,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    IconButton(
                      iconSize: 40,
                      onPressed: _nextTrack,
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                    ),
                    IconButton(
                      iconSize: 35,
                      icon: Icon(
                        _loopMode == LoopMode.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                        color: _loopMode == LoopMode.off
                            ? Colors.white54
                            : Colors.greenAccent,
                      ),
                      onPressed: _changeRepeatMode,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 100,
            right: 25,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _openAllSongsBottomSheet,
                    child: const Center(
                      child: Icon(
                        Icons.queue_music,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bouton Liked Songs
          Positioned(
            bottom: 100,
            right: 130,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _openLikedSongsBottomSheet,
                    child: const Center(
                      child: Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}

class PositionData {
  final Duration position;
  final Duration duration;
  PositionData(this.position, this.duration);
}
