import 'package:freezed_annotation/freezed_annotation.dart';

import 'caps.dart';

part 'account.freezed.dart';
part 'account.g.dart';

@freezed
class Account with _$Account {
  const factory Account({
    required String id,
    required String handle,
    required String displayName,
    required String avatar,
    required String instance,
    required bool isPixelfed,
    required InstanceCaps caps,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);
}

