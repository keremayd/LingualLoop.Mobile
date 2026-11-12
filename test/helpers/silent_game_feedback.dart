import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/services/GameFeedbackService.dart';

/// Oyun ekranlarını kuran testler için ses ve titreşimsiz geri bildirim.
class SilentGameFeedback extends Fake implements GameFeedbackService {
  @override
  Future<void> preload() async {}

  @override
  void correct() {}

  @override
  void wrong() {}

  @override
  void complete() {}
}
