import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';

extension PresentaionContactExtension on PresentationContact {

  bool matched({required bool Function(String) condition}) {
    if (displayName != null && condition(displayName!)) {
      return true;
    }

    if (matrixId != null && condition(matrixId!)) {
      return true;
    }

    if (email != null && condition(email!)) {
      return true;
    } 
    
    if (status != null && condition(status.toString())) {
      return true;
    }

    return false;
  }
}