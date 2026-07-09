# Very Good Analysis 10.3.0 migration

This branch imports the `very_good_analysis` 10.3.0 rule set as-is from
`linagora/very_good_analysis` at
`03b8e84c4672c4ee1dec0059cb5ba9318e01fb44`.

The first `flutter analyze` run reports 11,995 diagnostics:

| Severity | Count |
| --- | ---: |
| Error | 735 |
| Warning | 1,241 |
| Info | 10,019 |

## Main sources

| Area | Count |
| --- | ---: |
| `lib` | 7,907 |
| `test` | 3,629 |
| `integration_test` | 272 |
| `docs` | 184 |

## Top rules

| Rule | Count | Severity |
| --- | ---: | --- |
| `prefer_single_quotes` | 1,021 | info |
| `lines_longer_than_80_chars` | 923 | info |
| `inference_failure_on_instance_creation` | 832 | warning |
| `sort_constructors_first` | 767 | info |
| `prefer_int_literals` | 725 | info |
| `always_put_required_named_parameters_first` | 706 | info |
| `directives_ordering` | 540 | info |
| `omit_local_variable_types` | 486 | info |
| `discarded_futures` | 397 | info |
| `unawaited_futures` | 389 | info |
| `avoid_redundant_argument_values` | 381 | info |
| `use_build_context_synchronously` | 331 | info |
| `avoid_catches_without_on_clauses` | 311 | info |

## Top errors

| Rule | Count | Example |
| --- | ---: | --- |
| `undefined_function` | 162 | `docs/migration/snippets/lib/18_invitation_test.dart` |
| `argument_type_not_assignable` | 153 | `docs/migration/snippets/lib/16_invitation_page.dart` |
| `undefined_method` | 104 | `docs/migration/snippets/lib/06b_invitation_endpoint.dart` |
| `undefined_class` | 71 | `test/data/datasource_impl/contact/phonebook_contact_datasource_impl_test.dart` |
| `uri_has_not_been_generated` | 49 | `docs/migration/snippets/lib/06b_invitation_endpoint.dart` |
| `mixin_of_non_class` | 46 | `lib/config/go_routes/app_routes.dart` |
| `uri_does_not_exist` | 38 | `docs/migration/snippets/lib/06b_invitation_endpoint.dart` |

## Progressive path

1. Fix hard analyzer errors first, especially generated mocks, generated route files, and migration snippets.
2. Fix strict inference warnings next. Most warnings come from missing generic types and untyped callback parameters.
3. Split style-only infos by rule and path. Start with mechanical rules (`prefer_single_quotes`, `directives_ordering`, line length) after errors are under control.
4. Keep the imported rule set unchanged during migration. If a rule must be relaxed, document the reason in a dedicated follow-up PR.
