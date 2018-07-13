import 'package:flutter_todos/core/exceptions.dart';
import 'package:flutter_todos/core/reflection.dart';
abstract class Entity<ID>{
  ID id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Entity &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}


abstract class BaseRepository<ENTITY, ID>{
  insert(ENTITY entity);
  insertAll(List<ENTITY> entities);
  update(ENTITY entity);
  delete(ENTITY entity);
  deleteByID(ID id);
  findAll();
  findByID(ID id);
  search(SearchConditions conditions);
  searchFirst(SearchConditions conditions);
  contains(ID id);
}

class SearchConditions{
  Map<String, dynamic> conditions;
  SearchConditions(this.conditions);
}


class InMemoryRepository<ENTITY extends Entity, ID> implements BaseRepository<ENTITY, ID>{
  Map<ID, ENTITY> entities = {};
  InMemoryRepository(){
    entities = {};
  }

  @override
  delete(ENTITY entity) {
    if(!contains(entity.id))
      throw EntityNonExistingException();
    else
      entities.remove(entity.id);
  }

  @override
  deleteByID(ID id) {
    if(!contains(id))
      throw EntityNonExistingException();
    else
      entities.remove(id);
  }

  @override
  findAll() {
    return isNotEmpty() ? entities.values.toList() : throw NotFoundException();
  }

  bool isNotEmpty(){
    return entities != null && entities.length > 0;
  }

  @override
  findByID(ID id) {
    return contains(id) ? entities[id] : throw NotFoundException();
  }

  @override
  insert(ENTITY entity) {
    if(contains(entity.id))
      throw EntityAlreadyExistingException();
    else
      entities[entity.id] = entity;
    return entity;
  }

  @override
  insertAll(List<ENTITY> entities) {
    List<ENTITY> failed = [];
    for(int i = 0; i< entities.length; i++){
      ENTITY entity = entities[i];
      try{
        this.entities[entity.id] = entity;
      }
      on EntityAlreadyExistingException catch(_){
        failed.add(entity);
      }
    }
    return failed;
  }

  @override
  search(SearchConditions conditions) {
    List<ENTITY> result = [];
    entities.values.forEach((ENTITY entity){
      bool isOK = true;
      conditions.conditions.forEach((key, value){
        dynamic _value = Reflector.get(entity, key);
        if(!_value.toString().contains(value.toString())) {
          isOK = false;
          return;
        }
      });
      if(isOK) result.add(entity);
    });
    return result.isNotEmpty ? result : throw NotFoundException();
  }

  @override
  searchFirst(SearchConditions conditions) {
    ENTITY result;
    entities.values.forEach((ENTITY entity){
      bool isOK = true;
      conditions.conditions.forEach((key, value){
        dynamic _value = Reflector.get(entity, key);
        if(_value.toString().contains(value.toString())){
          isOK = false;
          return;
        }
      });
      if(isOK){
        result = entity;
        return;
      }
    });
    return result != null ? result : throw NotFoundException();
  }

  @override
  update(ENTITY entity) {
    if(contains(entity.id))
      entities[entity.id] = entity;
    else
      throw EntityNonExistingException();
  }

  @override
  contains(ID id) {
    return entities.containsKey(id);
  }
}
class Reflector{
  static get(entity, String fieldName){
    return EnableReflection.reflect(entity).invokeGetter(fieldName);
  }
}