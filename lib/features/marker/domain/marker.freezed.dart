// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'marker.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Marker {

 String get id; String get taskId; String get columnId; String get boardId; MarkerSymbol get symbol; DateTime get updatedAt;
/// Create a copy of Marker
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkerCopyWith<Marker> get copyWith => _$MarkerCopyWithImpl<Marker>(this as Marker, _$identity);

  /// Serializes this Marker to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Marker&&(identical(other.id, id) || other.id == id)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.columnId, columnId) || other.columnId == columnId)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,taskId,columnId,boardId,symbol,updatedAt);

@override
String toString() {
  return 'Marker(id: $id, taskId: $taskId, columnId: $columnId, boardId: $boardId, symbol: $symbol, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MarkerCopyWith<$Res>  {
  factory $MarkerCopyWith(Marker value, $Res Function(Marker) _then) = _$MarkerCopyWithImpl;
@useResult
$Res call({
 String id, String taskId, String columnId, String boardId, MarkerSymbol symbol, DateTime updatedAt
});




}
/// @nodoc
class _$MarkerCopyWithImpl<$Res>
    implements $MarkerCopyWith<$Res> {
  _$MarkerCopyWithImpl(this._self, this._then);

  final Marker _self;
  final $Res Function(Marker) _then;

/// Create a copy of Marker
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? taskId = null,Object? columnId = null,Object? boardId = null,Object? symbol = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,columnId: null == columnId ? _self.columnId : columnId // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as MarkerSymbol,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Marker].
extension MarkerPatterns on Marker {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Marker value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Marker() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Marker value)  $default,){
final _that = this;
switch (_that) {
case _Marker():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Marker value)?  $default,){
final _that = this;
switch (_that) {
case _Marker() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String taskId,  String columnId,  String boardId,  MarkerSymbol symbol,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Marker() when $default != null:
return $default(_that.id,_that.taskId,_that.columnId,_that.boardId,_that.symbol,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String taskId,  String columnId,  String boardId,  MarkerSymbol symbol,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Marker():
return $default(_that.id,_that.taskId,_that.columnId,_that.boardId,_that.symbol,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String taskId,  String columnId,  String boardId,  MarkerSymbol symbol,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Marker() when $default != null:
return $default(_that.id,_that.taskId,_that.columnId,_that.boardId,_that.symbol,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Marker implements Marker {
  const _Marker({required this.id, required this.taskId, required this.columnId, required this.boardId, required this.symbol, required this.updatedAt});
  factory _Marker.fromJson(Map<String, dynamic> json) => _$MarkerFromJson(json);

@override final  String id;
@override final  String taskId;
@override final  String columnId;
@override final  String boardId;
@override final  MarkerSymbol symbol;
@override final  DateTime updatedAt;

/// Create a copy of Marker
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MarkerCopyWith<_Marker> get copyWith => __$MarkerCopyWithImpl<_Marker>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MarkerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Marker&&(identical(other.id, id) || other.id == id)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.columnId, columnId) || other.columnId == columnId)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,taskId,columnId,boardId,symbol,updatedAt);

@override
String toString() {
  return 'Marker(id: $id, taskId: $taskId, columnId: $columnId, boardId: $boardId, symbol: $symbol, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MarkerCopyWith<$Res> implements $MarkerCopyWith<$Res> {
  factory _$MarkerCopyWith(_Marker value, $Res Function(_Marker) _then) = __$MarkerCopyWithImpl;
@override @useResult
$Res call({
 String id, String taskId, String columnId, String boardId, MarkerSymbol symbol, DateTime updatedAt
});




}
/// @nodoc
class __$MarkerCopyWithImpl<$Res>
    implements _$MarkerCopyWith<$Res> {
  __$MarkerCopyWithImpl(this._self, this._then);

  final _Marker _self;
  final $Res Function(_Marker) _then;

/// Create a copy of Marker
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? taskId = null,Object? columnId = null,Object? boardId = null,Object? symbol = null,Object? updatedAt = null,}) {
  return _then(_Marker(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,columnId: null == columnId ? _self.columnId : columnId // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as MarkerSymbol,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
