import 'dart:async';

import 'package:capture_core/capture_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_base/shared_base.dart';

import 'vox_interpreter.dart';
import 'vox_theme.dart';

/// Detailansicht. Die Segmentkette ist der Eintrag — deshalb steht sie in
/// der Mitte, und „Erweitern" hängt unten an, statt in einem Menü zu liegen.
///
/// Die vom Interpreter erkannten Felder stehen UNTER dem Transkript,
/// nicht statt seiner. Unter confidence 0.5 entfallen sie ganz.
class DetailScreen extends StatefulWidget {
  const DetailScreen({
    required this.store,
    required this.entryId,
    required this.recorder,
    super.key,
  });

  final EntryStore store;
  final String entryId;
  final AudioRecorder recorder;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final VoxInterpreter _interpreter = const VoxInterpreter();

  StreamSubscription<RecordingState>? _stateSub;
  RecordingState _state = RecordingState.idle;
  EntryWithSegments? _entry;

  @override
  void initState() {
    super.initState();
    _stateSub = widget.recorder.state.listen((RecordingState s) {
      if (mounted) {
        setState(() => _state = s);
      }
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    unawaited(_stateSub?.cancel());
    super.dispose();
  }

  Future<void> _load() async {
    final EntryWithSegments? e = await widget.store.byId(widget.entryId);
    if (mounted) {
      setState(() => _entry = e);
    }
  }

  Future<void> _start() async {
    try {
      await widget.recorder.start();
    } on StateError catch (e) {
      _report(e.message);
    }
  }

  Future<void> _stop() async {
    final RecordingResult? result = await widget.recorder.stop();
    if (result == null) {
      return;
    }

    final SttEngine stt = Registry.instance.get<SttEngine>();
    String? text;
    try {
      text = (await stt.transcribe(result.path)).text;
    } on SttFailure catch (e) {
      _report(e.message);
    }

    await widget.store.appendSegment(
      widget.entryId,
      mediaPath: result.path,
      transcript: text,
      engine: stt.id,
    );

    final EntryWithSegments? full = await widget.store.byId(widget.entryId);
    if (full != null) {
      await widget.store.updateData(
        widget.entryId,
        _interpreter.parse(full.fullText).toJson(),
      );
    }
    await _load();
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
    final EntryWithSegments? e = _entry;

    return Scaffold(
      appBar: AppBar(title: const Text('Eintrag')),
      body: AdSafeArea(
        bottomAction: RecordButton(
          state: _state,
          onStart: _start,
          onStop: _stop,
          label: 'Erweitern',
          insideAdSafeArea: true,
        ),
        child: e == null
            ? const Center(child: CircularProgressIndicator())
            : _body(context, e),
      ),
    );
  }

  Widget _body(BuildContext context, EntryWithSegments e) {
    final VoxResult r = VoxResult.fromJson(e.entry.data);
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Tokens.m, Tokens.m, Tokens.m, 0),
      children: <Widget>[
        Text(
          e.entry.title ?? r.title ?? 'Ohne Titel',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: Tokens.xs),
        Text(
          _dateTime(e.entry.createdAt),
          style: theme.textTheme.labelMedium
              ?.copyWith(color: VoxTheme.secondary),
        ),
        const SizedBox(height: Tokens.l),

        // --- Die Segmentkette. Sie IST der Eintrag. ---
        for (final Segment s in e.segments) ...<Widget>[
          Row(
            children: <Widget>[
              Text(
                _time(s.createdAt),
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: VoxTheme.secondary),
              ),
              const SizedBox(width: Tokens.s),
              Text(
                s.engine,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: VoxTheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: Tokens.xs),
          SelectableText(
            s.transcript ?? '(kein Text — Aufnahme ist erhalten)',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: Tokens.l),
        ],

        // --- Erkannte Felder, UNTER dem Transkript. ---
        if (r.confidence >= 0.5) ...<Widget>[
          Text(
            'Erkannt',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: VoxTheme.secondary),
          ),
          const SizedBox(height: Tokens.s),
          if (r.keywords.isNotEmpty)
            Wrap(
              spacing: Tokens.s,
              runSpacing: Tokens.s,
              children: <Widget>[
                for (final String k in r.keywords) Chip(label: Text(k)),
              ],
            ),
          const SizedBox(height: Tokens.s),
          Text(
            '${r.wordCount} Wörter · ${r.charCount} Zeichen',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: VoxTheme.secondary),
          ),
        ],
        const SizedBox(height: Tokens.m),
      ],
    );
  }

  static String _dateTime(DateTime d) => '${_date(d)} · ${_time(d)}';

  static String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  static String _time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
