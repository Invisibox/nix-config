{inputs, ...}: {
  flake.modules.homeManager.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    rimeWanxiang = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.rime-wanxiang;

    rimeSharedData = "${pkgs.fcitx5-rime.override {
      rimeDataPkgs = [pkgs.rime-data];
    }}/share/rime-data";
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
    };

    home.activation.redeployRimeWanxiang = lib.hm.dag.entryAfter ["linkGeneration"] ''
      rime_dir="${config.xdg.dataHome}/fcitx5/rime"
      state_file="$rime_dir/.hm-rime-wanxiang-state"
      state="$(
        printf '%s\n' '${rimeSharedData}'
        printf '%s\n' '${rimeWanxiang}/share/rime-data'
        for file in \
          default.custom.yaml \
          wanxiang_pro.custom.yaml \
          wanxiang_mixedcode.custom.yaml \
          wanxiang_reverse.custom.yaml \
          wanxiang_english.custom.yaml
        do
          readlink -f "$rime_dir/$file" 2>/dev/null || true
        done
      )"

      if [ ! -f "$state_file" ] || [ "$state" != "$(cat "$state_file")" ]; then
        if [[ -v DRY_RUN ]]; then
          echo "Would rebuild Rime data in $rime_dir"
        else
          (
            build_dir="$(mktemp -d "$rime_dir/.build.XXXXXX")"
            trap 'rm -rf -- "$build_dir"' EXIT
            ${pkgs.librime}/bin/rime_deployer --build "$rime_dir" '${rimeSharedData}' "$build_dir"

            # Exchange directories atomically so a failed replacement keeps the old cache.
            mkdir -p "$rime_dir/build"
            mv -T --exchange "$build_dir" "$rime_dir/build"
            printf '%s' "$state" > "$state_file"

            if [ "$(
              ${pkgs.systemd}/bin/busctl --user call \
                org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 CanRestart \
                2>/dev/null || true
            )" = "b true" ]; then
              ${pkgs.systemd}/bin/busctl --user call \
                org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 Restart \
                >/dev/null 2>&1 || true
            fi
          )
        fi
      fi
    '';
  };
}
