# Native macOS Toolchain

Mackerel-F firmware expects:

```text
m68k-mackerel-elf-gcc
m68k-mackerel-elf-as
m68k-mackerel-elf-ld
m68k-mackerel-elf-objcopy
```

and links against both `-lc` and `-lgcc`.

## Generic Homebrew Toolchain vs Mackerel Toolchain

Homebrew's generic `m68k-elf-gcc` provided GCC, binutils, and libgcc, but no target libc/Newlib:

```bash
m68k-elf-gcc -print-file-name=libc.a
```

returned only:

```text
libc.a
```

rather than a real path.

For the **68k architecture survey itself**, this is not necessarily a problem. Small bare-metal assembly programs and freestanding C tests can be built without Newlib, and that is likely sufficient for many survey labs.

The full Mackerel firmware does link against `-lc`, so reproducing that firmware required a complete toolchain with Newlib. We built the project-specific `m68k-mackerel-elf` toolchain successfully, so it is now the settled toolchain for this workspace even though Newlib is not a survey requirement.

## Settled Toolchain: crosstool-NG Build

Mackerel's supplied configuration was used:

```text
tools/mackerel_crosstools_baremetal_defconfig
```

This builds binutils, GCC, libgcc, and Newlib with the exact `m68k-mackerel-elf-` prefix expected by the firmware Makefile.

## Problem 1: Case Sensitivity

Normal macOS APFS installations are usually case-insensitive even though APFS also supports case-sensitive volumes.

On the normal volume:

```text
foo
Foo
FOO
```

normally refer to the same pathname.

crosstool-NG requires case-sensitive build and install locations, so a case-sensitive APFS sparse image was used.

Example creation:

```bash
hdiutil create -size 20g \
    -fs "Case-sensitive APFS" \
    -type SPARSE \
    -volname crosstool-ng \
    ~/m68k-toolchain
```

Mount:

```bash
diskutil image attach ~/m68k-toolchain.sparseimage
```

The image still mounts at:

```text
/Volumes/crosstool-ng
```

because renaming the image file does not rename the APFS volume inside it.

The toolchain install prefix must also live on that case-sensitive volume:

```text
CT_PREFIX_DIR="/Volumes/crosstool-ng/x-tools/${CT_TARGET}"
```

## Problem 2: Linux-Style Static Host Linking

The supplied defconfig includes Linux-oriented host settings:

```text
CT_STATIC_TOOLCHAIN=y
CT_EXTRA_LDFLAGS_FOR_HOST="-static"
```

For macOS, disable them:

```text
# CT_STATIC_TOOLCHAIN is not set
CT_EXTRA_LDFLAGS_FOR_HOST=""
```

This changes only host-tool linkage, not the generated 68000 ABI.

## Problem 3: zstd Discovery

Binutils failed with:

```text
--with-zstd was given, but pkgconfig/libzstd.pc is not found
```

Expose Homebrew's pkg-config path:

```bash
export PKG_CONFIG_PATH="$(brew --prefix zstd)/lib/pkgconfig:$PKG_CONFIG_PATH"
```

Then rerun:

```bash
ct-ng build
```

## Result

The native Apple-Silicon toolchain installs under:

```text
/Volumes/crosstool-ng/x-tools/m68k-mackerel-elf/
```

Add it to PATH:

```bash
export PATH="/Volumes/crosstool-ng/x-tools/m68k-mackerel-elf/bin:$PATH"
```

The Mackerel-F firmware then builds natively on macOS.

## Sparse Files

A sparse image has a large logical size without immediately consuming that much physical storage.

Linux equivalent:

```bash
truncate -s 20G crosstool-ng.img
```

`ls -lh` reports logical size; `du -h` reports blocks actually allocated.

Linux normally does not need such an image for crosstool-NG because ext4 and similar filesystems are already case-sensitive.
