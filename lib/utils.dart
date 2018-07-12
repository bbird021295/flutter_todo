import 'package:flutter/material.dart';

showMessage(BuildContext context, String title, String message) {
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
              },
            )
          ],
        );
      }
  );
}
