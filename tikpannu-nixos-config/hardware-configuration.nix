{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
    "vmw_pvscsi"
  ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/64f6fb02-4fed-4836-a33b-86e8993afdfa";
    fsType = "ext4";
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
