{
  fetchurl,
  runCommand,
  innoextract,
}: let
  tuningName = "DEV_0257_SUBSYS_17AA2329_PCI_SUBSYS_232917AA.xml";
  tuningPath = "code$GetExtractPath$/Source/ThirdParty/Dolby/dax3/ext_thinkpad_AIO_rtk_20h1_22h2_24h2_v9.1127.1236.0/${tuningName}";
in
  runCommand tuningName {
    nativeBuildInputs = [innoextract];
    src = fetchurl {
      url = "https://download.lenovo.com/pccbbs/mobiles/n45a127w.exe";
      hash = "sha256-Y698UHbcWJ5JzKtJB92JHHq2kRniuhJqfoe3B4Xg0RU=";
    };
    inherit tuningPath;
    # The vendor XML is extracted locally instead of being kept in Git or a binary cache.
    preferLocalBuild = true;
    allowSubstitutes = false;
  } ''
    innoextract --silent --include "$tuningPath" --output-dir unpacked "$src"
    install -m444 "unpacked/$tuningPath" "$out"
  ''
