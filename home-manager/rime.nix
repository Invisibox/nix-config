{pkgs, ...}: let
  rimeWanxiangVersion = "16.1.3";
  rimeWanxiangAssetName = "rime-wanxiang-flypy-fuzhu.zip";
  rimeWanxiangZipHash = "sha256-rvdRU/K/3VkuR//qp4KYeJ8HX8IKZYPltUhJApO2fwY=";
  rimeWanxiangGramHash = "sha256-jRCkhNG0AZsMfPTk6IP8KWGy+qQOqsRGFpw4FAn5OYM=";

  rimeWanxiang = pkgs.stdenvNoCC.mkDerivation {
    pname = "rime-wanxiang";
    version = rimeWanxiangVersion;

    src = pkgs.fetchurl {
      url = "https://github.com/amzxyz/rime_wanxiang/releases/download/v${rimeWanxiangVersion}/${rimeWanxiangAssetName}";
      hash = rimeWanxiangZipHash;
    };

    nativeBuildInputs = [pkgs.unzip];

    unpackPhase = ''
      runHook preUnpack

      unzip -q "$src"

      shopt -s dotglob nullglob
      entries=(*)
      if [ "''${#entries[@]}" -eq 1 ] && [ -d "''${entries[0]}" ]; then
        cd "''${entries[0]}"
      fi

      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      rm -rf README.md .git* LICENSE
      if [ -d custom ]; then
        find custom -type f ! -name '*.yaml' -delete
      fi
      if [ -f default.yaml ]; then
        mv default.yaml wanxiang_suggested_default.yaml
      fi

      mkdir -p "$out/share/rime-data"
      cp -r . "$out/share/rime-data/"

      runHook postInstall
    '';

    meta = {
      changelog = "https://github.com/amzxyz/rime_wanxiang/releases/tag/v${rimeWanxiangVersion}";
      downloadPage = "https://github.com/amzxyz/rime_wanxiang/releases";
    };
  };

  rimeWanxiangLtsGram = pkgs.fetchurl {
    name = "wanxiang-lts-zh-hans.gram";
    url = "https://github.com/amzxyz/RIME-LMDG/releases/download/LTS/wanxiang-lts-zh-hans.gram";
    hash = rimeWanxiangGramHash;
  };
in {
  xdg.dataFile = {
    "fcitx5/rime" = {
      source = "${rimeWanxiang}/share/rime-data";
      recursive = true;
    };

    "fcitx5/rime/default.custom.yaml".text = ''
      patch:
        __include: wanxiang_suggested_default:/
    '';

    "fcitx5/rime/wanxiang_pro.custom.yaml".text = ''
      patch:
        key_binder/bindings/+:
          - { when: paging, accept: comma, send: Page_Up }
          - { when: has_menu, accept: period, send: Page_Down }
        speller/algebra:
          __patch:
            - wanxiang_algebra:/pro/小鹤双拼
            - wanxiang_algebra:/pro/直接辅助
    '';

    "fcitx5/rime/wanxiang_mixedcode.custom.yaml".text = ''
      patch:
        speller/algebra:
          __include: wanxiang_algebra:/mixed/通用派生规则
          __patch: wanxiang_algebra:/mixed/小鹤双拼
    '';

    "fcitx5/rime/wanxiang_reverse.custom.yaml".text = ''
      patch:
        speller/algebra:
          __include: wanxiang_algebra:/reverse/小鹤双拼
          __patch: wanxiang_algebra:/reverse/hspzn
    '';

    "fcitx5/rime/wanxiang_english.custom.yaml".text = ''
      patch:
        speller/algebra:
          __include: wanxiang_algebra:/english/通用规则
          __patch: wanxiang_algebra:/english/小鹤双拼
    '';

    "fcitx5/rime/wanxiang-lts-zh-hans.gram".source = rimeWanxiangLtsGram;
  };
}
