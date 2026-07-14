{
  lib,
  stdenvNoCC,
  fetchurl,
  steamDisplayName ? "Proton EM",
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "proton-em";
  version = "10.0-34";

  src = fetchurl {
    url = "https://github.com/Etaash-mathamsetty/Proton/releases/download/EM-${finalAttrs.version}/proton-EM-${finalAttrs.version}.tar.xz";
    hash = "sha256-2WgF5x+34PkViHVYYL10Jl0RGye9QMXhrNNXMBeVRro=";
  };

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
    cp -r ./. $steamcompattool

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
