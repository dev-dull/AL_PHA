// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_series.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecurringSeries {

 String get id; String get title; String get description; int get priority; String get recurrenceRule; bool get isEvent; String? get scheduledTime; DateTime get createdAt; DateTime? get endedAt;
/// Create a copy of RecurringSeries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringSeriesCopyWith<RecurringSeries> get copyWith => _$RecurringSeriesCopyWithImpl<RecurringSeries>(this as RecurringSeries, _$identity);

  /// Serializes this RecurringSeries to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringSeries&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.recurrenceRule, recurrenceRule) || other.recurrenceRule == recurrenceRule)&&(identical(other.isEvent, isEvent) || other.isEvent == isEvent)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,priority,recurrenceRule,isEvent,scheduledTime,createdAt,endedAt);

@override
String toString() {
  return 'RecurringSeries(id: $id, title: $title, description: $description, priority: $priority, recurrenceRule: $recurrenceRule, isEvent: $isEvent, scheduledTime: $scheduledTime, createdAt: $createdAt, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class $RecurringSeriesCopyWith<$Res>  {
  factory $RecurringSeriesCopyWith(RecurringSeries value, $Res Function(RecurringSeries) _then) = _$RecurringSeriesCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, int priority, String recurrenceRule, bool isEvent, String? scheduledTime, DateTime createdAt, DateTime? endedAt
});




}
/// @nodoc
class _$RecurringSeriesCopyWithImpl<$Res>
    implements $RecurringSeriesCopyWith<$Res> {
  _$RecurringSeriesCopyWithImpl(this._self, this._then);

  final RecurringSeries _self;
  final $Res Function(RecurringSeries) _then;

/// Create a copy of RecurringSeries
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? priority = null,Object? recurrenceRule = null,Object? isEvent = null,Object? scheduledTime = freezed,Object? createdAt = null,Object? endedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,recurrenceRule: null == recurrenceRule ? _self.recurrenceRule : recurrenceRule // ignore: cast_nullable_to_non_nullable
as String,isEvent: null == isEvent ? _self.isEvent : isEvent // ignore: cast_nullable_to_non_nullable
as bool,scheduledTime: freezed == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurringSeries].
extension RecurringSeriesPatterns on RecurringSeries {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringSeries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringSeries() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringSeries value)  $default,){
final _that = this;
switch (_that) {
case _RecurringSeries():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringSeries value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringSeries() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  int priority,  String recurrenceRule,  bool isEvent,  String? scheduledTime,  DateTime createdAt,  DateTime? endedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringSeries() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.priority,_that.recurrenceRule,_that.isEvent,_that.scheduledTime,_that.createdAt,_that.endedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  int priority,  String recurrenceRule,  bool isEvent,  String? scheduledTime,  DateTime createdAt,  DateTime? endedAt)  $default,) {final _that = this;
switch (_that) {
case _RecurringSeries():
return $default(_that.id,_that.title,_that.description,_that.priority,_that.recurrenceRule,_that.isEvent,_that.scheduledTime,_that.createdAt,_that.endedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  int priority,  String recurrenceRule,  bool isEvent,  String? scheduledTime,  DateTime createdAt,  DateTime? endedAt)?  $default,) {final _that = this;
switch (_that) {
case _RecurringSeries() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.priority,_that.recurrenceRule,_that.isEvent,_that.scheduledTime,_that.createdAt,_that.endedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecurringSeries extends RecurringSeries {
  const _RecurringSeries({required this.id, required this.title, this.description = '', this.priority = 0, required this.recurrenceRule, this.isEvent = false, this.scheduledTime, required this.createdAt, this.endedAt}): super._();
  factory _RecurringSeries.fromJson(Map<String, dynamic> json) => _$RecurringSeriesFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  int priority;
@override final  String recurrenceRule;
@override@JsonKey() final  bool isEvent;
@override final  String? scheduledTime;
@override final  DateTime createdAt;
@override final  DateTime? endedAt;

/// Create a copy of RecurringSeries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringSeriesCopyWith<_RecurringSeries> get copyWith => __$RecurringSeriesCopyWithImpl<_RecurringSeries>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecurringSeriesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringSeries&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.recurrenceRule, recurrenceRule) || other.recurrenceRule == recurrenceRule)&&(identical(other.isEvent, isEvent) || other.isEvent == isEvent)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,priority,recurrenceRule,isEvent,scheduledTime,createdAt,endedAt);

@override
String toString() {
  return 'RecurringSeries(id: $id, title: $title, description: $description, priority: $priority, recurrenceRule: $recurrenceRule, isEvent: $isEvent, scheduledTime: $scheduledTime, createdAt: $createdAt, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class _$RecurringSeriesCopyWith<$Res> implements $RecurringSeriesCopyWith<$Res> {
  factory _$RecurringSeriesCopyWith(_RecurringSeries value, $Res Function(_RecurringSeries) _then) = __$RecurringSeriesCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, int priority, String recurrenceRule, bool isEvent, String? scheduledTime, DateTime createdAt, DateTime? endedAt
});




}
/// @nodoc
class __$RecurringSeriesCopyWithImpl<$Res>
    implements _$RecurringSeriesCopyWith<$Res> {
  __$RecurringSeriesCopyWithImpl(this._self, this._then);

  final _RecurringSeries _self;
  final $Res Function(_RecurringSeries) _then;

/// Create a copy of RecurringSeries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? priority = null,Object? recurrenceRule = null,Object? isEvent = null,Object? scheduledTime = freezed,Object? createdAt = null,Object? endedAt = freezed,}) {
  return _then(_RecurringSeries(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,recurrenceRule: null == recurrenceRule ? _self.recurrenceRule : recurrenceRule // ignore: cast_nullable_to_non_nullable
as String,isEvent: null == isEvent ? _self.isEvent : isEvent // ignore: cast_nullable_to_non_nullable
as bool,scheduledTime: freezed == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
