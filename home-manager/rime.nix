{pkgs, ...}: {
  xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      __include: wanxiang_suggested_default:/
  '';

  xdg.dataFile."fcitx5/rime/wanxiang_pro.custom.yaml".text = ''
    patch:
      key_binder/bindings/+:
        - { when: paging, accept: comma, send: Page_Up }
        - { when: has_menu, accept: period, send: Page_Down }
      speller/algebra:
        __patch:
          - wanxiang_algebra:/pro/小鹤双拼
          - wanxiang_algebra:/pro/直接辅助
  '';

  xdg.dataFile."fcitx5/rime/wanxiang-lts-zh-hans.gram".source = pkgs.rime-wanxiang-lts-gram;
}
