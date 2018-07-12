import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_todos/core.dart';
import 'package:flutter_todos/di.dart';
import 'package:flutter_todos/user.dart';
import "package:uuid/uuid.dart";
import "package:english_words/english_words.dart";
import "package:flutter_todos/utils.dart" as Utils;
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
  saveTodo(Todo todo);
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
    return repository.search((todo){
      print("User email = ${user.email} vs Todo's creator = ${todo.creator}");
      return todo.creator == user.email;
    });
  }

  @override
  loadWordDocument(String path) {
    // TODO: implement loadWordDocument
  }

  @override
  saveTodo(Todo todo) {
    repository.insert(todo);
  }

  @override
  List<Todo> searchTodos(User user, String keyword) {
    keyword = keyword.trim().toLowerCase();
    return repository.search((todo){
      return
        todo.creator == user.email
        && (
          todo.title.toLowerCase().contains(keyword)
          || todo.question.toLowerCase().contains(keyword)
          || todo.answer.toLowerCase().contains(keyword)
          || todo.fields.toLowerCase().contains(keyword)
        );
    });
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
    String keyword = keywordController.text;
    if(keyword.isEmpty)
      showError("Từ khóa tìm kiếm rỗng.");
    else{
      List<Todo> searchResult = todoService.searchTodos(member, keywordController.text);
      print("Search completed: size of result = ${searchResult.length}");
      showTodo(searchResult);
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
        title: Text("Quản lý TODOs")
      ),
      body: RefreshIndicator(
          child: Column(
            children: <Widget>[
              buildSearchBox(),
              buildAddTodoButton(),
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
        title: Text("Tạo TODO mới"),
      ),
      onPressed: toTodoCreation,
    );
  }

  Widget buildEmptyTodoList() {
    return Expanded(
      flex: 1,
      child: Center(
        child: ListTile(
          leading: Icon(Icons.today),
          title: Text("Bạn chưa có TODO nào."),
        ),
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
  toTodoCreation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context){
          return TodoCreationFormWidget(member);
        }
      )
    );
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

  toTodoDetail(Todo todo){
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context){
          return TodoDetailFormWidget(member, todo);
        }
      )
    );
  }

  void loadAllTodos() {
    List<Todo> todos = todoService.loadTodos(member);
    showTodo(todos);
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
      todoService.saveTodo(todo);
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
          buildTextField(fieldsController, "Lĩnh vực"),
          buildTextField(titleController, "Tiêu đề"),
          buildTextField(questionController, "Câu hỏi"),
          buildTextField(answerController, "Trả lời"),
          Center(
            child: RaisedButton(
              child: Text("Thêm"),
              onPressed: createButtonClicked,
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
          buildTextField(fieldsController, "Lĩnh vực"),
          buildTextField(titleController, "Tiêu đề"),
          buildTextField(questionController, "Câu hỏi"),
          buildTextField(answerController, "Trả lời"),
          TextField(
            controller: TextEditingController(text: "${todo.created.day}/${todo.created.month}/${todo.created.year}"),
            decoration: InputDecoration(
              labelText: "Ngày tạo"
            ),
            enabled: false,
          ),TextField(
            controller: TextEditingController(text: "${todo.creator}"),
            decoration: InputDecoration(
              labelText: "Người tạo"
            ),
            enabled: false,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                child: Text("Cập nhật"),
                onPressed: updateButtonClicked,
              ),
              RaisedButton(
                child: Text("Bỏ qua"),
                onPressed: refreshForm,
              )
            ],
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