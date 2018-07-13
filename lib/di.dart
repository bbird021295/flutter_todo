
import 'package:flutter_todos/core/share_prefs.dart';
import 'package:flutter_todos/todo.dart';
import 'package:flutter_todos/user.dart';


class ServiceContainer{
  static TodoService _todoService;
  static UserService _userService;
  static TodoLoaderService _todoLoader;

  static TodoService getTodoService(){
    if(_todoService == null)
      _todoService = TodoServiceImpl();
    return _todoService;
  }
  static UserService getUserService(){
    if(_userService == null)
      _userService = UserServiceImpl();
    return _userService;
  }


  static TodoLoaderService getTodoLoader() {
    if(_todoLoader == null){
      _todoLoader = TodoLoaderServiceImpl();
    }
    return _todoLoader;
  }
}