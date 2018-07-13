class BaseException implements Exception{
  String message;
  BaseException([this.message]);
}
class InvalidException extends BaseException{
  InvalidException([String message]) : super(message);

}
class AlreadyExistingException extends BaseException{
  AlreadyExistingException([String message]) : super(message);

}
class NonExistingException extends BaseException{
  NonExistingException([String message]) : super(message);

}
class NotFoundException extends BaseException{
  NotFoundException([String message]) : super(message);

}
class UnsupportedOperationException extends BaseException{
  UnsupportedOperationException([String message]) : super(message);
}
class EntityNonExistingException extends NonExistingException{
  EntityNonExistingException([String message]) : super(message);
}
class EntityAlreadyExistingException extends AlreadyExistingException{
  EntityAlreadyExistingException([String message]) : super(message);
}

class SignUpInformInvalidException extends InvalidException{
  SignUpInformInvalidException([String message]) : super(message);
}
class LoginInformInvalidException extends InvalidException{
  LoginInformInvalidException([String message]) : super(message);
}

class NonLoggedUserException extends BaseException{
  NonLoggedUserException([String message]) : super(message);

}
class ParseFileContentException extends BaseException{
  ParseFileContentException([String message]) : super(message);

}