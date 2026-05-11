import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../services/gemini_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messages = <ChatMessage>[];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  // ✅ Nueva instancia cada vez — sin singleton que cachea key vieja
  late final GeminiService _gemini;
  bool _typing = false;

  final List<String> _suggestions = [
    '¿En qué gasto más?',
    '¿Cómo puedo ahorrar más?',
    '¿Cómo está mi salud financiera?',
    '¿Cuáles son mis ingresos?',
    'Dame un consejo financiero',
  ];

  @override
  void initState() {
    super.initState();
    _gemini = GeminiService();
    final p = context.read<FinanceProvider>();
    _gemini.startNewChat(p.financialSummaryForAI);

    _messages.add(ChatMessage(
      text: _gemini.isAvailable
          ? '¡Hola! Soy FinIA, tu asistente de My Money IA 💰\n\n'
            '¿En qué puedo ayudarte hoy?'
          : '⚙️ Para activar el asistente IA:\n\n'
            '1. Ve a: https://aistudio.google.com/app/apikey\n'
            '2. Crea tu API Key GRATIS\n'
            '3. Ábrela en:\n'
            '   lib/services/gemini_service.dart\n'
            '4. Reemplaza AQUI_TU_NUEVA_API_KEY\n'
            '5. Ejecuta: flutter clean && flutter run\n\n'
            'Mientras tanto puedes usar el resto de la app normalmente 😊',
      isUser: false,
    ));
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send([String? preset]) async {
    final text = preset ?? _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() { _messages.add(ChatMessage(text: text, isUser: true)); _typing = true; });
    _scrollDown();
    final response = await _gemini.sendMessage(text);
    setState(() { _typing = false; _messages.add(ChatMessage(text: response, isUser: false)); });
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle), child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20)))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('FinIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(_gemini.isAvailable ? '● En línea' : '○ Sin configurar', style: TextStyle(fontSize: 11, color: _gemini.isAvailable ? Colors.green : Colors.orange)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          itemCount: _messages.length + (_typing ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == _messages.length) {
              return _BubbleWidget(isUser: false, child: Row(mainAxisSize: MainAxisSize.min, children: [
                _dot(), const SizedBox(width: 4), _dot(), const SizedBox(width: 4), _dot(),
              ]));
            }
            return _MessageBubble(message: _messages[i]);
          },
        )),
        if (_messages.length <= 2)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: _suggestions.map((s) => Padding(padding: const EdgeInsets.only(right: 8), child: ActionChip(label: Text(s, style: const TextStyle(fontSize: 12)), onPressed: () => _send(s)))).toList()),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))]),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: '¿En qué puedo ayudarte?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _send(),
              textInputAction: TextInputAction.send,
            )),
            const SizedBox(width: 8),
            MaterialButton(
              onPressed: _typing ? null : () => _send(),
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(14),
              minWidth: 0,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _dot() => Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.6), shape: BoxShape.circle));
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(width: 30, height: 30, margin: const EdgeInsets.only(right: 8, bottom: 4), decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle), child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14)))),
          ],
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: message.isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(message.isUser ? 18 : 4), bottomRight: Radius.circular(message.isUser ? 4 : 18)),
            ),
            child: Text(message.text, style: TextStyle(color: message.isUser ? Colors.white : null, height: 1.4)),
          )),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _BubbleWidget extends StatelessWidget {
  final bool isUser; final Widget child;
  const _BubbleWidget({required this.isUser, required this.child});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(18)), child: child),
    ]));
  }
}
