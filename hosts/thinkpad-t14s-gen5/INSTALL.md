# ThinkPad T14s Gen 5 installation

The disk layout targets `/dev/nvme0n1` and destroys all data on that device.
Boot the NixOS installer with Secure Boot disabled, then verify the internal SSD
name before continuing:

```console
lsblk -o NAME,PATH,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS
```

If the 512 GB internal SSD is not `/dev/nvme0n1`, change `device` in
`disko.nix` before running disko.

## Partition and install

From the repository root in the live installer:

```console
sudo nix --extra-experimental-features "nix-command flakes" \
  run github:nix-community/disko/latest -- \
  --mode destroy,format,mount ./hosts/thinkpad-t14s-gen5/disko.nix

sudo nixos-install --flake .#thinkpad-t14s-gen5
```

The first installation is allowed to write unsigned boot artifacts because the
Secure Boot keys do not exist yet. On the first boot,
`generate-sb-keys.service` creates them under `/var/lib/sbctl`. Rebuild once to
replace the initial boot artifacts with signed ones:

```console
sudo systemctl status generate-sb-keys.service
sudo nixos-rebuild switch --flake .#thinkpad-t14s-gen5
sudo sbctl verify
```

## Enroll Secure Boot keys

After `sbctl verify` reports the boot artifacts as signed:

1. Reboot into the ThinkPad firmware setup and open **Security > Secure Boot**.
2. Enable Secure Boot and select **Reset to Setup Mode**. Do not select
   **Clear All Secure Boot Keys**, because that also removes the forbidden
   signature database (`dbx`).
3. Boot NixOS and enroll the generated keys together with Microsoft's keys:

   ```console
   sudo sbctl enroll-keys --microsoft
   ```

4. Reboot and verify enforcement:

   ```console
   bootctl status
   sudo sbctl status
   ```

`bootctl status` should report `Secure Boot: enabled (user)`.

This layout does not encrypt Btrfs. Secure Boot still validates the boot chain,
but disk encryption is required to protect the signing keys and user data from
an attacker with physical access to the SSD.
