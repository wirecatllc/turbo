{ lib, ... }:
with lib;
let
in
{
  options = {
    acpi = mkOption {
      type = types.bool;
      description = ''
        ACPI is useful for power management, for example, with KVM guests it is required for graceful shutdown to work.
      '';
      default = true;
    };

    apic = mkOption {
      type = types.bool;
      description = ''
        APIC allows the use of programmable IRQ management. Since 0.10.2 (QEMU only) there is an optional attribute eoi with values on and off which toggles the availability of EOI (End of Interrupt) for the guest.
      '';
      default = true;
    };
  };
}
