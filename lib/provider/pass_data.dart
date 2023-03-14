import 'package:flutter/cupertino.dart';

class PassAllData extends ChangeNotifier{

  late String _userId;
  late String _otherUserId;
  late String _otherUserName;

  void setUserId(String id){
    _userId = id;
    notifyListeners();
  }

  String? getUserId(){
    return _userId;
  }

  void setOtherUserId(String id){
    _otherUserId = id;
    notifyListeners();
  }

  String? getOtherUserId(){
    return _otherUserId;
  }

  // ==============================


}