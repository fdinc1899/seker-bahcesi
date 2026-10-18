/// A three-star reward is granted only the first time a level reaches
/// three stars. The existing saved best-star map is the source of truth,
/// so no new persistent save field or migration is needed.
class StarPrize {
  const StarPrize({required this.bonusShuffles});

  final int bonusShuffles;

  bool get awarded => bonusShuffles > 0;
}

StarPrize prizeForLevel({required int previousBest, required int stars}) {
  final best = previousBest.clamp(0, 3);
  final now = stars.clamp(0, 3);
  return StarPrize(bonusShuffles: now == 3 && best < 3 ? 1 : 0);
}
