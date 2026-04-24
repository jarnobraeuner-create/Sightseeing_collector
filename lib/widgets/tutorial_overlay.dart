import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kTutorialShownKey = 'tutorial_v1_shown';
const bool _kAlwaysShowTutorialForTesting = false;

/// Returns true if the tutorial has NOT been shown yet.
Future<bool> shouldShowTutorial() async {
  if (_kAlwaysShowTutorialForTesting) return true;
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_kTutorialShownKey) ?? false);
}

Future<void> markTutorialShown() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kTutorialShownKey, true);
}

// ── Data model ──────────────────────────────────────────────────────────────

class _TutorialStep {
  final String title;
  final String body;

  const _TutorialStep({
    required this.title,
    required this.body,
  });
}

const List<_TutorialStep> _steps = [
  _TutorialStep(
    title: 'Willkommen bei Sightseeing Collector!',
    body: 'Tippe, um mit dem Tutorial zu starten.',
  ),
  _TutorialStep(
    title: 'Die Karte',
    body:
        'Das ist deine Karte. Hier kannst du eine Stadt auf ganz neue Weise entdecken. '
        'Um eine Sehenswürdigkeit zu entdecken und deiner Sammlung hinzuzufügen, '
        'musst du dich in einem Umkreis von 100 m befinden.\n\n'
        'Wenn du dich im angegebenen Bereich befindest, drücke ganz einfach auf den '
        'Map-Pin, um deinen Sightseeing-Token einzusammeln.',
  ),
  _TutorialStep(
    title: 'Token-Klassen',
    body:
        'Die Sightseeing-Token kommen in 4 verschiedenen Klassen. Es gibt bronzene '
        'Token als Grundlage. Die silbernen Tokens sind die nächste Stufe. Zusammen '
        'mit den goldenen Tokens werden sie wichtig, um Aufgaben und Events zu meistern.\n\n'
        'Die höchste Stufe, die man auf der Karte finden kann, sind die Platin-Tokens. '
        'Es gibt noch eine höhere Stufe: die Monumente. Diese kann man nur erspielen, '
        'indem man zentrale Tokens einer Stadt sammelt und eine spezielle Quest abschließt.',
  ),
  _TutorialStep(
    title: 'Sets',
    body:
        'Die Sets sind das Herzstück von Sightseeing Collector. Hier siehst du, '
        'welche Tokens du schon gesammelt hast und welche dir noch fehlen.\n\n'
        'Mit dem Abschluss eines ganzen Städte-Sets bekommst du den jeweiligen '
        'Stadtwappen-Token!',
  ),
  _TutorialStep(
    title: 'Marktplatz',
    body:
        'Der Marktplatz ist ein virtuelles Auktionshaus, in dem du Token kaufen, '
        'verkaufen oder mit anderen Spielern tauschen kannst.',
  ),
  _TutorialStep(
    title: 'Profil',
    body:
        'In der Profilübersicht siehst du alle deine Tokens in deiner Sammlung und '
        'kannst jeden Token genau ansehen.\n\n'
        'Hier findest du auch das Upgrade-Menü, deine Lootboxen (jeden Tag eine gratis) '
        'und deine Level-Anzeige.',
  ),
  _TutorialStep(
    title: 'Feedback',
    body:
        'Wenn dir etwas auffällt, was man verbessern kann, oder du einen Bug findest, '
        'lass es uns wissen und schreibe es in das Feedbackfeld.',
  ),
  _TutorialStep(
    title: 'Startbonus',
    body:
        'Für den Beginn gibt es eine Lootbox gratis, damit du direkt starten kannst.\n\n'
        'Tippe, um das Tutorial zu schließen und deine Lootbox zu öffnen!',
  ),
];

// ── Public entry point ───────────────────────────────────────────────────────

/// Shows the tutorial as a full-screen dialog.
/// Marks itself as shown when the user finishes or skips.
Future<bool> showTutorial(
  BuildContext context, {
  ValueChanged<int>? onStepChanged,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'tutorial',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
    pageBuilder: (context, _, __) => _TutorialDialog(onStepChanged: onStepChanged),
  );
  return result ?? false;
}

// ── Dialog widget ────────────────────────────────────────────────────────────

class _TutorialDialog extends StatefulWidget {
  final ValueChanged<int>? onStepChanged;

  const _TutorialDialog({this.onStepChanged});

  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.18, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _next() async {
    if (_current < _steps.length - 1) {
      await _slideController.reverse();
      setState(() => _current++);
      widget.onStepChanged?.call(_current);
      _slideController.forward();
    } else {
      _finish();
    }
  }

  void _finish() async {
    await markTutorialShown();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_current];
    final isLast = _current == _steps.length - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151A26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          step.body,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_steps.length, (i) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _current ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: i == _current
                                    ? Colors.lightBlueAccent
                                    : Colors.white24,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isLast ? 'Tippen zum Starten' : 'Tippen für nächste Seite',
                          style: TextStyle(
                            color: Colors.lightBlueAccent[100],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
