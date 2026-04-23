// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '02_invitation_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvitationStatus {
  bool get isEnabled;
  InvitationMedium get medium;
  InvitationLink? get activeLink;

  /// Create a copy of InvitationStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InvitationStatusCopyWith<InvitationStatus> get copyWith =>
      _$InvitationStatusCopyWithImpl<InvitationStatus>(
          this as InvitationStatus, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InvitationStatus &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled) &&
            (identical(other.medium, medium) || other.medium == medium) &&
            (identical(other.activeLink, activeLink) ||
                other.activeLink == activeLink));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isEnabled, medium, activeLink);

  @override
  String toString() {
    return 'InvitationStatus(isEnabled: $isEnabled, medium: $medium, activeLink: $activeLink)';
  }
}

/// @nodoc
abstract mixin class $InvitationStatusCopyWith<$Res> {
  factory $InvitationStatusCopyWith(
          InvitationStatus value, $Res Function(InvitationStatus) _then) =
      _$InvitationStatusCopyWithImpl;
  @useResult
  $Res call(
      {bool isEnabled, InvitationMedium medium, InvitationLink? activeLink});

  $InvitationLinkCopyWith<$Res>? get activeLink;
}

/// @nodoc
class _$InvitationStatusCopyWithImpl<$Res>
    implements $InvitationStatusCopyWith<$Res> {
  _$InvitationStatusCopyWithImpl(this._self, this._then);

  final InvitationStatus _self;
  final $Res Function(InvitationStatus) _then;

  /// Create a copy of InvitationStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isEnabled = null,
    Object? medium = null,
    Object? activeLink = freezed,
  }) {
    return _then(_self.copyWith(
      isEnabled: null == isEnabled
          ? _self.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      medium: null == medium
          ? _self.medium
          : medium // ignore: cast_nullable_to_non_nullable
              as InvitationMedium,
      activeLink: freezed == activeLink
          ? _self.activeLink
          : activeLink // ignore: cast_nullable_to_non_nullable
              as InvitationLink?,
    ));
  }

  /// Create a copy of InvitationStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $InvitationLinkCopyWith<$Res>? get activeLink {
    if (_self.activeLink == null) {
      return null;
    }

    return $InvitationLinkCopyWith<$Res>(_self.activeLink!, (value) {
      return _then(_self.copyWith(activeLink: value));
    });
  }
}

/// Adds pattern-matching-related methods to [InvitationStatus].
extension InvitationStatusPatterns on InvitationStatus {
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
    TResult Function(_InvitationStatus value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _InvitationStatus() when $default != null:
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
    TResult Function(_InvitationStatus value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InvitationStatus():
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
    TResult? Function(_InvitationStatus value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InvitationStatus() when $default != null:
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
    TResult Function(bool isEnabled, InvitationMedium medium,
            InvitationLink? activeLink)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _InvitationStatus() when $default != null:
        return $default(_that.isEnabled, _that.medium, _that.activeLink);
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
    TResult Function(
            bool isEnabled, InvitationMedium medium, InvitationLink? activeLink)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InvitationStatus():
        return $default(_that.isEnabled, _that.medium, _that.activeLink);
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
    TResult? Function(bool isEnabled, InvitationMedium medium,
            InvitationLink? activeLink)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InvitationStatus() when $default != null:
        return $default(_that.isEnabled, _that.medium, _that.activeLink);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _InvitationStatus implements InvitationStatus {
  const _InvitationStatus(
      {required this.isEnabled, required this.medium, this.activeLink});

  @override
  final bool isEnabled;
  @override
  final InvitationMedium medium;
  @override
  final InvitationLink? activeLink;

  /// Create a copy of InvitationStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$InvitationStatusCopyWith<_InvitationStatus> get copyWith =>
      __$InvitationStatusCopyWithImpl<_InvitationStatus>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _InvitationStatus &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled) &&
            (identical(other.medium, medium) || other.medium == medium) &&
            (identical(other.activeLink, activeLink) ||
                other.activeLink == activeLink));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isEnabled, medium, activeLink);

  @override
  String toString() {
    return 'InvitationStatus(isEnabled: $isEnabled, medium: $medium, activeLink: $activeLink)';
  }
}

/// @nodoc
abstract mixin class _$InvitationStatusCopyWith<$Res>
    implements $InvitationStatusCopyWith<$Res> {
  factory _$InvitationStatusCopyWith(
          _InvitationStatus value, $Res Function(_InvitationStatus) _then) =
      __$InvitationStatusCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool isEnabled, InvitationMedium medium, InvitationLink? activeLink});

  @override
  $InvitationLinkCopyWith<$Res>? get activeLink;
}

/// @nodoc
class __$InvitationStatusCopyWithImpl<$Res>
    implements _$InvitationStatusCopyWith<$Res> {
  __$InvitationStatusCopyWithImpl(this._self, this._then);

  final _InvitationStatus _self;
  final $Res Function(_InvitationStatus) _then;

  /// Create a copy of InvitationStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isEnabled = null,
    Object? medium = null,
    Object? activeLink = freezed,
  }) {
    return _then(_InvitationStatus(
      isEnabled: null == isEnabled
          ? _self.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      medium: null == medium
          ? _self.medium
          : medium // ignore: cast_nullable_to_non_nullable
              as InvitationMedium,
      activeLink: freezed == activeLink
          ? _self.activeLink
          : activeLink // ignore: cast_nullable_to_non_nullable
              as InvitationLink?,
    ));
  }

  /// Create a copy of InvitationStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $InvitationLinkCopyWith<$Res>? get activeLink {
    if (_self.activeLink == null) {
      return null;
    }

    return $InvitationLinkCopyWith<$Res>(_self.activeLink!, (value) {
      return _then(_self.copyWith(activeLink: value));
    });
  }
}

// dart format on
