{
  description = "Standalone build of ddcutil";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Query/change monitor settings via DDC/CI + USB. Linux-only (i2c-dev +
  # libudev device enumeration are kernel-locked).
  #
  # ddcutil's autoconf checks `malloc(0) == NULL` and, since musl returns
  # NULL there, flips on `#define malloc rpl_malloc` — but no gnulib supplies
  # rpl_malloc, so the build breaks on implicit-decl. Tell autoconf the
  # system malloc is fine (musl is POSIX-correct: NULL for size 0 is legal).
  # Same for realloc. See [[feedback_autoconf_rpl_malloc_musl]].
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "ddcutil";
      linuxOnly = true;
      smoke = [ "--version" ];
      smokePattern = "ddcutil";
      build = pkgs:
        let
          p = pkgs.pkgsStatic;
        in
        p.ddcutil.overrideAttrs (old: {
          configureFlags = (old.configureFlags or [ ]) ++ [
            "ac_cv_func_malloc_0_nonnull=yes"
            "ac_cv_func_realloc_0_nonnull=yes"
          ];
        });
    };
}
