import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/pages/activity/activity_filter.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'activity_view_controller.g.dart';

typedef ActivityViewState = ({ActivityFilter filter, String query});

/// The filter and the search of the Activity tab. Kept alive: on a wide
/// screen the page is built again when the user comes back from an item.
@Riverpod(keepAlive: true)
class ActivityViewController extends _$ActivityViewController {
  @override
  ActivityViewState build() {
    // The filter and the search of an account mean nothing to the next one.
    ref.watch(activeMatrixClientProvider);
    return (filter: ActivityFilter.all, query: '');
  }

  void selectFilter(ActivityFilter filter) =>
      state = (filter: filter, query: state.query);

  void search(String query) => state = (filter: state.filter, query: query);
}
