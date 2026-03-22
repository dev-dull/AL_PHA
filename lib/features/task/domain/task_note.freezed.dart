// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskNote {

 String get id; String get taskId; String get content; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of TaskNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskNoteCopyWith<TaskNote> get copyWith => _$TaskNoteCopyWithImpl<TaskNote>(this as TaskNote, _$identity);

  /// Serializes this TaskNote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskNote&&(identical(other.id, id) || other.id == id)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,taskId,content,createdAt,updatedAt);

@override
String toString() {
  return 'TaskNote(id: $id, taskId: $taskId, content: $content, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TaskNoteCopyWith<$Res>  {
  factory $TaskNoteCopyWith(TaskNote value, $Res Function(TaskNote) _then) = _$TaskNoteCopyWithImpl;
@useResult
$Res call({
 String id, String taskId, String content, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$TaskNoteCopyWithImpl<$Res>
    implements $TaskNoteCopyWith<$Res> {
  _$TaskNoteCopyWithImpl(this._self, this._then);

  final TaskNote _self;
  final $Res Function(TaskNote) _then;

/// Create a copy of TaskNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? taskId = null,Object? content = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskNote].
extension TaskNotePatterns on TaskNote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskNote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskNote value)  $default,){
final _that = this;
switch (_that) {
case _TaskNote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskNote value)?  $default,){
final _that = this;
switch (_that) {
case _TaskNote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String taskId,  String content,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskNote() when $default != null:
return $default(_that.id,_that.taskId,_that.content,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String taskId,  String content,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TaskNote():
return $default(_that.id,_that.taskId,_that.content,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String taskId,  String content,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TaskNote() when $default != null:
return $default(_that.id,_that.taskId,_that.content,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskNote implements TaskNote {
  const _TaskNote({required this.id, required this.taskId, required this.content, required this.createdAt, required this.updatedAt});
  factory _TaskNote.fromJson(Map<String, dynamic> json) => _$TaskNoteFromJson(json);

@override final  String id;
@override final  String taskId;
@override final  String content;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of TaskNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskNoteCopyWith<_TaskNote> get copyWith => __$TaskNoteCopyWithImpl<_TaskNote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskNoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskNote&&(identical(other.id, id) || other.id == id)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,taskId,content,createdAt,updatedAt);

@override
String toString() {
  return 'TaskNote(id: $id, taskId: $taskId, content: $content, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TaskNoteCopyWith<$Res> implements $TaskNoteCopyWith<$Res> {
  factory _$TaskNoteCopyWith(_TaskNote value, $Res Function(_TaskNote) _then) = __$TaskNoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String taskId, String content, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$TaskNoteCopyWithImpl<$Res>
    implements _$TaskNoteCopyWith<$Res> {
  __$TaskNoteCopyWithImpl(this._self, this._then);

  final _TaskNote _self;
  final $Res Function(_TaskNote) _then;

/// Create a copy of TaskNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? taskId = null,Object? content = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_TaskNote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
