// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'board_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BoardTemplate {

 String get id; String get name; String get description; BoardType get boardType; List<TemplateColumn> get columns;
/// Create a copy of BoardTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoardTemplateCopyWith<BoardTemplate> get copyWith => _$BoardTemplateCopyWithImpl<BoardTemplate>(this as BoardTemplate, _$identity);

  /// Serializes this BoardTemplate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoardTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.boardType, boardType) || other.boardType == boardType)&&const DeepCollectionEquality().equals(other.columns, columns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,boardType,const DeepCollectionEquality().hash(columns));

@override
String toString() {
  return 'BoardTemplate(id: $id, name: $name, description: $description, boardType: $boardType, columns: $columns)';
}


}

/// @nodoc
abstract mixin class $BoardTemplateCopyWith<$Res>  {
  factory $BoardTemplateCopyWith(BoardTemplate value, $Res Function(BoardTemplate) _then) = _$BoardTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, BoardType boardType, List<TemplateColumn> columns
});




}
/// @nodoc
class _$BoardTemplateCopyWithImpl<$Res>
    implements $BoardTemplateCopyWith<$Res> {
  _$BoardTemplateCopyWithImpl(this._self, this._then);

  final BoardTemplate _self;
  final $Res Function(BoardTemplate) _then;

/// Create a copy of BoardTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? boardType = null,Object? columns = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,boardType: null == boardType ? _self.boardType : boardType // ignore: cast_nullable_to_non_nullable
as BoardType,columns: null == columns ? _self.columns : columns // ignore: cast_nullable_to_non_nullable
as List<TemplateColumn>,
  ));
}

}


/// Adds pattern-matching-related methods to [BoardTemplate].
extension BoardTemplatePatterns on BoardTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoardTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoardTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoardTemplate value)  $default,){
final _that = this;
switch (_that) {
case _BoardTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoardTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _BoardTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  BoardType boardType,  List<TemplateColumn> columns)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoardTemplate() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.boardType,_that.columns);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  BoardType boardType,  List<TemplateColumn> columns)  $default,) {final _that = this;
switch (_that) {
case _BoardTemplate():
return $default(_that.id,_that.name,_that.description,_that.boardType,_that.columns);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  BoardType boardType,  List<TemplateColumn> columns)?  $default,) {final _that = this;
switch (_that) {
case _BoardTemplate() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.boardType,_that.columns);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BoardTemplate implements BoardTemplate {
  const _BoardTemplate({required this.id, required this.name, required this.description, required this.boardType, required final  List<TemplateColumn> columns}): _columns = columns;
  factory _BoardTemplate.fromJson(Map<String, dynamic> json) => _$BoardTemplateFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
@override final  BoardType boardType;
 final  List<TemplateColumn> _columns;
@override List<TemplateColumn> get columns {
  if (_columns is EqualUnmodifiableListView) return _columns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_columns);
}


/// Create a copy of BoardTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoardTemplateCopyWith<_BoardTemplate> get copyWith => __$BoardTemplateCopyWithImpl<_BoardTemplate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BoardTemplateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoardTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.boardType, boardType) || other.boardType == boardType)&&const DeepCollectionEquality().equals(other._columns, _columns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,boardType,const DeepCollectionEquality().hash(_columns));

@override
String toString() {
  return 'BoardTemplate(id: $id, name: $name, description: $description, boardType: $boardType, columns: $columns)';
}


}

/// @nodoc
abstract mixin class _$BoardTemplateCopyWith<$Res> implements $BoardTemplateCopyWith<$Res> {
  factory _$BoardTemplateCopyWith(_BoardTemplate value, $Res Function(_BoardTemplate) _then) = __$BoardTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, BoardType boardType, List<TemplateColumn> columns
});




}
/// @nodoc
class __$BoardTemplateCopyWithImpl<$Res>
    implements _$BoardTemplateCopyWith<$Res> {
  __$BoardTemplateCopyWithImpl(this._self, this._then);

  final _BoardTemplate _self;
  final $Res Function(_BoardTemplate) _then;

/// Create a copy of BoardTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? boardType = null,Object? columns = null,}) {
  return _then(_BoardTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,boardType: null == boardType ? _self.boardType : boardType // ignore: cast_nullable_to_non_nullable
as BoardType,columns: null == columns ? _self._columns : columns // ignore: cast_nullable_to_non_nullable
as List<TemplateColumn>,
  ));
}


}


/// @nodoc
mixin _$TemplateColumn {

 String get label; int get position; ColumnType get type;
/// Create a copy of TemplateColumn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TemplateColumnCopyWith<TemplateColumn> get copyWith => _$TemplateColumnCopyWithImpl<TemplateColumn>(this as TemplateColumn, _$identity);

  /// Serializes this TemplateColumn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TemplateColumn&&(identical(other.label, label) || other.label == label)&&(identical(other.position, position) || other.position == position)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,position,type);

@override
String toString() {
  return 'TemplateColumn(label: $label, position: $position, type: $type)';
}


}

/// @nodoc
abstract mixin class $TemplateColumnCopyWith<$Res>  {
  factory $TemplateColumnCopyWith(TemplateColumn value, $Res Function(TemplateColumn) _then) = _$TemplateColumnCopyWithImpl;
@useResult
$Res call({
 String label, int position, ColumnType type
});




}
/// @nodoc
class _$TemplateColumnCopyWithImpl<$Res>
    implements $TemplateColumnCopyWith<$Res> {
  _$TemplateColumnCopyWithImpl(this._self, this._then);

  final TemplateColumn _self;
  final $Res Function(TemplateColumn) _then;

/// Create a copy of TemplateColumn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? position = null,Object? type = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ColumnType,
  ));
}

}


/// Adds pattern-matching-related methods to [TemplateColumn].
extension TemplateColumnPatterns on TemplateColumn {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TemplateColumn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TemplateColumn() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TemplateColumn value)  $default,){
final _that = this;
switch (_that) {
case _TemplateColumn():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TemplateColumn value)?  $default,){
final _that = this;
switch (_that) {
case _TemplateColumn() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  int position,  ColumnType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TemplateColumn() when $default != null:
return $default(_that.label,_that.position,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  int position,  ColumnType type)  $default,) {final _that = this;
switch (_that) {
case _TemplateColumn():
return $default(_that.label,_that.position,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  int position,  ColumnType type)?  $default,) {final _that = this;
switch (_that) {
case _TemplateColumn() when $default != null:
return $default(_that.label,_that.position,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TemplateColumn implements TemplateColumn {
  const _TemplateColumn({required this.label, required this.position, this.type = ColumnType.custom});
  factory _TemplateColumn.fromJson(Map<String, dynamic> json) => _$TemplateColumnFromJson(json);

@override final  String label;
@override final  int position;
@override@JsonKey() final  ColumnType type;

/// Create a copy of TemplateColumn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TemplateColumnCopyWith<_TemplateColumn> get copyWith => __$TemplateColumnCopyWithImpl<_TemplateColumn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TemplateColumnToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TemplateColumn&&(identical(other.label, label) || other.label == label)&&(identical(other.position, position) || other.position == position)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,position,type);

@override
String toString() {
  return 'TemplateColumn(label: $label, position: $position, type: $type)';
}


}

/// @nodoc
abstract mixin class _$TemplateColumnCopyWith<$Res> implements $TemplateColumnCopyWith<$Res> {
  factory _$TemplateColumnCopyWith(_TemplateColumn value, $Res Function(_TemplateColumn) _then) = __$TemplateColumnCopyWithImpl;
@override @useResult
$Res call({
 String label, int position, ColumnType type
});




}
/// @nodoc
class __$TemplateColumnCopyWithImpl<$Res>
    implements _$TemplateColumnCopyWith<$Res> {
  __$TemplateColumnCopyWithImpl(this._self, this._then);

  final _TemplateColumn _self;
  final $Res Function(_TemplateColumn) _then;

/// Create a copy of TemplateColumn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? position = null,Object? type = null,}) {
  return _then(_TemplateColumn(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ColumnType,
  ));
}


}

// dart format on
