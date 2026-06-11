// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '01_invitation_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvitationLink {
  String get url;
  DateTime get expiresAt;
  String get roomId;

  /// Create a copy of InvitationLink
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InvitationLinkCopyWith<InvitationLink> get copyWith =>
      _$InvitationLinkCopyWithImpl<InvitationLink>(
          this as InvitationLink, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InvitationLink &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.roomId, roomId) || other.roomId == roomId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, url, expiresAt, roomId);

  @override
  String toString() {
    return 'InvitationLink(url: $url, expiresAt: $expiresAt, roomId: $roomId)';
  }
}

/// @nodoc
abstract mixin class $InvitationLinkCopyWith<$Res> {
  factory $InvitationLinkCopyWith(
          InvitationLink value, $Res Function(InvitationLink) _then) =
      _$InvitationLinkCopyWithImpl;
  @useResult
  $Res call({String url, DateTime expiresAt, String roomId});
}

/// @nodoc
class _$InvitationLinkCopyWithImpl<$Res>
    implements $InvitationLinkCopyWith<$Res> {
  _$InvitationLinkCopyWithImpl(this._self, this._then);

  final InvitationLink _self;
  final $Res Function(InvitationLink) _then;

  /// Create a copy of InvitationLink
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? expiresAt = null,
    Object? roomId = null,
  }) {
    return _then(_self.copyWith(
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: null == expiresAt
          ? _self.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      roomId: null == roomId
          ? _self.roomId
          : roomId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [InvitationLink].
extension InvitationLinkPatterns on InvitationLink {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_InvitationLink value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _InvitationLink() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_InvitationLink value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InvitationLink():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_InvitationLink value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InvitationLink() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String url, DateTime expiresAt, String roomId)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _InvitationLink() when $default != null:
        return $default(_that.url, _that.expiresAt, _that.roomId);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String url, DateTime expiresAt, String roomId) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InvitationLink():
        return $default(_that.url, _that.expiresAt, _that.roomId);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String url, DateTime expiresAt, String roomId)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InvitationLink() when $default != null:
        return $default(_that.url, _that.expiresAt, _that.roomId);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _InvitationLink implements InvitationLink {
  const _InvitationLink(
      {required this.url, required this.expiresAt, required this.roomId});

  @override
  final String url;
  @override
  final DateTime expiresAt;
  @override
  final String roomId;

  /// Create a copy of InvitationLink
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$InvitationLinkCopyWith<_InvitationLink> get copyWith =>
      __$InvitationLinkCopyWithImpl<_InvitationLink>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _InvitationLink &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.roomId, roomId) || other.roomId == roomId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, url, expiresAt, roomId);

  @override
  String toString() {
    return 'InvitationLink(url: $url, expiresAt: $expiresAt, roomId: $roomId)';
  }
}

/// @nodoc
abstract mixin class _$InvitationLinkCopyWith<$Res>
    implements $InvitationLinkCopyWith<$Res> {
  factory _$InvitationLinkCopyWith(
          _InvitationLink value, $Res Function(_InvitationLink) _then) =
      __$InvitationLinkCopyWithImpl;
  @override
  @useResult
  $Res call({String url, DateTime expiresAt, String roomId});
}

/// @nodoc
class __$InvitationLinkCopyWithImpl<$Res>
    implements _$InvitationLinkCopyWith<$Res> {
  __$InvitationLinkCopyWithImpl(this._self, this._then);

  final _InvitationLink _self;
  final $Res Function(_InvitationLink) _then;

  /// Create a copy of InvitationLink
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? url = null,
    Object? expiresAt = null,
    Object? roomId = null,
  }) {
    return _then(_InvitationLink(
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: null == expiresAt
          ? _self.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      roomId: null == roomId
          ? _self.roomId
          : roomId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
