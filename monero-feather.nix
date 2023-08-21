{ lib
, appimageTools
, fetchurl
}:
appimageTools.wrapType2 {
  name = "feather";
  src = fetchurl {
    url = "https://featherwallet.org/files/releases/linux-appimage/feather-2.4.9.AppImage";
    hash = "sha256-rIw5ppiNDzy9AjzBekVhrKlyQCu+NgWDDA9QaZEONJQ=";
  };
  extraPkgs = pkgs: with pkgs; [];
  meta = with lib; {
    description = "Monero Light Wallet for Desktop";
    license = licenses.gpl3;
    homepage = "https://featherwallet.org/";
    maintainers = with maintainers; [ ];
  };
}
