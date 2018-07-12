
import 'package:flutter_todos/todo.dart';
import 'package:flutter_todos/user.dart';

class ServiceContainer{
  static TodoService _todoService;
  static TodoService getTodoService(){
    if(_todoService == null)
      _todoService = TodoServiceImpl();
    return _todoService;
  }
  static UserService _userService;
  static UserService getUserService(){
    if(_userService == null)
      _userService = UserServiceImpl();
    return _userService;
  }
}