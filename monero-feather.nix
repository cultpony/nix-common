{ lib
, system
, appimageTools
, fetchurl
}:
appimageTools.wrapType2 rec {
  name = "feather";
  version = "2.5.2";
  src = if system == "x86_64-linux" then
    fetchurl {
      url = "https://featherwallet.org/files/releases/linux-appimage/feather-${version}.AppImage";
      hash = "sha256-P5wg9NE9NC1KcT2JNW0OXKsPxmCZs4+nd2mbzWSRGT0=";
    }
  else if system == "aarch64-linux" then
    fetchurl {
      url = "https://featherwallet.org/files/releases/linux-arm64-appimage/feather-${version}-arm64.AppImage";
      hash = "sha256-r4xVmcQBNlw2ky82xpkhwufoDYDEUgOi9aP9+Ts7dGo=";
    }
  else "incompatible system";
  extraPkgs = pkgs: with pkgs; [];
  meta = with lib; {
    description = "Monero Light Wallet for Desktop";
    license = licenses.gpl3;
    homepage = "https://featherwallet.org/";
    maintainers = with maintainers; [ ];
  };
}
