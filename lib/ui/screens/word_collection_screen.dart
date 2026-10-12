import 'package:flutter/material.dart';
import 'package:lingualloop/models/responses/word_collection_response.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/auth_back_button.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/word_collection_tile.dart';
import 'package:provider/provider.dart';

class WordCollectionScreen extends StatefulWidget {
  const WordCollectionScreen({super.key});

  @override
  State<WordCollectionScreen> createState() => _WordCollectionScreenState();
}

class _WordCollectionScreenState extends State<WordCollectionScreen> {
  static const _background = Color(0xFF041227);
  static const _muted = Color(0xFF8FA0B5);
  static const _blue = Color(0xFF1CB1F5);
  static const _border = Color(0xFF0B2143);

  String _category = 'all';
  WordCollectionResponse? _page;
  final List<WordCollectionItem> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _generation = 0;
  PronunciationService? _audioService;
  final ValueNotifier<({int kartyId, int requestId})?> _activeSpeech =
      ValueNotifier(null);
  int _speechRequestId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioService ??= context.read<PronunciationService>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load('all'));
  }

  @override
  void dispose() {
    _generation++;
    // Bu ekranın başlattığı telaffuz sayfa kapandığında devam etmesin.
    _audioService?.stop();
    _activeSpeech.dispose();
    super.dispose();
  }

  Future<void> _load(String category) async {
    final generation = ++_generation;
    _audioService?.stop();
    _activeSpeech.value = null;
    setState(() {
      _category = category;
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<UserService>().wordCollection(
            category: category,
          );
      if (!mounted || generation != _generation) return;
      if (result.data == null || result.errorCode != null) {
        throw StateError(result.message ?? 'Kelimeler yüklenemedi.');
      }
      setState(() {
        _page = result.data;
        _items
          ..clear()
          ..addAll(result.data!.items);
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = 'Kelimeler yüklenemedi. Tekrar deneyebilirsin.';
      });
    }
  }

  Future<void> _loadMore() async {
    final current = _page;
    if (_loading || _loadingMore || current == null || !current.hasMore) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final result = await context.read<UserService>().wordCollection(
            category: _category,
            page: current.page + 1,
          );
      if (!mounted || generation != _generation) return;
      if (result.data == null || result.errorCode != null) {
        throw StateError(result.message ?? 'Devamı yüklenemedi.');
      }
      setState(() {
        _page = result.data;
        final existing = _items.map((item) => item.kartyId).toSet();
        _items.addAll(
            result.data!.items.where((item) => existing.add(item.kartyId)));
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Diğer kelimeler yüklenemedi.'),
        action: SnackBarAction(label: 'Tekrar dene', onPressed: _loadMore),
      ));
    }
  }

  Future<void> _play(WordCollectionItem item) async {
    if (item.audioUrl == null || item.audioUrl!.isEmpty) return;
    final service = _audioService!;
    await service.ready;
    if (!mounted) return;
    if (service.isMuted.value) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Ses kapalı. Telaffuzu dinlemek için açabilirsin.'),
        action: SnackBarAction(
          label: 'Sesi aç',
          onPressed: () async {
            await service.setMuted(false);
            if (mounted) await _playAudible(item, service);
          },
        ),
      ));
      return;
    }
    await _playAudible(item, service);
  }

  Future<void> _playAudible(
      WordCollectionItem item, PronunciationService service) async {
    final requestId = ++_speechRequestId;
    _activeSpeech.value = (kartyId: item.kartyId, requestId: requestId);
    try {
      await service.play(item.audioUrl);
    } finally {
      if (mounted && _activeSpeech.value?.requestId == requestId) {
        _activeSpeech.value = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 750;
    final count = _page?.totalCount ?? 0;
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 300 * s) _loadMore();
            return false;
          },
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(38 * s, 18 * s, 38 * s, 38 * s),
            children: [
              SizedBox(
                height: 94 * s,
                child: Row(children: [
                  AuthBackButton(
                      scale: s, onPressed: () => Navigator.pop(context)),
                  Expanded(
                    child: Text('Kelimelerim',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppTypography.displayFamily,
                          fontWeight: AppTypography.heading,
                          fontSize: 51 * s,
                          height: 1,
                        )),
                  ),
                  SizedBox(width: 84.75 * s),
                ]),
              ),
              SizedBox(height: 50 * s),
              Text(
                  _page == null
                      ? 'Kelime koleksiyonun'
                      : '$count kelimeyle tanıştın',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: AppTypography.displayFamily,
                    fontWeight: AppTypography.heading,
                    fontSize: 44 * s,
                    height: 1.12,
                  )),
              SizedBox(height: 6 * s),
              Text('Kelimelerine yeniden göz at, seslerini dinle.',
                  style: TextStyle(
                    color: _muted,
                    fontFamily: AppTypography.family,
                    fontWeight: AppTypography.body,
                    fontSize: 25 * s,
                    height: 1.25,
                  )),
              SizedBox(height: 36 * s),
              Row(children: [
                _filter('Tümü', 'all', count, s),
                SizedBox(width: 10 * s),
                _filter('Yeni', 'new', _page?.newCount ?? 0, s),
                SizedBox(width: 10 * s),
                _filter('Tekrar', 'due', _page?.dueCount ?? 0, s),
                SizedBox(width: 10 * s),
                _filter('Artikel', 'article', _page?.articleCount ?? 0, s),
              ]),
              SizedBox(height: 40 * s),
              Text('KELİMELER',
                  style: TextStyle(
                    color: _muted,
                    fontFamily: AppTypography.family,
                    fontWeight: AppTypography.label,
                    fontSize: 22 * s,
                    letterSpacing: 0.5 * s,
                  )),
              SizedBox(height: 16 * s),
              if (_loading)
                const Center(child: CircularProgressIndicator(color: _blue))
              else if (_error != null)
                _message(_error!, s, retry: () => _load(_category))
              else if (_items.isEmpty)
                _message(_emptyMessage, s)
              else
                for (var i = 0; i < _items.length; i++) ...[
                  WordCollectionTile(
                      item: _items[i],
                      category: _category,
                      scale: s,
                      audioService: _audioService!,
                      activeSpeech: _activeSpeech,
                      onPlay: () => _play(_items[i])),
                  SizedBox(height: 23 * s),
                ],
              if (_loadingMore)
                const Center(child: CircularProgressIndicator(color: _blue)),
            ],
          ),
        ),
      ),
    );
  }

  String get _emptyMessage => switch (_category) {
        'new' => 'Yeni tanıştığın kelime yok.',
        'due' => 'Şu an tekrar zamanı gelen kelime yok.',
        'article' => 'Artikel çalışacak kelime yok.',
        _ => 'Henüz bir kelimeyle tanışmadın.',
      };

  Widget _message(String message, double s, {VoidCallback? retry}) => Padding(
        padding: EdgeInsets.symmetric(vertical: 48 * s),
        child: Column(children: [
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _muted,
                  fontFamily: AppTypography.family,
                  fontWeight: AppTypography.body,
                  fontSize: 26 * s)),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('TEKRAR DENE')),
        ]),
      );

  Widget _filter(String label, String category, int count, double s) {
    final selected = _category == category;
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) => Semantics(
          selected: selected,
          label: '$label $count',
          child: DepthPressableButton(
            width: constraints.maxWidth,
            height: 59 * s,
            radius: 22 * s,
            shadowOffset: 5 * s,
            backgroundColor: selected ? _blue : const Color(0xFF163258),
            shadowColor: selected ? const Color(0xFF1B84B5) : _border,
            fontSize: 21 * s,
            onPressed: () => _load(category),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: AppTypography.family,
                        fontWeight: AppTypography.label,
                        fontSize: 21 * s)),
                SizedBox(width: 11 * s),
                Text('$count',
                    style: TextStyle(
                        color: selected ? Colors.white : _muted,
                        fontFamily: AppTypography.family,
                        fontWeight: AppTypography.number,
                        fontSize: 20 * s)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
