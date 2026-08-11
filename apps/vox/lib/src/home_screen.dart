import 'dart:async';

import 'package:capture_core/capture_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_base/shared_base.dart';

import 'detail_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';
import 'vox_interpreter.dart';
import 'vox_theme.dart';

/// Startbildschirm. Aufbau aus dem Bauplan Abschnitt 7: Suchfeld oben,
/// Leerfläche, die letzten Einträge als flache Zeilen ohne Rahmen, unten
/// mittig der Aufnahmeknopf. Kein Willkommenstext, keine Tour.
class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.store, super.key});

  final EntryStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioRecorder _recorder = PlatformAudioRecorder();
  final VoxInterpreter _interpreter = const VoxInterpreter();
  final TextEditingController _query = TextEditingController();

  StreamSubscription<RecordingState>? _stateSub;
  RecordingState _state = RecordingState.idle;

  /// Nicht null, wenn die laufende Aufnahme einen bestehenden Eintrag
  /// erweitert statt einen neuen anzulegen.
  String? _activeEntryId;

  List<Entry>? _searchResults;

  @override
  void initState() {
    super.initState();
    _stateSub = _recorder.state.listen((RecordingState s) {
      if (mounted) {
        setState(() => _state = s);
      }
    });
  }

  @override
  void dispose() {
    unawaited(_stateSub?.cancel());
    unawaited(_recorder.dispose());
    _query.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      await _recorder.start();
    } on StateError catch (e) {
      _report(e.message);
    }
  }

  Future<void> _stop() async {
    final RecordingResult? result = await _recorder.stop();
    if (result == null) {
      return;
    }

    final SttEngine stt = Registry.instance.get<SttEngine>();
    final String entryId = _activeEntryId ??
        (await widget.store.createEntry(title: null)).id;

    String? text;
    try {
      text = (await stt.transcribe(result.path)).text;
    } on SttFailure catch (e) {
      // Eine gescheiterte Transkription nimmt die Aufnahme NICHT mit.
      // Das Segment wird ohne Text angelegt und bleibt nachhörbar.
      _report(e.message);
    }

    await widget.store.appendSegment(
      entryId,
      mediaPath: result.path,
      transcript: text,
      engine: stt.id,
    );

    await _reinterpret(entryId);

    if (mounted) {
      setState(() => _activeEntryId = null);
    }
  }

  /// Nach jeder Änderung an der Segmentkette neu ordnen. Genau das trägt
  /// „die Auswertung aktualisiert sich, ohne dass die App neu lädt".
  Future<void> _reinterpret(String entryId) async {
    final EntryWithSegments? full = await widget.store.byId(entryId);
    if (full == null) {
      return;
    }
    await widget.store.updateData(
      entryId,
      _interpreter.parse(full.fullText).toJson(),
    );
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    final List<Entry> found = await widget.store.search(q);
    if (mounted) {
      setState(() => _searchResults = found);
    }
  }

  Future<void> _open(Entry e) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => DetailScreen(
          store: widget.store,
          entryId: e.id,
          recorder: _recorder,
        ),
      ),
    );
    await _reinterpret(e.id);
  }

  void _report(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool recording = _state == RecordingState.recording;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vox'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Auswertung',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext _) =>
                    InsightsScreen(store: widget.store),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext _) =>
                    SettingsScreen(store: widget.store),
              ),
            ),
          ),
        ],
      ),
      body: AdSafeArea(
        bottomAction: RecordButton(
          state: _state,
          onStart: _start,
          onStop: _stop,
          label: _activeEntryId == null ? 'Aufnehmen' : 'Erweitern',
          // Der Mindestabstand kommt von AdSafeArea. Ohne dieses Flag
          // stünden 32 dp statt 16 dp.
          insideAdSafeArea: true,
        ),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Tokens.m,
                Tokens.s,
                Tokens.m,
                0,
              ),
              child: TextField(
                controller: _query,
                onChanged: _search,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Suchen',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (recording)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Tokens.m),
                child: Waveform(amplitude: _recorder.amplitude),
              ),
            Expanded(child: _list()),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    final List<Entry>? results = _searchResults;
    if (results != null) {
      return results.isEmpty
          ? const Center(child: Text('Nichts gefunden.'))
          : _tiles(results);
    }

    return StreamBuilder<List<Entry>>(
      stream: widget.store.watchAll(),
      builder: (BuildContext context, AsyncSnapshot<List<Entry>> snapshot) {
        final List<Entry> items = snapshot.data ?? const <Entry>[];
        if (items.isEmpty) {
          return const Center(child: Text('Noch nichts aufgenommen.'));
        }
        return _tiles(items);
      },
    );
  }

  /// Flache Zeilen ohne Rahmen, ohne Trennlinien — Papier und Tinte.
  Widget _tiles(List<Entry> items) => ListView.builder(
        // Kein zusätzlicher unterer Abstand nötig: die Liste steckt bereits
        // in AdSafeArea.
        padding: const EdgeInsets.fromLTRB(0, Tokens.s, 0, Tokens.s),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int i) {
          final Entry e = items[i];
          return ListTile(
            title: Text(
              titleOf(e),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              when(e.createdAt),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: VoxTheme.secondary),
            ),
            onTap: () => unawaited(_open(e)),
            trailing: IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Diesen Eintrag erweitern',
              onPressed: () {
                setState(() => _activeEntryId = e.id);
                unawaited(_start());
              },
            ),
          );
        },
      );

  /// Titel eines Eintrags: erst der selbst gesetzte, dann der vom
  /// Interpreter gebildete, zuletzt das Datum.
  static String titleOf(Entry e) {
    final String? own = e.title;
    if (own != null && own.isNotEmpty) {
      return own;
    }
    final Object? fromData = e.data['title'];
    if (fromData is String && fromData.isNotEmpty) {
      return fromData;
    }
    return 'Notiz vom ${when(e.createdAt)}';
  }

  static String when(DateTime d) => '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}
