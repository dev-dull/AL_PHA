// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'board_column.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BoardColumn {

 String get id; String get boardId; String get label; int get position; ColumnType get type;
/// Create a copy of BoardColumn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoardColumnCopyWith<BoardColumn> get copyWith => _$BoardColumnCopyWithImpl<BoardColumn>(this as BoardColumn, _$identity);

  /// Serializes this BoardColumn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoardColumn&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.label, label) || other.label == label)&&(identical(other.position, position) || other.position == position)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,label,position,type);

@override
String toString() {
  return 'BoardColumn(id: $id, boardId: $boardId, label: $label, position: $position, type: $type)';
}


}

/// @nodoc
abstract mixin class $BoardColumnCopyWith<$Res>  {
  factory $BoardColumnCopyWith(BoardColumn value, $Res Function(BoardColumn) _then) = _$BoardColumnCopyWithImpl;
@useResult
$Res call({
 String id, String boardId, String label, int position, ColumnType type
});




}
/// @nodoc
class _$BoardColumnCopyWithImpl<$Res>
    implements $BoardColumnCopyWith<$Res> {
  _$BoardColumnCopyWithImpl(this._self, this._then);

  final BoardColumn _self;
  final $Res Function(BoardColumn) _then;

/// Create a copy of BoardColumn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? boardId = null,Object? label = null,Object? position = null,Object? type = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ColumnType,
  ));
}

}


/// Adds pattern-matching-related methods to [BoardColumn].
extension BoardColumnPatterns on BoardColumn {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoardColumn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoardColumn() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoardColumn value)  $default,){
final _that = this;
switch (_that) {
case _BoardColumn():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoardColumn value)?  $default,){
final _that = this;
switch (_that) {
case _BoardColumn() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String boardId,  String label,  int position,  ColumnType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoardColumn() when $default != null:
return $default(_that.id,_that.boardId,_that.label,_that.position,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String boardId,  String label,  int position,  ColumnType type)  $default,) {final _that = this;
switch (_that) {
case _BoardColumn():
return $default(_that.id,_that.boardId,_that.label,_that.position,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String boardId,  String label,  int position,  ColumnType type)?  $default,) {final _that = this;
switch (_that) {
case _BoardColumn() when $default != null:
return $default(_that.id,_that.boardId,_that.label,_that.position,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BoardColumn implements BoardColumn {
  const _BoardColumn({required this.id, required this.boardId, required this.label, required this.position, this.type = ColumnType.custom});
  factory _BoardColumn.fromJson(Map<String, dynamic> json) => _$BoardColumnFromJson(json);

@override final  String id;
@override final  String boardId;
@override final  String label;
@override final  int position;
@override@JsonKey() final  ColumnType type;

/// Create a copy of BoardColumn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoardColumnCopyWith<_BoardColumn> get copyWith => __$BoardColumnCopyWithImpl<_BoardColumn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BoardColumnToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoardColumn&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.label, label) || other.label == label)&&(identical(other.position, position) || other.position == position)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,label,position,type);

@override
String toString() {
  return 'BoardColumn(id: $id, boardId: $boardId, label: $label, position: $position, type: $type)';
}


}

/// @nodoc
abstract mixin class _$BoardColumnCopyWith<$Res> implements $BoardColumnCopyWith<$Res> {
  factory _$BoardColumnCopyWith(_BoardColumn value, $Res Function(_BoardColumn) _then) = __$BoardColumnCopyWithImpl;
@override @useResult
$Res call({
 String id, String boardId, String label, int position, ColumnType type
});




}
/// @nodoc
class __$BoardColumnCopyWithImpl<$Res>
    implements _$BoardColumnCopyWith<$Res> {
  __$BoardColumnCopyWithImpl(this._self, this._then);

  final _BoardColumn _self;
  final $Res Function(_BoardColumn) _then;

/// Create a copy of BoardColumn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? boardId = null,Object? label = null,Object? position = null,Object? type = null,}) {
  return _then(_BoardColumn(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ColumnType,
  ));
}


}

// dart format on
