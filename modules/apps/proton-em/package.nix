{
  lib,
  stdenvNoCC,
  fetchzip,
  steamDisplayName ? "Proton EM",
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "proton-em";
  version = "10.0-37-HDR";

  src = fetchzip {
    url = "https://github.com/Etaash-mathamsetty/Proton/releases/download/EM-${finalAttrs.version}/proton-EM-${finalAttrs.version}.tar.xz";
    hash = "sha256-yap/7G6TeJ9vMtc5H/iWu8w3sM8mI6762G+K2JzSlgk=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  outputs = [
    "out"
    "steamcompattool"
  ];

  installPhase = ''
    runHook preInstall

    echo "${finalAttrs.pname} should not be installed into environments. Please use programs.steam.extraCompatPackages instead." > $out

    mkdir $steamcompattool
    ln -s $src/* $steamcompattool
    rm $steamcompattool/compatibilitytool.vdf
    cp $src/compatibilitytool.vdf $steamcompattool

    runHook postInstall
  '';

  preFixup = ''
    substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
      --replace-fail "proton-EM-${finalAttrs.version}" "${steamDisplayName}" \
      --replace-fail "-proton" ""
  '';

  meta = {
    description = "Development Oriented Compatibility tool for Steam Play based on Wine and additional components";
    homepage = "https://github.com/Etaash-mathamsetty/Proton";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [keenanweaver];
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
