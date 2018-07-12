
abstract class Entity<IDENTITY>{
  IDENTITY id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Entity &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;


}
abstract class Repository<ENTITY extends Entity, IDENTITY>{
  ///Insert [entity] to Repository
  ///return this [entity] before insert
  ///throw [EntityAlreadyExistingException] if [entity] is existing in Repository
  insert(ENTITY entity);
  ///Update [entity] to Repository
  ///throw [EntityNonExistingException] if [entity] isn't existing in Repository
  update(ENTITY entity);
  ///Delete entity with id [id] from Repository
  ///throw [EntityNonExistingException] if entity with [id] isn't existing in Repository
  delete(IDENTITY id);
  ///Fetch all entity in Repository
  ///throw an [NotFoundException] if there are no entites.
  List<ENTITY> fetchAll();
  ///Fetch entity with id [id] from Repository
  ///throw an [EntityNonExistingException] if entity with [id] isn't existing in Repository
  ENTITY fetchById(IDENTITY id);
  ///Search entities matching [test] from Repository
  ///throw an [NotFoundException] if there are no entities matching.
  List<ENTITY> search(bool test(ENTITY entity));
  ///Search and return first matching [test] entity from Repository
  ///throw an [NotFoundException] if there are no entities matching.
  ENTITY searchFirst(bool test(ENTITY entity));
}
class InMemoryRepository<ENTITY extends Entity, IDENTITY> implements Repository<ENTITY, IDENTITY>{
  List<ENTITY> entities = [];

  @override
  delete(IDENTITY id) {
    fetchById(id); /// check entity with [id] existing.
    entities.removeWhere((entity){
      entity.id = id;
    });
  }

  @override
  List<ENTITY> fetchAll() {
    return entities.isEmpty ? entities : throw NotFoundException("Repository không có entities nào.");
  }

  @override
  ENTITY fetchById(IDENTITY id) {
    return entities.firstWhere((entity){
      return entity.id == id;
    }, orElse: (){
      throw EntityNonExistingException("Entity với ID $id không tồn tại.");
    });
  }

  @override
  insert(ENTITY entity) {
    if(entities.contains(entity))
      throw EntityAlreadyExistingException("Entity với ID ${entity.id} đã tồn tại.");
    else
      entities.add(entity);
  }


  @override
  update(ENTITY entity) {
    if(entities.contains(entity)) {
      var index = entities.indexOf(entity);
      entities[index] = entity;
    }
    else
      throw EntityNonExistingException("Entity với ID ${entity.id} không tồn tại.");
  }

  @override
  List<ENTITY> search(bool test(ENTITY entity)) {
    var result = entities
        .where(test)
        .toList();
    return result.length > 0 ? result : throw NotFoundException("Không tìm thấy Entity nào khớp.");
  }

  @override
  ENTITY searchFirst(bool Function(ENTITY entity) test) {
      return entities.firstWhere(test, orElse: (){
        throw NotFoundException("Không tìm thấy Entity nào khớp");
      });
  }
}

class Optional<T>{
  T _payload;
  Optional.from(T t){
    _payload = t;
  }
  T get(){
    return _payload;
  }
  bool isPresent(){
    return _payload != null;
  }
  bool isNotPresent(){
    return !isPresent();
  }
}

class BaseException implements Exception{
  String message;
  BaseException(this.message);
}
class InvalidException extends BaseException{
  InvalidException(String message) : super(message);

}
class AlreadyExistingException extends BaseException{
  AlreadyExistingException(String message) : super(message);

}
class NonExistingException extends BaseException{
  NonExistingException(String message) : super(message);

}
class NotFoundException extends BaseException{
  NotFoundException(String message) : super(message);

}
class UnsupportedOperationException extends BaseException{
  UnsupportedOperationException(String message) : super(message);
}
class EntityNonExistingException extends NonExistingException{
  EntityNonExistingException(String message) : super(message);
}
class EntityAlreadyExistingException extends AlreadyExistingException{
  EntityAlreadyExistingException(String message) : super(message);
}

class SignUpInformInvalidException extends InvalidException{
  SignUpInformInvalidException(String message) : super(message);
}
class LoginInformInvalidException extends InvalidException{
  LoginInformInvalidException(String message) : super(message);
}
