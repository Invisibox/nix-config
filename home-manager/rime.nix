{
  config,
  lib,
  pkgs,
  ...
}: let
  rimeSharedData = "${pkgs.fcitx5-rime.override {
    rimeDataPkgs = [
      pkgs.rime-data
      pkgs.rime-wanxiang
    ];
  }}/share/rime-data";
in {
  xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      __include: wanxiang_suggested_default:/
  '';

  xdg.dataFile."fcitx5/rime/wanxiang_pro.custom.yaml".text = ''
    patch:
      key_binder/bindings/+:
        - { when: paging, accept: comma, send: Page_Up }
        - { when: has_menu, accept: period, send: Page_Down }
      engine/filters:
        - lua_filter@*wanxiang.auto_phrase
        - lua_filter@*wanxiang.super_lookup
        - lua_filter@*wanxiang.super_english
        - lua_filter@*wanxiang.super_comment_preedit
        - lua_filter@*wanxiang.super_replacer
        - lua_filter@*wanxiang.super_filter
        - lua_filter@*wanxiang.super_sequence*F
        - lua_filter@*wanxiang.user_predict*F
        - uniquifier
      speller/algebra:
        __patch:
          - wanxiang_algebra:/pro/小鹤双拼
          - wanxiang_algebra:/pro/直接辅助
  '';

  xdg.dataFile."fcitx5/rime/wanxiang_mixedcode.custom.yaml".text = ''
    patch:
      speller/algebra:
        __include: wanxiang_algebra:/mixed/通用派生规则
        __patch: wanxiang_algebra:/mixed/小鹤双拼
  '';

  xdg.dataFile."fcitx5/rime/wanxiang_reverse.custom.yaml".text = ''
    patch:
      speller/algebra:
        __include: wanxiang_algebra:/reverse/小鹤双拼
        __patch: wanxiang_algebra:/reverse/hspzn
  '';

  xdg.dataFile."fcitx5/rime/wanxiang_english.custom.yaml".text = ''
    patch:
      speller/algebra:
        __include: wanxiang_algebra:/english/通用规则
        __patch: wanxiang_algebra:/english/小鹤双拼
  '';

  xdg.dataFile."fcitx5/rime/wanxiang-lts-zh-hans.gram".source = pkgs.rime-wanxiang-lts-gram;

  home.activation.redeployRimeWanxiang = lib.hm.dag.entryAfter ["writeBoundary"] ''
    rime_dir="${config.xdg.dataHome}/fcitx5/rime"
    state_file="$rime_dir/.hm-rime-wanxiang-state"
    state="$(
      printf '%s\n' '${rimeSharedData}'
      for file in \
        default.custom.yaml \
        wanxiang_pro.custom.yaml \
        wanxiang_mixedcode.custom.yaml \
        wanxiang_reverse.custom.yaml \
        wanxiang_english.custom.yaml \
        wanxiang-lts-zh-hans.gram
      do
        readlink -f "$rime_dir/$file" 2>/dev/null || true
      done
    )"

    if [ ! -f "$state_file" ] || [ "$state" != "$(cat "$state_file")" ]; then
      if [ -d "$rime_dir/build" ]; then
        mv "$rime_dir/build" "$rime_dir/build.backup-$(date +%Y%m%d%H%M%S)"
      fi
      mkdir -p "$rime_dir/build"
      ${pkgs.librime}/bin/rime_deployer --build "$rime_dir" '${rimeSharedData}' "$rime_dir/build"
      printf '%s' "$state" > "$state_file"
    fi
  '';
}
