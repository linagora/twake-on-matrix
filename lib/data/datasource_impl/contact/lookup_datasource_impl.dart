import 'package:fluffychat/data/datasource/lookup_datasource.dart';
import 'package:fluffychat/data/network/contact/lookup_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/contact/hash_details_response.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_request.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_response.dart';

class LookupDatasourceImpl implements LookupDatasource {
  final LookupAPI _lookupAPI = getIt.get<LookupAPI>();

  @override
  Future<HashDetailsResponse> getHashDetails() {
    return _lookupAPI.getHashDetails();
  }

  @override
  Future<LookupListMxidResponse> lookupListMxid(
    LookupListMxidRequest request,
  ) async {
    // return _lookupAPI.lookupListMxid(request);
    if (request.addresses?.containsAll(mapping1.keys) == true) {
      return _createLookupListMxidResponse(mapping1);
    }

    if (request.addresses?.containsAll(mapping2.keys) == true) {
      return _createLookupListMxidResponse(mapping2);
    }

    if (request.addresses?.containsAll(mapping3.keys) == true) {
      return _createLookupListMxidResponse(mapping3);
    }

    if (request.addresses?.containsAll(mapping4.keys) == true) {
      return _createLookupListMxidResponse(mapping4);
    }

    if (request.addresses?.containsAll(mapping5.keys) == true) {
      return _createLookupListMxidResponse(mapping5);
    }

    if (request.addresses?.containsAll(mapping6.keys) == true) {
      return _createLookupListMxidResponse(mapping6);
    }

    if (request.addresses?.containsAll(mapping7.keys) == true) {
      return _createLookupListMxidResponse(mapping7);
    }

    if (request.addresses?.containsAll(mapping8.keys) == true) {
      return _createLookupListMxidResponse(mapping8);
    }

    if (request.addresses?.containsAll(mapping9.keys) == true) {
      return _createLookupListMxidResponse(mapping9);
    }

    if (request.addresses?.containsAll(mapping10.keys) == true) {
      return _createLookupListMxidResponse(mapping10);
    }

    if (request.addresses?.containsAll(mapping11.keys) == true) {
      return _createLookupListMxidResponse(mapping11);
    }

    if (request.addresses?.containsAll(mapping12.keys) == true) {
      return _createLookupListMxidResponse(mapping12);
    }

    if (request.addresses?.containsAll(mapping13.keys) == true) {
      return _createLookupListMxidResponse(mapping13);
    }

    return _createLookupListMxidResponse({});
  }

  LookupListMxidResponse _createLookupListMxidResponse(
      Map<String, String> mapping) {
    return LookupListMxidResponse(
      mappings: mapping,
    );
  }

  final mapping1 = {
    "fJcNGXVoRaa8cxZJpE9gfVX4JF4u1cWUb7SzlGXIWSI": "@hello1:matrix.org",
    "Rs8uZy6KNiVcjpk1dDKtsvrB9LTNEpNU5ZyZnP1txjo": "@hello3:matrix.org",
    "1rqNXP6OpnZrXtlA_k0NE6a-8vdmLwlm8lyKF0wTYq4": "@hello5:matrix.org",
    "CMGM0mdXgX0kAzPbTph4CUtaE7-fwVGsm7Ko-wMGccQ": "@hello7:matrix.org",
    "PIfY-6L-CB9h3YzC1Mn33EtXv5TFbTETHC7FERgBWpw": "@hello9:matrix.org",
  };

  final mapping2 = {
    "mMdPZHt4WrzcqlCL2KRpDSqZVyw1kGld-SmGVfwFQc": "@hello11:matrix.org",
    "lxvAR5E06tcWbuZoaTnG3TnGAAUoW4mkT8S2yu5SCT8": "@hello13:matrix.org",
    "3i7Wh86KNkH8-BIC4PypN9j4mnP9k_qR1riO_oHHxmE": "@hello15:matrix.org",
  };

  final mapping3 = {
    "tW3qKESX2ptWMrsSP2sKO4vYK-0Wp-m91tdqDULuMyE": "@hello21:matrix.org",
    "tFSISDS7qbRU1AXjqQ9NOpxOytv9E603eWY7j34bw4M": "hello24:matrix.org",
    "HEPHSgkhTDGWWhu7DOWgwhDfW-iXgmoalzKqfgk-rws": "@hello25:matrix.org",
    "ppKaWeAwOOHYVsdaGqoPrjTO-9azTzjoS2ROlB-VuWI": "@hello29:matrix.org",
    "5j3Q5o8nFu1AtQ0XjbVHnNacT110P0z52AK27Oj_Kw4": "@hello30:matrix.org",
  };

  final mapping4 = {
    "QDLfPwaO2HnZyb-6ywscoxJ5qvsAJjbJIPAPg4zH0Es": "@hello31:matrix.org",
    "yjk5lzHL_XSP4Un-6wuH_Lna558IZMLksuSntEq2xaY": "@hello32:matrix.org",
    "EWujCkcxjriGcHp3316jNl3GCCHm952FuBgZKViHICg": "@hello33:matrix.org",
    "3Qd3Bx3-Ecxs2GHpi4Gu8rjowReqx6aym0Z2U31WJQ": "@hello34:matrix.org",
    "iC7b4PG4a7vwyqF8ITiMZMxVQPHFELK02uPECh1Nor": "@hello35:matrix.org",
    "HMSCmpsEvNIkgmGUAxOLCB5IYCLlumDnS4aSEm8ecgE": "@hello36:matrix.org",
    "-jWCkSp5FqBVudCEYADpHa-fXk42b7rt5zwKIBDOBdA": "@hello37:matrix.org",
    "3kHKgujM9UrS6DvI1nXlt-cDpFAKr68Lb927U6zP5ns": "@hello39:matrix.org",
  };

  final mapping5 = {
    "33Nl5nMsY2E7-xzASrFxzvHeYVdBFzzbsU6ncqUU2k8": "@hello45:matrix.org"
  };

  final mapping6 = {
    "PZbqrkIKgJuYMFz8njXnwm4IYKYaVDx0uXvRbianjM8": "@hello51:matrix.org",
    "9C-kscxjsIYgRDt4RpPSJzyjeFwqbctAqzupKXUeSko": "@hello52:matrix.org",
    "ZnZozSu5fyBocNQFUoa47Ww6IuiruUEaIgxyVr7vpvc": "@hello53:matrix.org",
    "zM2nsjxiGaE_8C3EuJyv_vpJK7Rpp7XA5BL6rnGKuXc": "@hello54:matrix.org",
    "LJ7b4GxljYBbT0lmcKsvYDY2UdcuKBuTuDaWtV9WvUo": "@hello55:matrix.org",
    "y71UYBG6QjLxf4yFIJBnqKrHKKg8pW7Qn4II7I4EQD0": "@hello56:matrix.org",
    "lBt2yLPK_J5oMbtQA5AcwHF7BvpcxaErEFHPZiIRELw": "@hello57:matrix.org",
    "bNdiPfDVW8Kj8osBT1rDYkg--QY_FhPT8dpk6_1KySI": "@hello58:matrix.org",
  };

  final mapping7 = {
    "1KMDVNNUBOVrsXmBjLOX00qaZjEzZYiVGKSOl7Xh8yA": "@hello61:matrix.org",
    "q12hf3M4aP6ywGHjAAaG9gIYgauVDfYuS3Zyc_r5Tvs": "@hello62:matrix.org",
    "5MswbBSEl5uvf7h5JecoXgFvfPeddMVej_u5CM1uMXE": "@hello63:matrix.org",
    "DORPEU8wI0uDdjKWxSY12gnWw_pfTFvb-yo715eLVg": "@hello64:matrix.org",
    "ukMYUaIQ6lI6lE5UnJUjXplaPkflPh5IXJ5pPD1Gy2k": "@hello65:matrix.org",
    "y4dnb1YSFotwcMPzFDRxT5DvV4gyrcjwNNBeqaUzzlk": "@hello67:matrix.org",
    "YAeYKxhTZXc1cR1NWt6Sx_06kfOaLnBtZHw-idfQDiY": "@hello69:matrix.org",
  };
  final mapping8 = {
    "Vl4VMUfsMJT8JExN5_-bWmaCMXEUXurK6zLk-wZ1RiQ": "@hello71:matrix.org",
    "WUUcVbuq8nYl2rxuI7PjX8ltjIObQrj26fyTxvhL1yM": "@hello72:matrix.org",
    "joKCqtbf5ESNsHR8MiMgYi_6I__Vb7u7sDsNhvFiyRQ": "@hello74:matrix.org",
  };

  final mapping9 = {
    "p9b0OuiUPeBkvYyWiJtQbxJWQWDjT-na--zuQW57FRw": "@hello81:matrix.org"
  };
  final mapping10 = {
    "mokSrGILWsXv0SaYGvl2VTMpdNXh8dO5rMiUrbmJMts": "@hello91:matrix.org",
    "rmxEC4cVsjx-YFTS8Z8epWn2emSOsr5wTYIuPSqdAAw": "@hello92:matrix.org",
  };

  final mapping11 = {
    "j8jA8FYPxtccIP2yRkrusmcxu59mxBgjM3-PV1Y66ec": "@hello105:matrix.org",
  };
  final mapping12 = {
    "TwCC4vHJsOmVd6ewWE4LCYJFOc-5WeOVQZQ2uxVuJZ4": "@hello112:matrix.org",
    "LArSA69WKYFvHhOAxdNQzh_rF3MMfulH9xH2eV-MP7I": "@hello113:matrix.org",
  };

  final mapping13 = {
    "ah46z-6iBMnJ8EWLt4PqWJLWeceHsw-S3MtE0QRR69w": "@hello123:matrix.org",
  };
}
