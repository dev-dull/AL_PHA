// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Task {

 String get id; String get boardId; String get title; String get description; TaskState get state; int get priority; int get position; DateTime get createdAt; DateTime? get completedAt; DateTime? get deadline; String? get migratedFromBoardId; String? get migratedFromTaskId;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.state, state) || other.state == state)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.position, position) || other.position == position)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.migratedFromBoardId, migratedFromBoardId) || other.migratedFromBoardId == migratedFromBoardId)&&(identical(other.migratedFromTaskId, migratedFromTaskId) || other.migratedFromTaskId == migratedFromTaskId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,title,description,state,priority,position,createdAt,completedAt,deadline,migratedFromBoardId,migratedFromTaskId);

@override
String toString() {
  return 'Task(id: $id, boardId: $boardId, title: $title, description: $description, state: $state, priority: $priority, position: $position, createdAt: $createdAt, completedAt: $completedAt, deadline: $deadline, migratedFromBoardId: $migratedFromBoardId, migratedFromTaskId: $migratedFromTaskId)';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
 String id, String boardId, String title, String description, TaskState state, int priority, int position, DateTime createdAt, DateTime? completedAt, DateTime? deadline, String? migratedFromBoardId, String? migratedFromTaskId
});




}
/// @nodoc
class _$TaskCopyWithImpl<$Res>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? boardId = null,Object? title = null,Object? description = null,Object? state = null,Object? priority = null,Object? position = null,Object? createdAt = null,Object? completedAt = freezed,Object? deadline = freezed,Object? migratedFromBoardId = freezed,Object? migratedFromTaskId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as TaskState,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,migratedFromBoardId: freezed == migratedFromBoardId ? _self.migratedFromBoardId : migratedFromBoardId // ignore: cast_nullable_to_non_nullable
as String?,migratedFromTaskId: freezed == migratedFromTaskId ? _self.migratedFromTaskId : migratedFromTaskId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Task value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Task value)  $default,){
final _that = this;
switch (_that) {
case _Task():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Task value)?  $default,){
final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String boardId,  String title,  String description,  TaskState state,  int priority,  int position,  DateTime createdAt,  DateTime? completedAt,  DateTime? deadline,  String? migratedFromBoardId,  String? migratedFromTaskId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.boardId,_that.title,_that.description,_that.state,_that.priority,_that.position,_that.createdAt,_that.completedAt,_that.deadline,_that.migratedFromBoardId,_that.migratedFromTaskId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String boardId,  String title,  String description,  TaskState state,  int priority,  int position,  DateTime createdAt,  DateTime? completedAt,  DateTime? deadline,  String? migratedFromBoardId,  String? migratedFromTaskId)  $default,) {final _that = this;
switch (_that) {
case _Task():
return $default(_that.id,_that.boardId,_that.title,_that.description,_that.state,_that.priority,_that.position,_that.createdAt,_that.completedAt,_that.deadline,_that.migratedFromBoardId,_that.migratedFromTaskId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String boardId,  String title,  String description,  TaskState state,  int priority,  int position,  DateTime createdAt,  DateTime? completedAt,  DateTime? deadline,  String? migratedFromBoardId,  String? migratedFromTaskId)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.boardId,_that.title,_that.description,_that.state,_that.priority,_that.position,_that.createdAt,_that.completedAt,_that.deadline,_that.migratedFromBoardId,_that.migratedFromTaskId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Task implements Task {
  const _Task({required this.id, required this.boardId, required this.title, this.description = '', this.state = TaskState.open, this.priority = 0, required this.position, required this.createdAt, this.completedAt, this.deadline, this.migratedFromBoardId, this.migratedFromTaskId});
  factory _Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

@override final  String id;
@override final  String boardId;
@override final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  TaskState state;
@override@JsonKey() final  int priority;
@override final  int position;
@override final  DateTime createdAt;
@override final  DateTime? completedAt;
@override final  DateTime? deadline;
@override final  String? migratedFromBoardId;
@override final  String? migratedFromTaskId;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.state, state) || other.state == state)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.position, position) || other.position == position)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.migratedFromBoardId, migratedFromBoardId) || other.migratedFromBoardId == migratedFromBoardId)&&(identical(other.migratedFromTaskId, migratedFromTaskId) || other.migratedFromTaskId == migratedFromTaskId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,title,description,state,priority,position,createdAt,completedAt,deadline,migratedFromBoardId,migratedFromTaskId);

@override
String toString() {
  return 'Task(id: $id, boardId: $boardId, title: $title, description: $description, state: $state, priority: $priority, position: $position, createdAt: $createdAt, completedAt: $completedAt, deadline: $deadline, migratedFromBoardId: $migratedFromBoardId, migratedFromTaskId: $migratedFromTaskId)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String boardId, String title, String description, TaskState state, int priority, int position, DateTime createdAt, DateTime? completedAt, DateTime? deadline, String? migratedFromBoardId, String? migratedFromTaskId
});




}
/// @nodoc
class __$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? boardId = null,Object? title = null,Object? description = null,Object? state = null,Object? priority = null,Object? position = null,Object? createdAt = null,Object? completedAt = freezed,Object? deadline = freezed,Object? migratedFromBoardId = freezed,Object? migratedFromTaskId = freezed,}) {
  return _then(_Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as TaskState,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,migratedFromBoardId: freezed == migratedFromBoardId ? _self.migratedFromBoardId : migratedFromBoardId // ignore: cast_nullable_to_non_nullable
as String?,migratedFromTaskId: freezed == migratedFromTaskId ? _self.migratedFromTaskId : migratedFromTaskId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
