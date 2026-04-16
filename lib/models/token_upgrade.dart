import 'token.dart';

enum UpgradeRecipeType {
  bronzeToSilver,
  silverToGold,
  goldToPlatinum;

  String get displayName {
    switch (this) {
      case UpgradeRecipeType.bronzeToSilver:
        return '5 Bronze → 1 Silber';
      case UpgradeRecipeType.silverToGold:
        return '5 Silber → 1 Gold';
      case UpgradeRecipeType.goldToPlatinum:
        return '5 Gold → 1 Platin';
    }
  }

  int get requiredAmount => 5;
}

class TokenUpgradeRecipe {
  final String id;
  final String landmarkId;
  final String landmarkName;
  final UpgradeRecipeType type;
  final int requiredAmount;
  final int bonusCoins;

  TokenUpgradeRecipe({
    required this.id,
    required this.landmarkId,
    required this.landmarkName,
    required this.type,
    this.requiredAmount = 5,
    this.bonusCoins = 0,
  });

  bool canUpgrade(List<Token> tokens) {
    final tokensForLandmark = tokens.where((t) => t.landmarkId == landmarkId);
    
    switch (type) {
      case UpgradeRecipeType.bronzeToSilver:
        return tokensForLandmark.where((t) => t.tier == TokenTier.bronze).length >= requiredAmount;
      case UpgradeRecipeType.silverToGold:
        return tokensForLandmark.where((t) => t.tier == TokenTier.silver).length >= requiredAmount;
      case UpgradeRecipeType.goldToPlatinum:
        return tokensForLandmark.where((t) => t.tier == TokenTier.gold).length >= requiredAmount;
    }
  }

  TokenTier get inputTier {
    switch (type) {
      case UpgradeRecipeType.bronzeToSilver:
        return TokenTier.bronze;
      case UpgradeRecipeType.silverToGold:
        return TokenTier.silver;
      case UpgradeRecipeType.goldToPlatinum:
        return TokenTier.gold;
    }
  }

  TokenTier get outputTier {
    switch (type) {
      case UpgradeRecipeType.bronzeToSilver:
        return TokenTier.silver;
      case UpgradeRecipeType.silverToGold:
        return TokenTier.gold;
      case UpgradeRecipeType.goldToPlatinum:
        return TokenTier.platinum;
    }
  }
}
