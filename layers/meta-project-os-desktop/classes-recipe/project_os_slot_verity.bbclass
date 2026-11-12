# project-os desktop — dm-verity parameters of a system slot for GRUB (step 4c.3, D-047)
#
# meta-oe's image_types_verity appends the hash tree to the erofs image and writes its
# parameters (<image>.verity-params). This class turns them into a GRUB environment
# block, <IMAGE_LINK_NAME>.slot-verity.env, with two variables:
#   roothash         root hash of the tree, the kernel's roothash=
#   verity_options   the rest, as systemd.verity_root_options= (veritytab options)
# The disk image puts it on the EFI partition as slot-A.env (IMAGE_EFI_BOOT_FILES);
# the update bundle carries it and its hook writes it as slot-<bootname>.env.
# GRUB reads it with load_env and only those two variable names.
#
# Inherited through IMAGE_CLASSES, so it does nothing for images without verity in
# IMAGE_FSTYPES (e.g. the initramfs).

# The task must exist only for images with verity, as in image_types_verity, which
# adds its own task the same way
# nooelint: oelint.task.noanonpython
python __anonymous() {
    if 'verity' in d.getVar('IMAGE_FSTYPES').split():
        bb.build.addtask('do_project_os_slot_verity', 'do_image_wic do_image_complete',
                         'do_image_verity', d)
}

python do_project_os_slot_verity() {
    import os

    link = os.path.join(d.getVar('IMGDEPLOYDIR'),
                        d.getVar('IMAGE_LINK_NAME') + '.' + d.getVar('VERITY_IMAGE_FSTYPE'))
    params = {}
    with open(link + '.verity-params') as f:
        for line in f:
            key, _, value = line.strip().partition('=')
            params[key] = value

    data_blocks = int(params['VERITY_DATA_BLOCKS'])
    data_block_size = int(params['VERITY_DATA_BLOCK_SIZE'])
    # image_types_verity writes the tree right after the data, without a verity
    # superblock: every parameter must be given to veritysetup
    options = ','.join([
        'superblock=false',
        'format=%s' % params['VERITY_HASH_TYPE'],
        'data-blocks=%d' % data_blocks,
        'data-block-size=%d' % data_block_size,
        'hash-block-size=%s' % params['VERITY_HASH_BLOCK_SIZE'],
        'hash-offset=%d' % (data_blocks * data_block_size),
        'hash=%s' % params['VERITY_HASH_ALGORITHM'],
        'salt=%s' % params['VERITY_SALT'],
    ])

    # GRUB environment block: header, one variable per line, '#' padding up to exactly
    # 1024 bytes
    block = '# GRUB Environment Block\nroothash=%s\nverity_options=%s\n' % (
        params['VERITY_ROOT_HASH'], options)
    if len(block) > 1024:
        bb.fatal('dm-verity parameters do not fit in a GRUB environment block')
    block += '#' * (1024 - len(block))

    env = os.path.join(d.getVar('IMGDEPLOYDIR'),
                       d.getVar('IMAGE_LINK_NAME') + '.slot-verity.env')
    with open(env, 'w') as f:
        f.write(block)
    bb.note('Slot root hash: %s' % params['VERITY_ROOT_HASH'])
}
do_project_os_slot_verity[doc] = "Write the dm-verity parameters of the slot for GRUB"
