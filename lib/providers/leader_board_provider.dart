import 'package:flutter/material.dart';
import 'package:MeezanSync/models/model.dart';

class LeaderBoardProvider extends ChangeNotifier {
  List<LeaderBoardItem> _leaderBoard = [];
  List<LeaderBoardItem> get leaderBoard => _leaderBoard;

  void setLeaderBoard(List<LeaderBoardItem> leaderBoard) {
    _leaderBoard = leaderBoard;
    notifyListeners();
  }
}
