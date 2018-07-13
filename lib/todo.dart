import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_todos/core/exceptions.dart';
import 'package:flutter_todos/core/reflection.dart';
import 'package:flutter_todos/di.dart';
import 'package:flutter_todos/core/repository.dart';
import 'package:flutter_todos/user.dart';
import "package:uuid/uuid.dart";
import "package:english_words/english_words.dart";
import "package:flutter_todos/core/utils.dart" as Utils;
import "package:flutter_todos/strings.dart" as Strings;
@EnableReflection
class Todo implements Entity<String>{
  @override
  String id;

  String title;
  String fields;
  String question;
  String answer;
  DateTime created;
  int reviewTimes;

  ///Creator's email
  String creator;

  Todo(this.id, this.title, this.fields, this.question, this.answer,
      this.created, this.reviewTimes, this.creator);
  Todo.newInstance({@required this.title, @required this.fields, @required this.question, @required this.answer, @required this.creator}){
    id = Uuid().v1();
    created = DateTime.now();
    reviewTimes = 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Todo &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  Todo clone(){
    return Todo(id, title, fields, question, answer, created, reviewTimes, creator);
  }
}

///Triển khai business logic cho nghiệp vụ liên quan tới Todo
abstract class TodoService{
  loadWordDocument(String path);
  searchTodos(User user, String keyword);
  loadTodos(User user);
  addTodo(Todo todo);
  saveTodo(Todo todo);
  addTodos(List<Todo> todos);
}
///Xác định chiều order, [ASC] tăng dần hoặc [DES]giảm dần
enum OrderDirection{
  ASC, DES
}
///Hỗ trợ order các todos
abstract class TodoList{
  List<List<Todo>> listTodos;

  TodoList(List<Todo> todos);

  orderByCreatedTime({OrderDirection direction = OrderDirection.ASC});
  orderByFields({OrderDirection direction = OrderDirection.ASC});
}

abstract class Form{
  showError(String erMessage);
  showMessage(String message);
}

abstract class TodoManagementForm implements Form{
  showTodo(List<Todo> todos);
  showEmptySearchResult();
  searchButtonClicked();
  toTodoCreation();
  toTodoDetail(Todo todo);
}
abstract class TodoCreationForm  implements Form{
  createButtonClicked();
}
abstract class TodoDetailForm  implements Form{
  Todo todo;

  TodoDetailForm(this.todo);
  updateButtonClicked();
}
abstract class TodoLoadForm implements Form{
  requestLoadTodos();
  backToTodoManagementForm();
  showTodos(List<Todo> todos);
  forwardToFileExplorer();
  TodoLoadInform fetchTodoLoadInform();
  requestSaveTodos();
}
abstract class TodoLoaderService{
  List<Todo> parseTodoLoadInform(TodoLoadInform inform);
}
class TodoLoadInform{
  String content;

  TodoLoadInform(this.content);

}



///
///
///
/// Implementation
///
///
///


class TodoServiceImpl implements TodoService{
  InMemoryRepository<Todo, String> repository;
  TodoServiceImpl(){
    repository = InMemoryRepository();
    fake(100);
  }
  fake(int length){
    var fieldses = generateWordPairs().take(length ~/ 10).toList();
    var titles = generateWordPairs().take(length).toList();
    var questions = generateWordPairs().take(length).toList();
    var answers = generateWordPairs().take(length).toList();
    for(int i =0; i < length; i++){
      repository.insert(Todo.newInstance(
          title: titles[i].asCamelCase,
          fields: fieldses[i % fieldses.length].asCamelCase,
          question: questions[i].asCamelCase,
          answer: answers[i].asCamelCase,
          creator: "thopvna@gmail.com"
      ));
    }
    print("Faked, size = $length");
  }
  @override
  loadTodos(User user) {
    return repository.search(SearchConditions({"creator": user.email}));
  }

  @override
  loadWordDocument(String path) {
    // TODO: implement loadWordDocument
  }

  @override
  addTodo(Todo todo) {
    repository.insert(todo);
  }

  @override
  List<Todo> searchTodos(User user, String keyword) {
    keyword = keyword.trim().toLowerCase();
    return repository.search(SearchConditions({
      "creator": user.email,
      "title": keyword,
      "fields": keyword,
      "question": keyword,
      "answer": keyword
    }));
  }

  @override
  saveTodo(Todo todo) {
    repository.update(todo);
  }

  @override
  addTodos(List<Todo> todos) {
    repository.insertAll(todos);
  }
}

class TodoListImpl implements TodoList{

  @override
  List<List<Todo>> listTodos;

  TodoListImpl(List<Todo> todos){
    Map<String, List<Todo>> map = {};
    for(int i =0; i < todos.length; i++){
      Todo todo = todos[i];
      if(map.containsKey(todo.fields)){
        map[todo.fields].add(todo);
      }
      else{
        map[todo.fields] = [todo];
      }
    }
    listTodos = map.values.toList();
  }

  @override
  void orderByFields({OrderDirection direction: OrderDirection.ASC}) {
    listTodos.sort((list1, list2){
      return list1[0].fields.compareTo(list2[0].fields);
    });
  }
  @override
  void orderByCreatedTime({OrderDirection direction: OrderDirection.ASC}) {
    listTodos.forEach((list){
      list.sort((todo1, todo2){
        return todo1.created.millisecondsSinceEpoch.compareTo(todo2.created.millisecondsSinceEpoch);
      });
    });
  }

}

class TodoManagementFormWidget extends StatefulWidget{
  final User member;
  TodoManagementFormWidget(this.member);

  @override
  State<StatefulWidget> createState() {
    return _TodoManagementFormState(member);
  }
}
class _TodoManagementFormState extends State<TodoManagementFormWidget> implements TodoManagementForm{
  User member;
  List<List<Todo>> todos = List();
  TodoService todoService;
  TextEditingController keywordController;
  _TodoManagementFormState(this.member){
    todoService = ServiceContainer.getTodoService();
    keywordController = TextEditingController();
  }
  @override
  void initState() {
    super.initState();
    loadAllTodos();
  }

  @override
  searchButtonClicked() {
    try {
      String keyword = keywordController.text;
      if (keyword.isEmpty)
        showError("Từ khóa tìm kiếm rỗng.");
      else {
        List<Todo> searchResult = todoService.searchTodos(
            member, keywordController.text);
        print("Search completed: size of result = ${searchResult.length}");
        showTodo(searchResult);
      }
    }
    on NotFoundException catch(exception){
      showError(exception.message);
    }
  }

  @override
  showEmptySearchResult() {
    setState(() {
      todos = [];
    });
  }

  @override
  showError(String erMessage) {
    Utils.showMessage(context, "Lỗi", erMessage);
  }

  @override
  showMessage(String message) {
    Utils.showMessage(context, "Thông báo", message);
  }

  @override
  showTodo(List<Todo> todos) {
    print("Show TODO: size ${todos.length}");
    setState(() {
      TodoList list = TodoListImpl(todos);
      list.orderByFields();
      this.todos = list.listTodos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý TODOs"),
        actions: <Widget>[
          FlatButton(
            child: Text("Đăng xuất", style: TextStyle(color: Colors.white),),
            onPressed: requestLogout,
          )
        ],
      ),
      body: RefreshIndicator(
          child: Column(
            children: <Widget>[
              buildSearchBox(),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: buildAddTodoButton()
                  ),
                  Expanded(
                    child: buildLoadTodoButton()
                  )
                ],
              ),
              haveTodos() ? buildTodoList() : buildEmptyTodoList()
            ],
          ),
          onRefresh: onRefreshed
      ),
    );
  }
  Future<Null> onRefreshed() async{
    loadAllTodos();
  }
  bool haveTodos(){
    return todos != null && todos.length > 0;
  }
  Widget buildSearchBox() {
    return ListTile(
      title: TextField(
        controller: keywordController,
        decoration: InputDecoration(
            labelText: "Nhập từ khóa tìm kiếm..."
        ),
      ),
      trailing: RaisedButton(
        child: Text("Tìm kiếm"),
        onPressed: searchButtonClicked
      ),
    );
  }

  Widget buildAddTodoButton() {
    return RaisedButton(
      child: ListTile(
        leading: Icon(Icons.add),
        title: Text("Tạo TODOs"),
      ),
      onPressed: toTodoCreation,
    );
  }

  Widget buildEmptyTodoList() {
    return Expanded(
      child: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.today),
            title: Text("Bạn chưa có TODO nào."),
          )
        ],
      ),
    );
  }

  Widget buildTodoList() {
    return Expanded(
      child: ListView.builder(
        itemBuilder: (context, position){
          return buildFieldsTile(context, position);
        },
        itemCount: todos.length,
      ),
    );
  }

  @override
  toTodoCreation() async{
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context){
          return TodoCreationFormWidget(member);
        }
      )
    );
    loadAllTodos();
  }

  Widget buildFieldsTile(BuildContext context, int position) {
    assert (todos[position] != null);
    assert (todos[position].length > 0);
    List<Todo> fields = todos[position];
    return Column(
      children: <Widget>[
        ListTile(
          leading: Icon(Icons.star, color: Colors.yellow,),
          title: Text("Fields: " + fields[0].fields + " - ${fields.length} TODO"),
        ),
        ListView.builder(
          itemBuilder: (context, position){
            return buildTodoTile(context, fields[position]);
          },
          itemCount: fields.length,
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
        )
      ],
    );
  }

  Widget buildTodoTile(BuildContext context, Todo todo) {
    return ListTile(
      title: Text("${todo.title} - ${todo.created.day}/${todo.created.month}/${todo.created.year}" ),
      subtitle: Text(todo.question),
      trailing: Icon(Icons.navigate_next),
      onTap: (){
        toTodoDetail(todo);
      }
    );
  }

  toTodoDetail(Todo todo) async{
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context){
          return TodoDetailFormWidget(member, todo);
        }
      )
    );
    loadAllTodos();

  }

  void loadAllTodos() {
    try{
      List<Todo> todos = todoService.loadTodos(member);
      showTodo(todos);
    }
    on NotFoundException catch(exception){
      print(exception);
      showEmptySearchResult();
    }
  }

  void requestLogout() {
    ServiceContainer.getUserService().removeLoggedUser();
    Utils.showConfirm(context, "Xác nhận", "Bạn thực sự muốn đăng xuất ?", (){
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context){
            return LoginFormWidget();
          })
      );
    });
  }

  Widget buildLoadTodoButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8.0),
      child: RaisedButton(
        child: ListTile(
          title: Text("tải TODOs"),
          leading: Icon(Icons.insert_drive_file),
        ),
        onPressed: forwardToLoadTodoForm,
      ),
    );
  }

  void forwardToLoadTodoForm() async{
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context){
        return TodoLoadFormWidget(member);
      })
    );
    loadAllTodos();
  }
}
class TodoCreationFormWidget extends StatefulWidget{
  final User member;

  TodoCreationFormWidget(this.member);

  @override
  State<StatefulWidget> createState() {
    return _TodoCreationFormState(member);
  }

}
class _TodoCreationFormState extends State<TodoCreationFormWidget> implements TodoCreationForm{
  User member;
  TodoService todoService;
  TextEditingController titleController, fieldsController, questionController, answerController;
  _TodoCreationFormState(this.member){
    this.todoService = ServiceContainer.getTodoService();
    titleController = TextEditingController();
    fieldsController = TextEditingController();
    questionController = TextEditingController();
    answerController = TextEditingController();
  }


  @override
  createButtonClicked() {
    try{
      Todo todo = Todo.newInstance(
          title: titleController.text,
          fields: fieldsController.text,
          question: questionController.text,
          answer: answerController.text,
          creator: member.email
      );
      validate(todo);
      todoService.addTodo(todo);
      clearTextFields();
      showMessage("Bạn đã thêm TODO thành công.");
    }
    on InvalidException catch(exception){
      showError(exception.message);
    }
    on BaseException catch(exception){
      showError(exception.message);
    }
  }
  void validate(Todo todo){
    String message;
    if(todo.title.isEmpty)
      message = "Title is empty";
    else if(todo.fields.isEmpty)
      message = "Fields is empty";
    else if(todo.question.isEmpty)
      message = "Question is empty";
    else if(todo.answer.isEmpty)
      message = "Answer is empty";
    else if(todo.creator.isEmpty)
      message = "Creator is empty";
    if(message != null)
      throw InvalidException(message);
  }

  @override
  showError(String erMessage) {
    Utils.showMessage(context, "Lỗi", erMessage);
  }

  @override
  showMessage(String message) {
    Utils.showMessage(context, "Thông báo", message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thêm TODO")
      ),
      body: ListView(
        children: <Widget>[
          buildTextField(fieldsController, Strings.fieldsLabel),
          buildTextField(titleController, Strings.titleLabel),
          buildTextField(questionController, Strings.questionLabel),
          buildTextField(answerController, Strings.answerLabel),
          Container(
            margin: EdgeInsets.only(top: 8.0),
            child: Center(
              child: RaisedButton(
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
                child: Text("Thêm"),
                onPressed: createButtonClicked,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String labelText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
          labelText: labelText
      ),
    );
  }

  void clearTextFields() {
    titleController.clear();
    fieldsController.clear();
    questionController.clear();
    answerController.clear();
  }
}
class TodoDetailFormWidget extends StatefulWidget{
  final User member;
  final Todo todo;

  TodoDetailFormWidget(this.member, this.todo);

  @override
  State<StatefulWidget> createState() {
    return _TodoDetailFormState(member, todo);
  }
  
}
class _TodoDetailFormState extends State<TodoDetailFormWidget> implements TodoDetailForm{
  @override
  Todo todo;
  User member;
  TodoService todoService;

  TextEditingController titleController, questionController, answerController, fieldsController;
  
  _TodoDetailFormState(this.member, this.todo){
    todoService = ServiceContainer.getTodoService();
    titleController = TextEditingController(text: todo.title);
    questionController = TextEditingController(text: todo.question);
    answerController = TextEditingController(text: todo.answer);
    fieldsController = TextEditingController(text: todo.fields);
  }
  
  @override
  showError(String erMessage) {
    Utils.showMessage(context, "Lỗi", erMessage);
  }

  @override
  showMessage(String message) {
    Utils.showMessage(context, "Thông báo", message);
  }

  @override
  updateButtonClicked() {
    try {
      Todo todo = this.todo.clone();
      todo.title = titleController.text;
      todo.question = questionController.text;
      todo.answer = answerController.text;
      todo.fields = fieldsController.text;

      validate(todo);
      todoService.saveTodo(todo);
      showTodo(todo); ///refresh this.todo = todo
      showMessage("Cập nhật TODO thành công");
    }
    on InvalidException catch(exception){
      showError(exception.message);
    }
    on AlreadyExistingException catch(_){

    }
    on BaseException catch(exception){
      showError(exception.message);
    }
  }


  void showTodo(Todo todo) {
    setState(() {
      this.todo = todo;
    });
  }

  refreshForm(){
    titleController.text = todo.title;
    questionController.text = todo.question;
    answerController.text = todo.answer;
    fieldsController.text = todo.fields;
  }

  validate(Todo todo) {
    String message;
    if(todo.title.isEmpty)
      message = "Title is empty";
    else if(todo.question.isEmpty)
      message = "Question is empty";
    else if(todo.fields.isEmpty)
      message = "Fields is empty";
    else if(todo.answer.isEmpty)
      message = "Answer is empty";
    if(message != null)
      throw InvalidException(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update TODO"),
      ),
      body: ListView(
        children: <Widget>[
          TextField(
            controller: TextEditingController(text: todo.id),
            decoration: InputDecoration(
                labelText: "ID"
            ),
            enabled: false,
          ),
          buildTextField(fieldsController, Strings.fieldsLabel),
          buildTextField(titleController, Strings.titleLabel),
          buildTextField(questionController, Strings.questionLabel),
          buildTextField(answerController, Strings.answerLabel),
          TextField(
            controller: TextEditingController(text: "${todo.created.day}/${todo.created.month}/${todo.created.year}"),
            decoration: InputDecoration(
              labelText: Strings.createdLabel
            ),
            enabled: false,
          ),TextField(
            controller: TextEditingController(text: "${todo.creator}"),
            decoration: InputDecoration(
              labelText: Strings.creatorLabel
            ),
            enabled: false,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(right: 8.0),
                  child: RaisedButton(
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    child: Text(Strings.updateLabel),
                    onPressed: updateButtonClicked,
                  ),
                ),
                RaisedButton(
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  child: Text(Strings.ignoreLabel),
                  onPressed: refreshForm,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
  Widget buildTextField(TextEditingController controller, String labelText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText
      ),
    );
  }
}

class TodoLoaderServiceImpl implements TodoLoaderService{
  @override
  List<Todo> parseTodoLoadInform(TodoLoadInform inform) {
    String content = inform.content;
    List<dynamic> todos = json.decode(content);
    return todos
        .map((todo){
          Map<String, dynamic> todoJSON = json.decode(todo);
          print(todoJSON);
          return Todo.newInstance(
              title: todoJSON["title"],
              fields: todoJSON["fields"],
              question: todoJSON["question"],
              answer: todoJSON["answer"],
              creator: todoJSON["creator"]
          );
        }).toList();
  }
}

class TodoLoadFormWidget extends StatefulWidget{
  final User member;

  TodoLoadFormWidget(this.member);

  @override
  State<StatefulWidget> createState() {
    return _TodoLoadFormState(member);
  }
}
class _TodoLoadFormState extends State<TodoLoadFormWidget> implements TodoLoadForm{
  User user;
  TodoLoaderService todoLoader;
  TodoService todoService;
  List<Todo> todos = [];
  FileContentController fileContentController;

  _TodoLoadFormState(this.user){
    todoLoader = ServiceContainer.getTodoLoader();
    todoService = ServiceContainer.getTodoService();
    fileContentController = FileContentController();
  }


  @override
  backToTodoManagementForm() {
    Navigator.of(context).pop();
  }

  @override
  TodoLoadInform fetchTodoLoadInform() {
    String content = fileContentController.text;
    return TodoLoadInform(content);
  }

  @override
  forwardToFileExplorer() {
    // TODO: implement forwardToFileExplorer
  }

  @override
  requestLoadTodos() {
    try {
      TodoLoadInform inform = fetchTodoLoadInform();
      List<Todo> todos = todoLoader.parseTodoLoadInform(inform);
      showTodos(todos);
    }
    on ParseFileContentException catch(exception){
      showError(exception.message);
    }
  }

  @override
  requestSaveTodos() {
    try{
      todoService.addTodos(todos);
      showMessage("Bạn đã thêm các TODOs thành công. Tổng cộng ${todos.length} TODOs");
      clearTodos();
    }
    on BaseException catch(exception){
      showError(exception.message);
    }
  }

  @override
  showError(String erMessage) {
    Utils.showMessage(context, "Lỗi", erMessage);
  }

  @override
  showMessage(String message) {
    Utils.showMessage(context, "Thông báo", message);
  }

  @override
  showTodos(List<Todo> todos) {
    setState(() {
      this.todos = todos;
    });
  }

  void clearTodos() {
    setState(() {
      todos = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tải TODOs từ File")
      ),
      body: Container(
        margin: EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: FileChooser(
                  title: Text("Lựa chọn file"),
                  onSelected: requestLoadTodos,
                  controller: fileContentController
              ),
            ),
            Expanded(
              child: buildTodoListView(),
            ),
            hasTodos() ? Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: RaisedButton(
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
                child: Text("Thêm tất cả"),
                onPressed: requestSaveTodos,
              ),
            ) : Container()
          ],
        )
      )
    );
  }

  Widget buildTodoListView() {
    return ListView.builder(
      itemBuilder: (context, position){
        Todo todo = todos[position];
        return ListTile(
            title: Text("${todo.title} - ${todo.created.day}/${todo.created.month}/${todo.created.year}"),
            subtitle: Text(todo.question),
        );
      },
      itemCount: todos.length,
    );
  }

  hasTodos() {
    return todos.length > 0;
  }
}
class FileContentController{
  String text;

  FileContentController({this.text});

}
class FileChooser extends StatelessWidget{
  final Widget title;
  final Function() onSelected;
  final FileContentController controller;
  FileChooser({this.title, this.onSelected, this.controller}){
    List<String> todos = [];
    for(int i =0; i <= 20; i++){
      todos.add("""{"title":"Fake title $i","fields":"Fake fields $i","question":"Fake question $i","answer":"Fake answer $i","creator":"thopvna@gmail.com"}""");
    }
    controller.text = json.encode(todos);
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          title,
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: RaisedButton(
              child: Text("Chọn file"),
              onPressed: (){
                onSelected();
              },
            ),
          )
        ],
      ),
    );
  }
}
