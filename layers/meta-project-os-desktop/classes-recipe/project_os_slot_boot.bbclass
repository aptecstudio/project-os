# project-os desktop — boot files of a system slot (steps 4c.3 and 4c.4, D-047, D-048)
#
# The slot holds no kernel: everything needed to boot it lives on the EFI partition,
# in EFI/project-os/<A|B>/, and is built here as <IMAGE_LINK_NAME>.slot-boot/:
#   project-os.efi       unified kernel image (UKI) for UEFI: systemd-boot stub,
#                        kernel, early archives (CPU microcode) and initramfs, with two
#                        profiles, @0 for slot A and @1 for slot B, each with its own
#                        kernel command line (the same image can be installed in either
#                        slot, and the line must name the slot's partition)
#   bzImage              kernel, early archives and initramfs as separate files, for
#   <early archives>     GRUB when the PC boots from BIOS (no UKI there, R-26)
#   initramfs.cpio.zst
#   boot.env             GRUB environment block with cmdline_a and cmdline_b, the same
#                        command lines as the two profiles, for the BIOS path
# The command lines carry the dm-verity root hash and tree parameters of the image,
# written by meta-oe's image_types_verity (<image>.verity-params).
#
# The disk image copies the directory to EFI/project-os/A (IMAGE_EFI_BOOT_FILES); the
# update bundle carries it and its hook copies it to EFI/project-os/<bootname>.
#
# Inherited through IMAGE_CLASSES, so it does nothing for images without verity in
# IMAGE_FSTYPES (e.g. the initramfs).

# EFI_ARCH (x64) for the stubs and the UKI, as in OE's uki class. The file is in
# OE-Core, found through BBPATH, which oelint-adv does not search
# nooelint: oelint.file.requirenotfound
require conf/image-uefi.conf

# Kernel command line shared by both slots (set by the machine); the class adds the
# root hash and the slot's own part
PROJECT_OS_KERNEL_CMDLINE ??= ""
# Archives loaded before the initramfs (e.g. CPU microcode, which the kernel must find
# uncompressed at the very start), relative to DEPLOY_DIR_IMAGE, and their tasks
PROJECT_OS_EARLY_INITRD ??= ""
PROJECT_OS_EARLY_INITRD_DEPENDS ??= ""
PROJECT_OS_INITRAMFS ??= "project-os-initramfs"

# The task must exist only for images with verity, as in image_types_verity, which
# adds its own task the same way
# nooelint: oelint.task.noanonpython
python __anonymous() {
    if 'verity' in d.getVar('IMAGE_FSTYPES').split():
        bb.build.addtask('do_project_os_slot_boot', 'do_image_wic do_image_complete',
                         'do_image_verity', d)
}

do_project_os_slot_boot[depends] += "\
    ${PROJECT_OS_EARLY_INITRD_DEPENDS} \
    ${PROJECT_OS_INITRAMFS}:do_image_complete \
    systemd-boot-native:do_populate_sysroot \
    systemd-boot:do_deploy \
    virtual/kernel:do_deploy \
"
do_project_os_slot_boot[cleandirs] = "\
    ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.slot-boot \
    ${WORKDIR}/slot-boot \
"

python do_project_os_slot_boot() {
    import os
    import shutil
    import subprocess

    deploy = d.getVar('DEPLOY_DIR_IMAGE')
    work = os.path.join(d.getVar('WORKDIR'), 'slot-boot')
    out = os.path.join(d.getVar('IMGDEPLOYDIR'), d.getVar('IMAGE_LINK_NAME') + '.slot-boot')

    # dm-verity parameters of the image. image_types_verity writes the tree right after
    # the data, without a verity superblock: every parameter must be given.
    link = os.path.join(d.getVar('IMGDEPLOYDIR'),
                        d.getVar('IMAGE_LINK_NAME') + '.' + d.getVar('VERITY_IMAGE_FSTYPE'))
    params = {}
    with open(link + '.verity-params') as f:
        for line in f:
            key, _, value = line.strip().partition('=')
            params[key] = value
    data_blocks = int(params['VERITY_DATA_BLOCKS'])
    data_block_size = int(params['VERITY_DATA_BLOCK_SIZE'])
    verity_options = ','.join([
        'superblock=false',
        'format=%s' % params['VERITY_HASH_TYPE'],
        'data-blocks=%d' % data_blocks,
        'data-block-size=%d' % data_block_size,
        'hash-block-size=%s' % params['VERITY_HASH_BLOCK_SIZE'],
        'hash-offset=%d' % (data_blocks * data_block_size),
        'hash=%s' % params['VERITY_HASH_ALGORITHM'],
        'salt=%s' % params['VERITY_SALT'],
    ])

    # One command line per slot: data and hash tree on the same partition, found by
    # its GPT label; rauc.slot tells RAUC which slot is booted
    cmdlines = {}
    for slot in ('a', 'b'):
        cmdlines[slot] = ' '.join([
            ' '.join(d.getVar('PROJECT_OS_KERNEL_CMDLINE').split()),
            'roothash=%s' % params['VERITY_ROOT_HASH'],
            'systemd.verity_root_options=%s' % verity_options,
            'systemd.verity_root_data=PARTLABEL=root_%s' % slot,
            'systemd.verity_root_hash=PARTLABEL=root_%s' % slot,
            'rauc.slot=%s' % slot.upper(),
        ])

    kernel = os.path.join(deploy, d.getVar('KERNEL_IMAGETYPE'))
    early = [os.path.join(deploy, f) for f in d.getVar('PROJECT_OS_EARLY_INITRD').split()]
    initramfs = os.path.join(deploy, '%s-%s.cpio.zst' % (d.getVar('PROJECT_OS_INITRAMFS'),
                                                        d.getVar('MACHINE')))
    stub = os.path.join(deploy, 'linux%s.efi.stub' % d.getVar('EFI_ARCH'))
    # A profile alone is built on the addon stub (no kernel in it)
    addon_stub = os.path.join(deploy, 'addon%s.efi.stub' % d.getVar('EFI_ARCH'))
    os_release = d.expand('${IMAGE_ROOTFS}${nonarch_libdir}/os-release')

    # ukify comes from systemd-boot-native and runs on the native Python, with pefile
    env = dict(os.environ, PATH=d.getVar('PATH'))

    def ukify(args):
        cmd = ['ukify', 'build'] + args
        bb.note('Running: %s' % ' '.join(cmd))
        result = subprocess.run(cmd, capture_output=True, text=True, env=env)
        if result.returncode != 0:
            bb.fatal('ukify failed:\n%s%s' % (result.stdout, result.stderr))

    def profile_id(slot):
        return '--profile=ID=slot-%s\nTITLE=project-os, slot %s' % (slot, slot.upper())

    # The UKI itself is profile 0, slot A: its .profile and .cmdline come first, so the
    # stub uses them for @0 (and when started with no profile at all). Slot B is
    # profile 1, built on its own on the addon stub (no kernel in it) and joined.
    # Joining A as a separate profile instead makes ukify add an empty base profile
    # ("main", no command line) as @0.
    profile_b = os.path.join(work, 'profile-b.efi')
    ukify([profile_id('b'),
           '--cmdline=%s' % cmdlines['b'],
           '--stub=%s' % addon_stub,
           '--efi-arch=%s' % d.getVar('EFI_ARCH'),
           '--output=%s' % profile_b])
    # The early archives go first: the kernel looks for the microcode only at the
    # start of the initrd, uncompressed
    initrd_args = ['--initrd=%s' % f for f in early + [initramfs]]
    ukify(['--linux=%s' % kernel] + initrd_args +
          [profile_id('a'),
           '--cmdline=%s' % cmdlines['a'],
           '--stub=%s' % stub,
           '--efi-arch=%s' % d.getVar('EFI_ARCH'),
           '--os-release=@%s' % os_release,
           '--join-profile=%s' % profile_b,
           '--output=%s' % os.path.join(out, 'project-os.efi')])

    # BIOS path: the same files, separate
    for path in [kernel] + early:
        shutil.copyfile(path, os.path.join(out, os.path.basename(path)))
    shutil.copyfile(initramfs, os.path.join(out, 'initramfs.cpio.zst'))

    # GRUB environment block: header, one variable per line, '#' padding up to a fixed
    # size (2048 bytes: the two command lines do not fit in grub-editenv's 1024)
    block = '# GRUB Environment Block\ncmdline_a=%s\ncmdline_b=%s\n' % (cmdlines['a'],
                                                                      cmdlines['b'])
    if len(block) > 2048:
        bb.fatal('The kernel command lines do not fit in a 2048-byte GRUB environment block')
    block += '#' * (2048 - len(block))
    with open(os.path.join(out, 'boot.env'), 'w') as f:
        f.write(block)
    bb.note('Slot root hash: %s' % params['VERITY_ROOT_HASH'])
}
do_project_os_slot_boot[doc] = "Build the boot files of the slot for the EFI partition"
