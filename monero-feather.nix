{ lib
, stdenv
, fetchFromGitHub
, cmake
, openssl
, unbound
, hidapi
, pkg-config
, protobuf
, python310
, boost
, qrencode
, qtbase
, wrapQtAppsHook
, libsodium
, zxing-cpp
, zip
, zlib
, qtsvg
, qtmultimedia
, qtwebsockets
, libusb1
, graphviz
, tor
, git
, readline
, protobufc
, gettext
, fetchurl
, qtwayland, gnupg, expat, zeromq, zbar, libzip, libunwind, libudev0-shim, libgcrypt}:
stdenv.mkDerivation rec {
  name = "feather";
  version = "2.5.2";
  src = fetchFromGitHub {
    owner = "feather-wallet";
    repo = "feather";
    rev = version;
    fetchSubmodules = true;
    leaveDotGit = true;
    hash = "sha256-czOlTulyzY/3npeOz9LhKlgFoh6kDfyTqTVvxv4CtVk=";
  };
  cmakeFlags = [
    "-DTOR_DIR=${tor}/bin"
    "-DTOR_VERSION=${tor.version}"
    "-DCHECK_UPDATES=OFF"
    "-DDONATE_BEG=OFF"
    "-DUSE_DEVICE_TREZOR=ON"
    "-DWITH_SCANNER=OFF"
    "-DXMRIG=OFF"
    "-DLOCALMONERO=OFF"
  ];
  buildInputs = [
    cmake
    openssl
    
    unbound
    boost
    expat
    gnupg
    hidapi 
    
    qtbase
    qtsvg
    qtwebsockets
    qtmultimedia
    qtwayland

    libgcrypt
    libsodium
    libudev0-shim
    libunwind
    libusb1
    libzip
    hidapi
    
    protobuf
    qrencode
    zeromq
  ];
  runtimeInputs = [
    tor
  ];
  nativeBuildInputs = [
    wrapQtAppsHook protobuf protobufc pkg-config
  ];
  meta = with lib; {
    description = "Monero Light Wallet for Desktop";
    license = licenses.gpl3;
    platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    homepage = "https://featherwallet.org/";
    maintainers = [ ];
  };
}
