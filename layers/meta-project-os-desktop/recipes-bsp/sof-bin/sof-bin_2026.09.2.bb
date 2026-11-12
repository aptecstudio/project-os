SUMMARY = "Sound Open Firmware for Intel audio DSPs"
DESCRIPTION = "Firmware and topologies for the audio DSP of Intel laptops and PCs \
(Sound Open Firmware), loaded by the kernel's SOF drivers. Needed for internal \
speakers and microphones on most Intel laptops from the 11th generation on (R-04, \
D-025, D-039). Not in linux-firmware: released by the SOF project as sof-bin."
HOMEPAGE = "https://github.com/thesofproject/sof-bin"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENCE.Intel;md5=54b4f1a2dd35fd85bc7a1d4afa731b78"

SRC_URI = "https://github.com/thesofproject/sof-bin/releases/download/v${PV}/sof-bin-${PV}.tar.gz"
# Same digest as published by GitHub for the release asset
SRC_URI[sha256sum] = "5f7bc30b2b5c1e6b0da55a33fc44e2b7f56ae9b06952edcde614f51ef6b943e1"
S = "${UNPACKDIR}/sof-bin-${PV}"

inherit allarch

DEPENDS = "zstd-native"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

FW_DIR = "${nonarch_base_libdir}/firmware/intel"

do_install() {
    install -d ${D}${FW_DIR}
    # Same layout as the upstream install.sh; the tools/ directory (sof-logger and other
    # debugging tools) is not installed
    for dir in sof sof-ipc4 sof-ipc4-lib sof-ipc4-tplg sof-tplg; do
        cp -R --no-preserve=ownership ${S}/$dir ${D}${FW_DIR}/
    done
    ln -s sof-ipc4-tplg ${D}${FW_DIR}/sof-ace-tplg

    # Not needed on an amd64 PC (R-02):
    #   *.ldc               debug-log dictionaries, read only by sof-logger
    #   *imx*, *mt81*       topologies for NXP i.MX and MediaTek ARM DSPs
    #   sof-rn*, sof-acp*   AMD topologies: the AMD driver looks for them in amd/, and
    #                       sof-bin ships no AMD firmware
    find ${D}${FW_DIR} \( -name '*.ldc' -o -name '*imx*' -o -name '*mt81*' \
        -o -name 'sof-rn*' -o -name 'sof-acp*' \) -delete

    # zstd compression, like the rest of the firmware (FIRMWARE_COMPRESSION, D-025): the
    # kernel loader decompresses .zst files (CONFIG_FW_LOADER_COMPRESS_ZSTD)
    find ${D}${FW_DIR} -type f -exec zstd -q -19 --rm {} \;
    # Symbolic links to files now point to the compressed name. Links can point to
    # other links (e.g. arl -> arl/intel-signed -> mtl): repeat until nothing changes
    changed=1
    while [ "$changed" = 1 ]; do
        changed=0
        for link in $(find ${D}${FW_DIR} -type l ! -name '*.zst'); do
            target=$(readlink "$link")
            if [ -e "$(dirname "$link")/$target.zst" ]; then
                ln -s "$target.zst" "$link.zst"
                rm "$link"
                changed=1
            fi
        done
    done
    broken=$(find ${D}${FW_DIR} -xtype l)
    if [ -n "$broken" ]; then
        bbfatal "Broken symbolic links in the SOF firmware: $broken"
    fi
}

FILES:${PN} = "${FW_DIR}"
