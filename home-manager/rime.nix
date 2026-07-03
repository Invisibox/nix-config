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
}
