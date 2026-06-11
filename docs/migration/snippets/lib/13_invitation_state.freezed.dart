// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '13_invitation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvitationState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is InvitationState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'InvitationState()';
  }
}

/// @nodoc
class $InvitationStateCopyWith<$Res> {
  $InvitationStateCopyWith(
      InvitationState _, $Res Function(InvitationState) __);
}

/// Adds pattern-matching-related methods to [InvitationState].
extension InvitationStatePatterns on InvitationState {
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
  TResult maybeMap<TResult extends Object?>({
    TResult Function(InvitationInitial value)? initial,
    TResult Function(InvitationLinkReady value)? linkReady,
    TResult Function(InvitationSent value)? sent,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case InvitationInitial() when initial != null:
        return initial(_that);
      case InvitationLinkReady() when linkReady != null:
        return linkReady(_that);
      case InvitationSent() when sent != null:
        return sent(_that);
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
  TResult map<TResult extends Object?>({
    required TResult Function(InvitationInitial value) initial,
    required TResult Function(InvitationLinkReady value) linkReady,
    required TResult Function(InvitationSent value) sent,
  }) {
    final _that = this;
    switch (_that) {
      case InvitationInitial():
        return initial(_that);
      case InvitationLinkReady():
        return linkReady(_that);
      case InvitationSent():
        return sent(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(InvitationInitial value)? initial,
    TResult? Function(InvitationLinkReady value)? linkReady,
    TResult? Function(InvitationSent value)? sent,
  }) {
    final _that = this;
    switch (_that) {
      case InvitationInitial() when initial != null:
        return initial(_that);
      case InvitationLinkReady() when linkReady != null:
        return linkReady(_that);
      case InvitationSent() when sent != null:
        return sent(_that);
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
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(InvitationLink link, bool isSending)? linkReady,
    TResult Function(String targetUserId)? sent,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case InvitationInitial() when initial != null:
        return initial();
      case InvitationLinkReady() when linkReady != null:
        return linkReady(_that.link, _that.isSending);
      case InvitationSent() when sent != null:
        return sent(_that.targetUserId);
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
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(InvitationLink link, bool isSending) linkReady,
    required TResult Function(String targetUserId) sent,
  }) {
    final _that = this;
    switch (_that) {
      case InvitationInitial():
        return initial();
      case InvitationLinkReady():
        return linkReady(_that.link, _that.isSending);
      case InvitationSent():
        return sent(_that.targetUserId);
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(InvitationLink link, bool isSending)? linkReady,
    TResult? Function(String targetUserId)? sent,
  }) {
    final _that = this;
    switch (_that) {
      case InvitationInitial() when initial != null:
        return initial();
      case InvitationLinkReady() when linkReady != null:
        return linkReady(_that.link, _that.isSending);
      case InvitationSent() when sent != null:
        return sent(_that.targetUserId);
      case _:
        return null;
    }
  }
}

/// @nodoc

class InvitationInitial implements InvitationState {
  const InvitationInitial();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is InvitationInitial);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'InvitationState.initial()';
  }
}

/// @nodoc

class InvitationLinkReady implements InvitationState {
  const InvitationLinkReady({required this.link, this.isSending = false});

  final InvitationLink link;
  @JsonKey()
  final bool isSending;

  /// Create a copy of InvitationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InvitationLinkReadyCopyWith<InvitationLinkReady> get copyWith =>
      _$InvitationLinkReadyCopyWithImpl<InvitationLinkReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InvitationLinkReady &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.isSending, isSending) ||
                other.isSending == isSending));
  }

  @override
  int get hashCode => Object.hash(runtimeType, link, isSending);

  @override
  String toString() {
    return 'InvitationState.linkReady(link: $link, isSending: $isSending)';
  }
}

/// @nodoc
abstract mixin class $InvitationLinkReadyCopyWith<$Res>
    implements $InvitationStateCopyWith<$Res> {
  factory $InvitationLinkReadyCopyWith(
          InvitationLinkReady value, $Res Function(InvitationLinkReady) _then) =
      _$InvitationLinkReadyCopyWithImpl;
  @useResult
  $Res call({InvitationLink link, bool isSending});

  $InvitationLinkCopyWith<$Res> get link;
}

/// @nodoc
class _$InvitationLinkReadyCopyWithImpl<$Res>
    implements $InvitationLinkReadyCopyWith<$Res> {
  _$InvitationLinkReadyCopyWithImpl(this._self, this._then);

  final InvitationLinkReady _self;
  final $Res Function(InvitationLinkReady) _then;

  /// Create a copy of InvitationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? link = null,
    Object? isSending = null,
  }) {
    return _then(InvitationLinkReady(
      link: null == link
          ? _self.link
          : link // ignore: cast_nullable_to_non_nullable
              as InvitationLink,
      isSending: null == isSending
          ? _self.isSending
          : isSending // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  /// Create a copy of InvitationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $InvitationLinkCopyWith<$Res> get link {
    return $InvitationLinkCopyWith<$Res>(_self.link, (value) {
      return _then(_self.copyWith(link: value));
    });
  }
}

/// @nodoc

class InvitationSent implements InvitationState {
  const InvitationSent({required this.targetUserId});

  final String targetUserId;

  /// Create a copy of InvitationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InvitationSentCopyWith<InvitationSent> get copyWith =>
      _$InvitationSentCopyWithImpl<InvitationSent>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InvitationSent &&
            (identical(other.targetUserId, targetUserId) ||
                other.targetUserId == targetUserId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, targetUserId);

  @override
  String toString() {
    return 'InvitationState.sent(targetUserId: $targetUserId)';
  }
}

/// @nodoc
abstract mixin class $InvitationSentCopyWith<$Res>
    implements $InvitationStateCopyWith<$Res> {
  factory $InvitationSentCopyWith(
          InvitationSent value, $Res Function(InvitationSent) _then) =
      _$InvitationSentCopyWithImpl;
  @useResult
  $Res call({String targetUserId});
}

/// @nodoc
class _$InvitationSentCopyWithImpl<$Res>
    implements $InvitationSentCopyWith<$Res> {
  _$InvitationSentCopyWithImpl(this._self, this._then);

  final InvitationSent _self;
  final $Res Function(InvitationSent) _then;

  /// Create a copy of InvitationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? targetUserId = null,
  }) {
    return _then(InvitationSent(
      targetUserId: null == targetUserId
          ? _self.targetUserId
          : targetUserId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
