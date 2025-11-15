import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  
  // Le constructeur configure le joueur et gère les streams d'état
  AudioPlayerHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  // Surcharge pour gérer l'ajout d'une nouvelle piste
  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // Note : dans une application complète, vous géreriez une liste de lecture
    // Ici, on remplace simplement la piste en cours.
    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(mediaItem.id), tag: mediaItem),
    );
    this.mediaItem.add(mediaItem);
  }

  // Surcharge pour démarrer la lecture
  @override
  Future<void> play() => _player.play();

  // Surcharge pour mettre en pause
  @override
  Future<void> pause() => _player.pause();

  // Surcharge pour arrêter la lecture
  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }
  
  // Surcharge pour chercher une position spécifique
  @override
  Future<void> seek(Duration position) => _player.seek(position);

  // Convertit l'état de just_audio en état d'audio_service
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 3], // Pause/Play, Skip Next/Prev
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}