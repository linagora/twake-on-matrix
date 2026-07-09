# Very Good Analysis 10.3.0 migration

This branch imports the `very_good_analysis` 10.3.0 rule set from
`linagora/very_good_analysis` at
`03b8e84c4672c4ee1dec0059cb5ba9318e01fb44`.

It keeps existing Twake Chat analyzer exclusions for generated files,
localization files, test bundles, and migration snippets.

The first `flutter analyze --no-pub` run reports 11,299 diagnostics:

| Severity | Count |
| --- | ---: |
| Error | 674 |
| Warning | 1,224 |
| Info | 9,401 |

## Main sources

| Area | Count |
| --- | ---: |
| `lib` | 7,428 |
| `test` | 3,628 |
| `integration_test` | 240 |

## Top rules

| Rule | Count | Severity |
| --- | ---: | --- |
| `prefer_single_quotes` | 1,021 | info |
| `lines_longer_than_80_chars` | 912 | info |
| `inference_failure_on_instance_creation` | 830 | warning |
| `sort_constructors_first` | 761 | info |
| `prefer_int_literals` | 725 | info |
| `always_put_required_named_parameters_first` | 705 | info |
| `directives_ordering` | 540 | info |
| `omit_local_variable_types` | 486 | info |
| `discarded_futures` | 397 | info |
| `unawaited_futures` | 389 | info |
| `avoid_redundant_argument_values` | 381 | info |
| `avoid_catches_without_on_clauses` | 311 | info |

## Top errors

| Rule | Count | Example |
| --- | ---: | --- |
| `argument_type_not_assignable` | 152 | `lib/config/app_config.dart` |
| `undefined_function` | 151 | `test/data/datasource_impl/contact/phonebook_contact_datasource_impl_test.dart` |
| `undefined_method` | 94 | `lib/data/hive/dto/contact/contact_hive_obj.dart` |
| `undefined_class` | 71 | `test/data/datasource_impl/contact/phonebook_contact_datasource_impl_test.dart` |
| `uri_has_not_been_generated` | 46 | `lib/config/go_routes/app_routes.dart` |
| `mixin_of_non_class` | 46 | `lib/config/go_routes/app_routes.dart` |
| `uri_does_not_exist` | 37 | `test/data/datasource_impl/contact/phonebook_contact_datasource_impl_test.dart` |

## Top warnings

| Rule | Count | Example |
| --- | ---: | --- |
| `inference_failure_on_instance_creation` | 830 | `integration_test/base/core_robot.dart` |
| `strict_raw_type` | 132 | `lib/app_state/success.dart` |
| `inference_failure_on_untyped_parameter` | 95 | `lib/data/local/localizations/language_cache_manager.dart` |
| `inference_failure_on_function_invocation` | 73 | `lib/data/network/dio_client.dart` |
| `inference_failure_on_collection_literal` | 45 | `integration_test/base/test_base.dart` |
| `inference_failure_on_function_return_type` | 37 | `lib/pages/chat/chat_invitation_body.dart` |

## Progressive path

1. Fix hard analyzer errors first, especially generated mocks, generated route files, and migration snippets.
2. Fix strict inference warnings next. Most warnings come from missing generic types and untyped callback parameters.
3. Split style-only infos by rule and path. Start with mechanical rules (`prefer_single_quotes`, `directives_ordering`, line length) after errors are under control.
4. Keep the imported rule set unchanged during migration. If a rule must be relaxed, document the reason in a dedicated follow-up PR.
