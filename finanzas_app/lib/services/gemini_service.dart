import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // ✅ PEGA TU API KEY AQUÍ
  static const String _apiKey = 'AQUI_TU_API_KEY';

  GenerativeModel? _model;
  ChatSession? _chat;
  bool _initialized = false;

  GeminiService() {
    _initModel();
  }

  void _initModel() {
    if (_apiKey == 'AQUI_TU_API_KEY' || _apiKey.trim().isEmpty) {
      _initialized = false;
      return;
    }
    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey.trim(),
        generationConfig: GenerationConfig(
          temperature: 0.4,
          maxOutputTokens: 800,
        ),
      );
      _initialized = true;
    } catch (e) {
      _initialized = false;
    }
  }

  bool get isAvailable => _initialized;

  void startNewChat(String financialContext) {
    if (!_initialized || _model == null) return;
    _chat = _model!.startChat(history: [
      Content.text(
        'Eres FinIA de My Money IA. '
        'REGLAS: Responde SIEMPRE en español. Completa SIEMPRE tu respuesta. '
        'Máximo 4 oraciones. Sé directo y usa emojis. '
        'No inventes datos. Solo usa los datos del usuario.\n\n'
        'Datos:\n$financialContext',
      ),
      Content.model([TextPart('¡Hola! Soy FinIA 💰 ¿En qué te ayudo?')]),
    ]);
  }

  Future<String> sendMessage(String message) async {
    if (!_initialized || _model == null) {
      return '⚙️ Configura tu API Key en:\nlib/services/gemini_service.dart\n\nReemplaza AQUI_TU_API_KEY con tu key de:\nhttps://aistudio.google.com/app/apikey';
    }
    _chat ??= _model!.startChat();
    try {
      final response = await _chat!.sendMessage(Content.text(message));
      return response.text ?? 'Sin respuesta. Intenta de nuevo.';
    } on GenerativeAIException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('quota') || msg.contains('429') || msg.contains('rate')) {
        return '⏳ Demasiadas solicitudes seguidas.\n\nEspera 1 minuto e intenta de nuevo.\nEl límite es 15 req/minuto.';
      }
      if (msg.contains('api_key') || msg.contains('invalid') || msg.contains('403')) {
        return '❌ API Key inválida.\nVerifica en: https://aistudio.google.com/app/apikey';
      }
      return '❌ Error: ${e.message}';
    } catch (e) {
      return '❌ Error de conexión. Verifica tu internet.';
    }
  }

  Future<Map<String, dynamic>?> analyzeTransactionText(String description) async {
    if (!_initialized || _model == null) return null;

    final prompt = 'Responde SOLO con JSON válido. Sin texto extra. Sin markdown.\n'
        'Input: "$description"\n'
        'Output exacto: {"tipo":"egreso","categoria":"Comida","monto":50,"descripcion":"Almuerzo"}\n'
        'tipo: "egreso" o "ingreso"\n'
        'monto: número sin símbolo, o null si no hay\n'
        'Categorías egreso: Comida,Transporte,Entretenimiento,Salud,Ropa,Educación,Hogar,Servicios,Otros gastos\n'
        'Categorías ingreso: Salario,Freelance,Inversiones,Regalos,Otros ingresos\n'
        'Ejemplos:\n'
        '"taxi 15"->{"tipo":"egreso","categoria":"Transporte","monto":15,"descripcion":"Taxi"}\n'
        '"sueldo 800"->{"tipo":"ingreso","categoria":"Salario","monto":800,"descripcion":"Salario"}\n'
        '"gasté 50 comida"->{"tipo":"egreso","categoria":"Comida","monto":50,"descripcion":"Comida"}\n'
        'JSON:';

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await _model!.generateContent([Content.text(prompt)]);
        if (res.text == null || res.text!.isEmpty) continue;
        String text = res.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .replaceAll('\n', ' ')
            .trim();
        final start = text.indexOf('{');
        final end = text.lastIndexOf('}');
        if (start == -1 || end == -1 || end <= start) continue;
        text = text.substring(start, end + 1);
        final result = jsonDecode(text) as Map<String, dynamic>;
        if (result.containsKey('tipo')) return result;
      } on GenerativeAIException catch (e) {
        if (e.message.toLowerCase().contains('quota')) return null;
      } catch (_) {}
      if (attempt == 0) await Future.delayed(const Duration(seconds: 2));
    }
    return null;
  }

  // ✅ Solo se llama cuando el usuario lo solicita explícitamente, NO al iniciar
  Future<String> getDailyTip(String financialContext) async {
    if (!_initialized || _model == null) {
      return 'Ahorra al menos el 10% de tus ingresos 💡';
    }
    try {
      final res = await _model!.generateContent([
        Content.text('1 consejo financiero breve (máx 15 palabras). Solo el consejo:\n$financialContext'),
      ]);
      return res.text?.trim() ?? 'Controla tus gastos diarios 💪';
    } catch (_) {
      return 'Pequeños ahorros generan grandes resultados 💪';
    }
  }

  Future<String> generateFinancialInsight(String financialContext) async {
    if (!_initialized || _model == null) return 'Configura tu API Key para análisis IA.';
    try {
      final res = await _model!.generateContent([
        Content.text('Analiza en máx 100 palabras: 1 positivo, 1 mejora, 1 consejo. Emojis:\n$financialContext'),
      ]);
      return res.text ?? 'No se pudo generar análisis.';
    } catch (_) {
      return 'Error de conexión.';
    }
  }
}
