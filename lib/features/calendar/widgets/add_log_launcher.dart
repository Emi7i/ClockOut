import 'package:material_ui/material_ui.dart';
import 'add_log_button.dart';
import '../../../domain/entities/log_entry.dart';
import 'log_editor_popup.dart';

/// The floating add button plus the popup it opens.
///
/// One controller drives everything so it stays in sync: the plus turns
/// 180° + 45° while the popup grows in the middle of the screen. Layers, bottom
/// to top: a scrim dimming everything (tap to close), the popup, the button —
/// the button stays undimmed on top so it doubles as the close control.
///
/// Must be a direct child of a [Stack] that fills the screen.
class AddLogLauncher extends StatefulWidget {
  const AddLogLauncher({super.key});

  @override
  State<AddLogLauncher> createState() => AddLogLauncherState();
}

class AddLogLauncherState extends State<AddLogLauncher>
    with SingleTickerProviderStateMixin {
  static const double _edge = 18;
  static const double _bottom = 24;

  /// Space left on each side of the popup, and its widest size on big screens.
  static const double _popupMargin = 16;
  static const double _popupMaxWidth = 420;

  /// Dimming over everything except the popup and the button.
  static const Color _scrimColor = Color(0x99000000);

  /// 180° + 45°, in turns.
  static const double _openTurns = 0.625;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  late final Animation<double> _eased = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  late final Animation<double> _turns =
      Tween<double>(begin: 0, end: _openTurns).animate(_eased);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The log being edited while the popup is open, or `null` when adding.
  LogEntry? _editing;

  bool get _isOpen =>
      _controller.status == AnimationStatus.forward ||
      _controller.status == AnimationStatus.completed;

  /// Opens the popup — to add a log, or to edit [editing].
  void open({LogEntry? editing}) {
    setState(() => _editing = editing);
    _controller.forward();
  }

  void _toggle() => _isOpen ? _controller.reverse() : open();

  void _close() => _controller.reverse();

  /// The popup scaled up, as a whole, to nearly the full screen width (its
  /// layout is designed at 209×262 and keeps its proportions).
  Widget _centeredPopup() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 2 * _popupMargin)
            .clamp(LogEditorPopup.width, _popupMaxWidth);
        return SizedBox(
          width: width,
          height: width * LogEditorPopup.height / LogEditorPopup.width,
          child: FittedBox(
            child: LogEditorPopup(
              // A new state per log, so fields never carry over between logs.
              key: ValueKey(_editing?.id),
              editing: _editing,
              onClose: _close,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isOpen = !_controller.isDismissed;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (isOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: FadeTransition(
                    opacity: _eased,
                    child: const ColoredBox(color: _scrimColor),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: FadeTransition(
                    opacity: _eased,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.6, end: 1).animate(_eased),
                      child: _centeredPopup(),
                    ),
                  ),
                ),
              ),
            ],
            Positioned(
              right: _edge,
              bottom: _bottom,
              child: AddLogButton(turns: _turns, onTap: _toggle),
            ),
          ],
        );
      },
    );
  }
}
