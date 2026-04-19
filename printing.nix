{pkgs, ...}: {
  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = [
      # HP LaserJet Pro M401dn
      pkgs.hplip

      # HP Laser MFP 136w uses Samsung ULD lineage; in CUPS pick the M2070
      # family PPD if 136w is not listed directly.
      pkgs.samsung-unified-linux-driver_1_00_37
    ];
  };

  # Enable autodiscovery of network printers
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
