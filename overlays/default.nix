{...}: let
  rimeWanxiangVersion = "15.9.5";
  rimeWanxiangAssetName = "rime-wanxiang-flypy-fuzhu.zip";
  rimeWanxiangZipHash = "sha256-20WeDXZAmTyK5bK9MI/9YyeaaR53xZp+Ja+BYhAtpDg=";
  rimeWanxiangGramHash = "sha256-pouPhELO4zWYg3En4qJ/QLaLltHsAs0UxKqeY/kCzl4=";
in {
  nixpkgs.overlays = [
    (final: prev: {
      proton-em = prev.callPackage ./proton-em {};
      proton-ge = final.proton-ge-bin.override {
        steamDisplayName = "Proton GE";
      };
      # proton-ge = prev.proton-ge-bin.overrideAttrs (old: rec {
      #   version = "GE-Proton10-27";
      #   src = prev.fetchzip {
      #     url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
      #     hash = "sha256-yBPjPb2LzxdgEobuoeSfs3UZ1XUxZF6vIMYF+fAnLA0=";
      #   };
      # });
      # proton-ge-bin = prev.proton-ge-bin.overrideAttrs (old: rec {
      #   version = "GE-Proton10-16";
      #   src = prev.fetchzip {
      #     url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
      #     hash = "sha256-pwnYnO6JPoZS8w2kge98WQcTfclrx7U2vwxGc6uj9k4=";
      #   };
      # });
      nautilus = prev.nautilus.overrideAttrs (nprev: {
        buildInputs =
          (nprev.buildInputs or [])
          ++ [
            prev.gst_all_1.gst-plugins-good
            prev.gst_all_1.gst-plugins-bad
          ];
      });
      rime-wanxiang = prev.stdenvNoCC.mkDerivation {
        pname = "rime-wanxiang";
        version = rimeWanxiangVersion;

        src = prev.fetchurl {
          url = "https://github.com/amzxyz/rime_wanxiang/releases/download/v${rimeWanxiangVersion}/${rimeWanxiangAssetName}";
          hash = rimeWanxiangZipHash;
        };

        nativeBuildInputs = [prev.unzip];

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

          rm -rf README.md .git* custom LICENSE
          if [ -f default.yaml ]; then
            mv default.yaml wanxiang_suggested_default.yaml
          fi

          mkdir -p "$out/share/rime-data"
          cp -r . "$out/share/rime-data/"

          runHook postInstall
        '';

        meta =
          (prev.rime-wanxiang.meta or {})
          // {
            changelog = "https://github.com/amzxyz/rime_wanxiang/releases/tag/v${rimeWanxiangVersion}";
            downloadPage = "https://github.com/amzxyz/rime_wanxiang/releases";
          };
      };
      rime-wanxiang-lts-gram = prev.fetchurl {
        name = "wanxiang-lts-zh-hans.gram";
        url = "https://github.com/amzxyz/RIME-LMDG/releases/download/LTS/wanxiang-lts-zh-hans.gram";
        hash = rimeWanxiangGramHash;
      };
    })
    (self: super: {
      # 我们要覆盖 'wpsoffice-cn' 这个包

      # wpsoffice-cn = super.wpsoffice-cn.overrideAttrs (oldAttrs: {
      #   # 添加 makeWrapper 到构建输入
      #   nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [super.makeWrapper];
      #   # 我们使用 postInstall 钩子, 在包安装完成后执行额外操作
      #   postInstall =
      #     (oldAttrs.postInstall or "")
      #     + ''
      #       # wrapProgram 是一个Nix提供的便利工具
      #       # 它会为指定程序创建一个包装脚本
      #       # --set <VAR> <VALUE> 会在脚本中设置环境变量
      #       # 为WPS文字 (wps) 创建包装
      #       wrapProgram $out/bin/wps --set QT_IM_MODULE fcitx5
      #       # 为WPS演示 (wpp) 创建包装
      #       wrapProgram $out/bin/wpp --set QT_IM_MODULE fcitx5
      #       # 为WPS表格 (et) 创建包装
      #       wrapProgram $out/bin/et --set QT_IM_MODULE fcitx5
      #     '';
      # });
    })
  ];
}
