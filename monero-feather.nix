{ lib
, stdenv
, fetchFromGitHub
, cmake
, openssl
, unbound
, hidapi
, pkg-config
, protobuf
, system
, boost
, qrencode
, qtbase
, wrapQtAppsHook
, libsodium
, qtsvg
, qtmultimedia
, qtwebsockets
, libusb1
, tor
, protobufc
, qtwayland
, gnupg
, expat
, zeromq
, libzip
, libunwind
, libudev0-shim
, libgcrypt
}:
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
  ] ++ (if system != "aarch64-darwin" then [ qtwayland ] else []);
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
