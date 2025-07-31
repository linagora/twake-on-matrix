import '../base/test_base.dart';
import '../help/softAssertionHelper.dart';
import '../robots/chat_list_robot.dart';
import '../scenarios/message_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Checking sending message between members',
    test: ($) async {
      const searchPharse = 'Thu Huyen HOANG';
      const groupID = "!jmWMCwSFwoXpofpmqQ";
      // login by UI

      await TestBase().loginAndRun($, (_) async {});
      // search contact
      //scroll vuot contact
      // click vaof chat bat ky thi ra chi tiet cuar chat voi nguowif ddo
      // back quay tro lai tu man. hinh chat chi tiet dc.  Vì back lai tu man hinh chi tiet co the ve chat lít nên can luu y
      // khi go 1 contact khong ton tai >>> thi phai ra no result
      // khi gõ 1 contact có trong list thì phải có trong list
      // khi click vao search thi phải có hiẻn thi chư contá, biet tuong search, text và dấu đóng
      // khi dong dau x thi phai dong vao
      // nếu gõ đúng chữ với tên người dung thì phaiả hiện lên có chữ Owner
      //nêu hõ chữ vào text thì phai hiện lên bàn phím để send key
      // search băng address matrix
      // search băng chữ hoa chữ thuong deu dc
      // seach băng
      // neu seach băng 1 account đung nhung chua được add bao giờ thi vẫn hiện lên trong chat ?
      // search băngg 1 account khac domanin , giông domain
      // khi vao list chat thì tưng item phai gom co thanh phan gi
      // khi searching thi list của nó , từng item gom các thanh phan gia

      final softAssert = SoftAssertHelper();

    softAssert.softAssertEquals(1 + 1, 2, 'Addition should work');
    softAssert.softAssertEquals('abc'.toUpperCase(), 'ABC', 'Uppercase string');
    softAssert.softAssertEquals(10 ~/ 3, 4, 'Integer division');

    // Gọi verifyAll() cuối cùng để tổng hợp lỗi
    softAssert.verifyAll();

    },
  );
}