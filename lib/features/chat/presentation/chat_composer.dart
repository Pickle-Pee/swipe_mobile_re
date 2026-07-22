import 'package:flutter/material.dart';

import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/liquid_ui.dart';
import '../application/chat_socket.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.connectionState,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ChatConnectionState connectionState;
  final bool isSending;
  final VoidCallback onSend;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend =
        widget.controller.text.trim().isNotEmpty &&
        !widget.isSending &&
        widget.connectionState == ChatConnectionState.connected;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppTokens.space12,
        AppTokens.space4,
        AppTokens.space12,
        AppTokens.space8,
      ),
      child: GlassSurface(
        key: const Key('chat-composer'),
        level: GlassLevel.overlay,
        radius: AppTokens.radiusLarge,
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space16,
          AppTokens.space8,
          AppTokens.space8,
          AppTokens.space8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const Key('chat-message-input'),
                controller: widget.controller,
                focusNode: widget.focusNode,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: AppTokens.space12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.space8),
            Semantics(
              button: true,
              enabled: canSend,
              label: widget.isSending ? 'Sending message' : 'Send message',
              onTap: canSend ? widget.onSend : null,
              excludeSemantics: true,
              child: SizedBox.square(
                dimension: AppTokens.minTouchTarget,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: canSend ? AppTokens.ctaGradient : null,
                    color: canSend ? null : AppTokens.backgroundElevated,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    key: const Key('chat-send'),
                    onPressed: canSend ? widget.onSend : null,
                    tooltip: 'Send',
                    icon: widget.isSending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTextChanged() => setState(() {});
}
