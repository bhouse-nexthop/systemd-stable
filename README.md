# systemd for Ubuntu noble, with networkd nexthop fixes

This branch builds Ubuntu 24.04 (noble)'s `systemd` source package with two extra
patches for `systemd-networkd`. Everything else is Ubuntu's package, unchanged.

- `UBUNTU_VERSION`: the Ubuntu source version to build, fetched from Launchpad.
- `LOCAL_SUFFIX`: appended to that version (`255.4-1ubuntu8.19` + `+nh1`).
- `patches/`: DEP-3 patches appended to Ubuntu's `debian/patches/series`.
- `build.sh`: the build, run in an `ubuntu:24.04` container.
- `.github/workflows/build.yml`: builds on every push (packages as a workflow
  artifact) and publishes a GitHub Release for tags named `noble/<version>`.

## The problem

systemd-networkd v255 aborts when the kernel has an fdb nexthop:

    Assertion 'link' failed at src/network/networkd-nexthop.c:283, function nexthop_add(). Aborting.

FRR zebra installs fdb nexthop groups for MACs behind a remote EVPN multihoming
Ethernet Segment. As soon as a host joins a VNI with such MACs, networkd crash-loops.
Separately, v255 deletes foreign nexthop groups (zebra's ECMP and fdb groups)
whenever it configures a link that lacks `KeepConfiguration=yes`. v256 added
`ManageForeignNextHops=` to prevent that, but v255 ignores the key.

## The patches

1. `network-nexthop-ignore-nexthops-without-oif.patch`: ignore nexthops that are
   neither groups nor blackholes and carry no `NHA_OIF` (fdb nexthops), instead of
   asserting.
2. `network-backport-ManageForeignNextHops.patch`: add `[Network]
   ManageForeignNextHops=` to `networkd.conf`. With `no`, networkd neither
   enumerates nor remembers nexthops it did not configure, so it never removes a
   routing daemon's nexthops.

Upstream PR: https://github.com/systemd/systemd-stable/pull/499 (branch
`v255-fdb-nexthops`).

## Rebasing on a newer Ubuntu update

Set `UBUNTU_VERSION` to the new version (for example `255.4-1ubuntu8.20`), reset
`LOCAL_SUFFIX` to `+nh1` if needed, push, and check that the patches still apply.
The local version sorts below the next Ubuntu update, so hold or pin `systemd`
on hosts that run it until Ubuntu ships the fix.
