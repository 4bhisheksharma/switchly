import 'package:flutter/foundation.dart';

import '../services/home_service.dart';

class HomeProvider extends ChangeNotifier {
  final HomeService _service;

  HomeProvider({HomeService? service})
      : _service = service ?? HomeService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    await _service.fetchItems();

    _isLoading = false;
    notifyListeners();
  }
}
