// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppPreferences {

/// Font family name, or null for system default.
 String? get fontFamily;/// 0 = system, 1 = light, 2 = dark.
 int get themeModeIndex;/// First day of the week: 1 = Monday, 7 = Sunday.
 int get firstDayOfWeek;
/// Create a copy of AppPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppPreferencesCopyWith<AppPreferences> get copyWith => _$AppPreferencesCopyWithImpl<AppPreferences>(this as AppPreferences, _$identity);

  /// Serializes this AppPreferences to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppPreferences&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.themeModeIndex, themeModeIndex) || other.themeModeIndex == themeModeIndex)&&(identical(other.firstDayOfWeek, firstDayOfWeek) || other.firstDayOfWeek == firstDayOfWeek));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fontFamily,themeModeIndex,firstDayOfWeek);

@override
String toString() {
  return 'AppPreferences(fontFamily: $fontFamily, themeModeIndex: $themeModeIndex, firstDayOfWeek: $firstDayOfWeek)';
}


}

/// @nodoc
abstract mixin class $AppPreferencesCopyWith<$Res>  {
  factory $AppPreferencesCopyWith(AppPreferences value, $Res Function(AppPreferences) _then) = _$AppPreferencesCopyWithImpl;
@useResult
$Res call({
 String? fontFamily, int themeModeIndex, int firstDayOfWeek
});




}
/// @nodoc
class _$AppPreferencesCopyWithImpl<$Res>
    implements $AppPreferencesCopyWith<$Res> {
  _$AppPreferencesCopyWithImpl(this._self, this._then);

  final AppPreferences _self;
  final $Res Function(AppPreferences) _then;

/// Create a copy of AppPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fontFamily = freezed,Object? themeModeIndex = null,Object? firstDayOfWeek = null,}) {
  return _then(_self.copyWith(
fontFamily: freezed == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String?,themeModeIndex: null == themeModeIndex ? _self.themeModeIndex : themeModeIndex // ignore: cast_nullable_to_non_nullable
as int,firstDayOfWeek: null == firstDayOfWeek ? _self.firstDayOfWeek : firstDayOfWeek // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AppPreferences].
extension AppPreferencesPatterns on AppPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppPreferences value)  $default,){
final _that = this;
switch (_that) {
case _AppPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _AppPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? fontFamily,  int themeModeIndex,  int firstDayOfWeek)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppPreferences() when $default != null:
return $default(_that.fontFamily,_that.themeModeIndex,_that.firstDayOfWeek);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? fontFamily,  int themeModeIndex,  int firstDayOfWeek)  $default,) {final _that = this;
switch (_that) {
case _AppPreferences():
return $default(_that.fontFamily,_that.themeModeIndex,_that.firstDayOfWeek);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? fontFamily,  int themeModeIndex,  int firstDayOfWeek)?  $default,) {final _that = this;
switch (_that) {
case _AppPreferences() when $default != null:
return $default(_that.fontFamily,_that.themeModeIndex,_that.firstDayOfWeek);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppPreferences extends AppPreferences {
  const _AppPreferences({this.fontFamily = 'PatrickHand', this.themeModeIndex = 0, this.firstDayOfWeek = DateTime.monday}): super._();
  factory _AppPreferences.fromJson(Map<String, dynamic> json) => _$AppPreferencesFromJson(json);

/// Font family name, or null for system default.
@override@JsonKey() final  String? fontFamily;
/// 0 = system, 1 = light, 2 = dark.
@override@JsonKey() final  int themeModeIndex;
/// First day of the week: 1 = Monday, 7 = Sunday.
@override@JsonKey() final  int firstDayOfWeek;

/// Create a copy of AppPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppPreferencesCopyWith<_AppPreferences> get copyWith => __$AppPreferencesCopyWithImpl<_AppPreferences>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppPreferencesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppPreferences&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.themeModeIndex, themeModeIndex) || other.themeModeIndex == themeModeIndex)&&(identical(other.firstDayOfWeek, firstDayOfWeek) || other.firstDayOfWeek == firstDayOfWeek));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fontFamily,themeModeIndex,firstDayOfWeek);

@override
String toString() {
  return 'AppPreferences(fontFamily: $fontFamily, themeModeIndex: $themeModeIndex, firstDayOfWeek: $firstDayOfWeek)';
}


}

/// @nodoc
abstract mixin class _$AppPreferencesCopyWith<$Res> implements $AppPreferencesCopyWith<$Res> {
  factory _$AppPreferencesCopyWith(_AppPreferences value, $Res Function(_AppPreferences) _then) = __$AppPreferencesCopyWithImpl;
@override @useResult
$Res call({
 String? fontFamily, int themeModeIndex, int firstDayOfWeek
});




}
/// @nodoc
class __$AppPreferencesCopyWithImpl<$Res>
    implements _$AppPreferencesCopyWith<$Res> {
  __$AppPreferencesCopyWithImpl(this._self, this._then);

  final _AppPreferences _self;
  final $Res Function(_AppPreferences) _then;

/// Create a copy of AppPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fontFamily = freezed,Object? themeModeIndex = null,Object? firstDayOfWeek = null,}) {
  return _then(_AppPreferences(
fontFamily: freezed == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String?,themeModeIndex: null == themeModeIndex ? _self.themeModeIndex : themeModeIndex // ignore: cast_nullable_to_non_nullable
as int,firstDayOfWeek: null == firstDayOfWeek ? _self.firstDayOfWeek : firstDayOfWeek // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
