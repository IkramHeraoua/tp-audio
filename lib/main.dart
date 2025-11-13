import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

void main() {
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
  final AudioPlayer _player = AudioPlayer();
  final List<String> _playlist = [
    'assets/sounds/song1.mp3',
    'assets/sounds/song2.mp3',
    'assets/sounds/song3.mp3',
    'assets/sounds/song4.mp3',
  ];
  int _currentIndex = 0;

  /// Liste des morceaux likés
  final Set<int> _likedSongs = {};

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.setAudioSource(
      ConcatenatingAudioSource(
        children: _playlist.map((path) => AudioSource.asset(path)).toList(),
      ),
    );

    // Passer au morceau suivant automatiquement
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _nextTrack();
      }
    });
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

  void _openLikedSongsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LikedSongsPage(
          likedSongs: _likedSongs.map((i) => _playlist[i]).toList(),
        ),
      ),
    );
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest2<Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.durationStream,
        (position, duration) => PositionData(position, duration ?? Duration.zero),
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Lecteur Audio"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            color: Colors.redAccent,
            onPressed: _openLikedSongsPage,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Artwork
            Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                color: Colors.green.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  const Icon(Icons.music_note, size: 100, color: Colors.white),
            ),
            const SizedBox(height: 30),

            // Titre
            Text(
              'Morceau ${_currentIndex + 1}',
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            // Bouton like ❤️
            IconButton(
              iconSize: 35,
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.grey,
              ),
              onPressed: _toggleLike,
            ),

            const SizedBox(height: 20),

            // Barre de progression
            StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data ??
                    PositionData(
                        Duration.zero, _player.duration ?? Duration.zero);
                return Column(
                  children: [
                    Slider(
                      min: 0,
                      max: positionData.duration.inMilliseconds.toDouble(),
                      value: positionData.position.inMilliseconds
                          .clamp(0, positionData.duration.inMilliseconds)
                          .toDouble(),
                      onChanged: (value) {
                        _player.seek(Duration(milliseconds: value.toInt()));
                      },
                      activeColor: Colors.green,
                      inactiveColor: Colors.green.shade100,
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(positionData.position)),
                          Text(_formatDuration(positionData.duration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            // Contrôles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 40,
                  onPressed: _previousTrack,
                  icon: const Icon(Icons.skip_previous),
                ),
                const SizedBox(width: 20),
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
                const SizedBox(width: 20),
                IconButton(
                  iconSize: 40,
                  onPressed: _nextTrack,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

/// Page qui affiche les musiques likées
class LikedSongsPage extends StatelessWidget {
  final List<String> likedSongs;

  const LikedSongsPage({super.key, required this.likedSongs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Musiques Likées"),
        centerTitle: true,
      ),
      body: likedSongs.isEmpty
          ? const Center(
              child: Text(
                "Aucune musique likée pour le moment ❤️",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: likedSongs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text("Morceau ${index + 1}"),
                  subtitle: Text(likedSongs[index]),
                );
              },
            ),
    );
  }
}

class PositionData {
  final Duration position;
  final Duration duration;
  PositionData(this.position, this.duration);
}
