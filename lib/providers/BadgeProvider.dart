import 'package:flutter/cupertino.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/services/BadgeService.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:provider/provider.dart';
import 'package:lingualloop/models/Badge.dart';


class BadgeProvider with ChangeNotifier {
  final List<Badge> _badges = [];
  bool _isLoaded = false;

  List<Badge> get badges => List.unmodifiable(_badges); // Dışarıdan değiştirilemez liste
  bool get isLoaded => _isLoaded;

  Future<bool> loadBadges(BuildContext context) async {
    final badgeService = Provider.of<BadgeService>(context, listen: false);

    _badges.clear();
    var apiResponse = await badgeService.getBadgesById();
    if (apiResponse.errorCode == null) {
      _isLoaded = false;
      notifyListeners();

      for (var badges in apiResponse.data!) {
        _badges.add(
          Badge(
            badgeUrl: badges.badge.badgeUrl,
            badgeTitle: badges.badge.badgeTitle,
            badgeDescription: badges.badge.badgeDescription,
            createdDate: badges.badge.createdDate,
          ),
        );
      }

      _isLoaded = true;
      notifyListeners();
      return true;
    }

    return false;
  }
}