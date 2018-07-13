import 'package:flutter/material.dart';
import 'package:flutter_todos/core/exceptions.dart';
import 'package:flutter_todos/core/reflection.dart';
import 'package:flutter_todos/core/repository.dart';
import 'package:flutter_todos/di.dart';
import 'package:flutter_todos/core/share_prefs.dart';
import 'package:flutter_todos/todo.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import "package:flutter_todos/core/utils.dart" as Utils;
import "package:flutter_todos/strings.dart" as Strings;
@EnableReflection
class User implements Entity<String>{
  @override
  String id;

  String email;
  String password;
  String firstName;
  String lastName;
  List<Role> roles;
  DateTime created;

  User(this.id, this.email, this.password, this.firstName, this.lastName,
      this.roles, this.created);
  User.newInstance({@required this.email, @required this.password, @required this.firstName, @required this.lastName}){
    id = Uuid().v1();
    created = DateTime.now();
    roles = [Role.MEMBER];
  }
  addRole(Role role){
    if(roles.contains(role))
      throw AlreadyExistingException("Vai trò $role đã tồn tại.");
    else
      roles.add(role);
  }
  removeRole(Role role){
    if(roles.contains(role))
      roles.remove(role);
    else
      throw NonExistingException("Vai trò $role không tồn tại.");
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is User &&
              runtimeType == other.runtimeType &&
              email == other.email;

  @override
  int get hashCode => email.hashCode;

}

enum Role{
  MEMBER, ADMIN
}
class LoginInform{
  String email;
  String password;

  LoginInform(this.email, this.password);

}
class SignUpInform{
  String email;
  String password;
  String firstName;
  String lastName;

  SignUpInform(this.email, this.password, this.firstName, this.lastName);

}
abstract class UserService{
  User signUp(SignUpInform inform);
  User login(LoginInform inform);
  User fetchUserByEmail(String email);
  validateLoginInform(LoginInform inform);
  validateSignUpInform(SignUpInform inform);
  saveLoggedUser(User user);
  ///return logged user information
  ///throw a [NonLoggedUserException] exception
  User fetchLoggedUser();
  removeLoggedUser();
}
abstract class SignUpForm{
  requestSignUp();
  SignUpInform fetchSignUpInform();
  validateSignUpInform(SignUpInform inform);
  showMessage(String message);
  showError(String message);
  backToLoginForm(User user);
}
abstract class LoginForm{
  requestLogin();
  LoginInform fetchLoginInform();
  validateLoginInform(LoginInform inform);
  showMessage(String message);
  showError(String error);
  forwardToTodoManagementForm(User user);
  validateLoggedUser();
}

class UserServiceImpl implements UserService{
  BaseRepository<User, String> repository;
  static const CURRENT_USER_KEY = "current-user-key";

  UserServiceImpl(){
    repository = new InMemoryRepository();
    repository.insert(User.newInstance(email: "thopvna@gmail.com", password: "thiendia98", firstName: "Thọ", lastName: "Phạm"));
  }

  @override
  User fetchUserByEmail(String email) {
    return repository.searchFirst(SearchConditions({
      "email": email
    }));
  }

  @override
  User login(LoginInform inform) {
    validateLoginInform(inform);
    User user = fetchUserByEmail(inform.email);
    saveLoggedUser(user);
    return user;
  }

  @override
  User signUp(SignUpInform inform) {
    validateSignUpInform(inform);
    User user = User.newInstance(
        email: inform.email,
        password: inform.password,
        firstName: inform.firstName,
        lastName: inform.lastName
    );
    repository.insert(user);
    return user;
  }

  @override
  validateLoginInform(LoginInform inform) {
    User user = fetchUserByEmail(inform.email);
    if(user == null || user.password != inform.password)
      throw LoginInformInvalidException("Tài khoản | mật khẩu chưa chính xác.");
  }

  @override
  validateSignUpInform(SignUpInform inform) {
    try{
      repository.searchFirst(SearchConditions({
        "email": inform.email
      }));
      throw SignUpInformInvalidException("Tài khoản đã tồn tại.");
    }
    on NotFoundException catch(_){}
  }

  @override
  User fetchLoggedUser() {
    try {
      var email = SharePrefsService.getItem(CURRENT_USER_KEY);
      return fetchUserByEmail(email);
    }
    on BaseException catch(exception){
      print(exception.message);
      throw NonLoggedUserException("Không có dữ liệu đăng nhập.");
    }
  }

  @override
  saveLoggedUser(User user) {
    SharePrefsService.setItem(CURRENT_USER_KEY, user.email);
  }

  @override
  removeLoggedUser() {
    SharePrefsService.removeItem(CURRENT_USER_KEY);
  }
}

class LoginFormWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _LoginFormState();
  }
}
class _LoginFormState extends State<LoginFormWidget> implements LoginForm{
  UserService userService;
  TextEditingController emailController, passwordController;
  _LoginFormState(){
    userService = ServiceContainer.getUserService();
    emailController = TextEditingController(text: "thopvna@gmail.com");
    passwordController = TextEditingController(text: "thiendia98");
  }
  @override
  void initState() {
    super.initState();
    validateLoggedUser();
  }
  @override
  LoginInform fetchLoginInform() {
    return LoginInform(
      emailController.text,
      passwordController.text
    );
  }

  @override
  forwardToTodoManagementForm(User user) {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context){
              return TodoManagementFormWidget(user);
            }
        )
    );
  }

  @override
  validateLoginInform(LoginInform inform) {
    String message;
    if(inform.email.isEmpty)
      message = "Email để trống.";
    else if(inform.password.isEmpty)
      message = "Mật khẩu để trống.";
    if(message != null)
      throw LoginInformInvalidException(message);
  }

  @override
  requestLogin() {
    try{
      LoginInform inform = fetchLoginInform();
      validateLoginInform(inform);
      User user = userService.login(inform);
      forwardToTodoManagementForm(user);
    }
    on LoginInformInvalidException catch(exception){
      showError(exception.message);
    }
    on BaseException catch(exception){
      showError(exception.message);
    }
  }

  @override
  showError(String error) {
    Utils.showMessage(context, "Lỗi", error);
  }

  @override
  showMessage(String message) {
    Utils.showMessage(context, "Thông báo", message);
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        margin: EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            Image(
              image: NetworkImage("https://c1.cdnjav.com/content-01/thumbs/1-lafbd-038-rika-anna-laforet-girl-38-p/images/480x270/27s.jpg")
              , fit: BoxFit.cover,
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: Strings.emailLabel
              ),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: Strings.passwordLabel
              ),
              obscureText: true,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
              child: Center(
                child: RaisedButton(
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  child: Text(Strings.loginLabel),
                  onPressed: requestLogin,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlatButton(
                  child: Text(Strings.signUpLabel),
                  onPressed: forwardToSignUpForm,
                ),
                FlatButton(
                  child: Text(Strings.forgotPasswordLabel),
                  onPressed: forwardToForgetPasswordForm,
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  void forwardToSignUpForm() async{
    User user = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context){
        return SignUpFormWidget();
      })
    );
    emailController.text = user.email;
    passwordController.clear();
  }

  void forwardToForgetPasswordForm() {
    showError("Tính năng này chưa được triển khai.");
  }

  @override
  validateLoggedUser() async {
    try{
      User user = userService.fetchLoggedUser();
      print("User logged ${user.email}");
      forwardToTodoManagementForm(user);
    }
    on NonLoggedUserException catch(exception){
      print(exception);
    }
  }
}
class SignUpFormWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _SignUpFormState();
  }
}
class _SignUpFormState extends State<SignUpFormWidget> implements SignUpForm{
  TextEditingController emailController, passwordController, firstNameController, lastNameController;
  UserService userService;
  _SignUpFormState(){
    userService = ServiceContainer.getUserService();
    emailController = TextEditingController(text: "qwe123@gmail.com");
    passwordController = TextEditingController(text: "12345");
    firstNameController = TextEditingController(text: "Tho");
    lastNameController = TextEditingController(text: "Pham");
  }

  @override
  backToLoginForm(User user) {
    Navigator.pop(context, user);
  }

  @override
  SignUpInform fetchSignUpInform() {
    return SignUpInform(
      emailController.text,
      passwordController.text,
      firstNameController.text,
      lastNameController.text,
    );
  }

  @override
  requestSignUp() {
    try {
      SignUpInform inform = fetchSignUpInform();
      validateSignUpInform(inform);
      User user = userService.signUp(inform);
      showMessage("Bạn đã đăng ký thành Công. Bạn sẽ về trang đăng nhập.", () {
        backToLoginForm(user);
      });
    }
    on BaseException catch(exception){
      showError(exception.message);
    }
  }

  @override
  showError(String message, [void accepted()]) {
    Utils.showMessage(context, "Lỗi", message, accepted);
  }

  @override
  showMessage(String message, [void accepted()]) {
    Utils.showMessage(context, "Thông báo", message, accepted);
  }

  @override
  validateSignUpInform(SignUpInform inform) {
    String message;
    if(inform.email.isEmpty)
      message = "Email để trống.";
    else if(inform.password.isEmpty)
      message = "Mật khẩu để trống.";
    else if(inform.firstName.isEmpty)
      message = "Họ để trống.";
    else if(inform.lastName.isEmpty)
      message = "Tên để trống.";
    if(message != null)
      throw SignUpInformInvalidException(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Đăng ký tài khoản")
      ),
      body: Container(
        margin: EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: Strings.emailLabel,
                hintText: "thopvna@gmail.com"
              ),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: Strings.passwordLabel,
                hintText: "tho456"
              ),
              obscureText: true,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                        labelText: Strings.firstNameLabel,
                        hintText: "Thọ"
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                        labelText: Strings.lastNameLabel,
                        hintText: "Phạm"
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: RaisedButton(
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  child: Text(Strings.signUpLabel),
                  onPressed: requestSignUp,
                ),
              ),
            )
          ],
        ),
      )
    );
  }
}