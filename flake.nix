{
  description = "ddcutil as a single self-contained binary";

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

      # Build via the unpin-llvm engine + emit a bitcode multicall module.
      engine = "unpin-llvm";
      # ddcutil links NO bare `.o` — its executable is assembled entirely from
      # libtool convenience archives (src/Makefile.am: `ddcutil_SOURCES=` is
      # empty, `ddcutil_LDADD= libapp.la libcommon.la`, with main() living in
      # app_ddcutil/main.c → inlined into libapp). The engine's link-capture
      # shim only writes a program sidecar when it sees ≥1 object, so the default
      # inferLinkInputs path finds nothing ("no link sidecar for ddcutil"). So
      # turn inference off (objs = []) and hand-list the two convenience archives
      # instead: the module hook folds them with `ld.lld -r`, which pulls main
      # (and everything reachable) from libapp.a on demand — the same member
      # selection the real link does. Paths follow libtool convention
      # (.libs/lib<n>.a) inside the `src/` build subdir; pinned to ddcutil 2.2.7.
      multicall = {
        programs = [{ name = "ddcutil"; objs = [ ]; }];
        internalArchives = [ "src/.libs/libapp.a" "src/.libs/libcommon.a" ];
        # ddcutil links glib (core containers), libX11 (XRandR display names) and
        # dbus (post-sleep display re-detection). Each static lib inlines its own
        # baked datadir/helper-path constants into ddcutil — glib's localedir +
        # GIO module dir, libX11's locale/compose/XErrorDB/XKeysymDB dirs, dbus's
        # `dbus-launch` — and ddcutil bakes its own install libdir. None are
        # reached at runtime by this self-contained binary (the code is statically
        # linked; the paths don't even exist on the target), yet Nix counts them
        # as runtime refs and drags a ~676 MB build closure (glib -dev → python3,
        # gettext, …). Scrub those dead refs so the binary is truly 0-ref, exactly
        # as the other tier-1 packages. All features stay intact (verified: smoke
        # green after the scrub); this removes build-host path strings, not
        # functionality. See [[feedback_dont_disable_features_silently]] — a scrub
        # of unreachable paths is not a feature disable.
        removeReferences = [ "glib-static" "libx11-static" "dbus-static" "ddcutil-static" ];
      };
      linuxOnly = true;
      smoke = [ "--version" ];
      smokePattern = "ddcutil";
      build = pkgs:
        let
          # libX11 (pulled by ddcutil's optional X11 display-name support, via
          # libXrandr/libXext and dbus) has a configure probe that checks whether
          # its cpp needs -undef to stop predefining `unix`. The engine's clang
          # cpp keeps `unix` defined even under -undef, so the probe aborts
          # ("defines unix with or without -undef. I don't know what to do."). That
          # RAWCPP only preprocesses X11's host-independent locale/compose text at
          # build time, so hand it the build-host gcc cpp (which honors -undef);
          # libX11 links into ddcutil as a plain static .a regardless of which cpp
          # cooked its data. Patch it set-wide so libXrandr/libXext/dbus share the
          # fixed libX11. (Keeping X11 is a deliberate call — it maps DDC displays
          # to XRandR screen names.)
          p = pkgs.pkgsStatic.extend (final: prev: {
            libx11 = prev.libx11.overrideAttrs (_: {
              RAWCPP = "${final.buildPackages.stdenv.cc}/bin/cpp";
            });
          });
        in
        p.ddcutil.overrideAttrs (old: {
          configureFlags = (old.configureFlags or [ ]) ++ [
            "ac_cv_func_malloc_0_nonnull=yes"
            "ac_cv_func_realloc_0_nonnull=yes"
          ];
          # libexecinfo — ddcutil 2.2.7 hard-includes <execinfo.h> in linux_util.c
          # for its crash-backtrace helper, a glibc extension absent from musl
          # ("execinfo.h: No such file"); libexecinfo provides the header + a
          # musl-compatible backtrace, linked via -lexecinfo (ddcutil's link line
          # assumes backtrace lives in libc).
          buildInputs = (old.buildInputs or [ ]) ++ [ p.libexecinfo ];
          NIX_LDFLAGS = (old.NIX_LDFLAGS or "") + " -lexecinfo";
        });
    };
}
