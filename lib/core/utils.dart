import 'package:flutter/material.dart';
import "package:flutter_todos/strings.dart" as Strings;
showMessage(BuildContext context, String title, String message, [void accepted()]) {
  showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            FlatButton(
              child: Text("Tôi hiểu rồi"),
              onPressed: () {
                Navigator.of(context).pop();
                accepted();
              },
            )
          ],
        );
      }
  );
}
showConfirm(BuildContext context, String title, String message, void onAccept()){
  showDialog(
    context: context,
    builder: (_){
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          FlatButton(
            child: Text(Strings.denyLabel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          FlatButton(
            child: Text(Strings.acceptLabel),
            onPressed: () {
              Navigator.of(context).pop();
              onAccept();
            },
          )
        ],
      );
    }
  );
}