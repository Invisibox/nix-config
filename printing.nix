{
  config,
  pkgs,
  inputs,
  ...
}: {
  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      cups-filters
      cups-browsed
    ];
    cups-pdf = {
      enable = true;
      instances.pdf.settings = {
        Out = "\${HOME}/Documents/CUPS-PDF";
        UserUMask = "0033";
        TitlePref = "1";
      };
    };
  };

  # Enable autodiscovery of network printers
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
