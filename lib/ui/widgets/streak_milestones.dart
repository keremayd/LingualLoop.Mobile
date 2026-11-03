/// Seri hedeflerinin tek kaynağı; profil hedef kartı da bunu kullanır.
class StreakMilestones {
  const StreakMilestones._();

  static const days = [3, 7, 14, 30, 50, 100, 200, 365];

  static int? next(int streak) {
    for (final day in days) {
      if (day > streak) return day;
    }
    return null;
  }
}
