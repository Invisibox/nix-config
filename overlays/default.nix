{...}: {
  nixpkgs.overlays = [
    (final: prev: {
      proton-em = prev.callPackage ./proton-em {};
      proton-ge-bin = prev.proton-ge-bin.overrideAttrs (old: rec {
        version = "GE-Proton10-16";
        src = prev.fetchzip {
          url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
          hash = "sha256-pwnYnO6JPoZS8w2kge98WQcTfclrx7U2vwxGc6uj9k4=";
        };
      });
    })
  ];
}