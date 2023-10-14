{ linkFarm, fetchzip }:

linkFarm "zig-packages" [
  {
    name = "12206e93994d37b3ce5c790e391736130f2a26bec06eca01ca51ab08a6d8105ab7f9";
    path = fetchzip {
      url = "https://pkg.machengine.org/mach-core/9243a331a3eb0d4ba97aec7f793e60f1cf90bd8b.tar.gz";
      hash = "sha256-1R1xQyJmz+gxTgB7ysW89FbeftGqBQFIujxauLWRjko=";
    };
  }
  {
    name = "12205cd22eb1e26ea16e973fe57fb297535246d64454e3ccae8a39783c97ea488a83";
    path = fetchzip {
      url = "https://pkg.machengine.org/mach-gpu-dawn/5d463ceb63246b3b73070c774465c67dd657e045.tar.gz";
      hash = "sha256-8ncYUUmt8saB0yhPe3esOD/lDK+Ab7/hbkyGzsKmRpM=";
    };
  }
  {
    name = "1220293eae4bf67a7c27a18a8133621337cde91a97bc6859a9431b3b2d4217dfb5fb";
    path = fetchzip {
      url = "https://github.com/hexops/xcode-frameworks-pkg/archive/d486474a6af7fafd89e8314e0bf7eca4709f811b.tar.gz";
      hash = "sha256-fVgkzDYdWPPXE3k+wfE9vJ00gqNTNQH8Dl0jpT6GR94=";
    };
  }
]