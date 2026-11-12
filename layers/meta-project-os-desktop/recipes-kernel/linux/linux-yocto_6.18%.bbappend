# linux-yocto 6.18 LTS kernel for the desktop amd64 machine (D-014).
# The OE-Core recipe declares only the QEMU machines as compatible: we add ours and
# start from the reference configuration for 64-bit PCs in yocto-kernel-cache.
COMPATIBLE_MACHINE:project-os-amd64 = "project-os-amd64"
KMACHINE:project-os-amd64 = "common-pc-64"
KBRANCH:project-os-amd64 = "v6.18/standard/base"

# Modern hardware (R-04, D-025) and virtual machines (D-041). Each fragment is checked
# against the kernel Kconfig files with tools/check-kernel-fragments.py, and against the
# final configuration by do_project_os_configcheck below.
FILESEXTRAPATHS:prepend:project-os-amd64 := "${THISDIR}/files:"
SRC_URI:append:project-os-amd64 = " \
    file://storage.cfg \
    file://graphics.cfg \
    file://audio.cfg \
    file://bluetooth.cfg \
    file://wifi.cfg \
    file://ethernet.cfg \
    file://input-platform.cfg \
    file://ab-crypt.cfg \
    file://virt-guest.cfg \
"

# Every option set by our fragments must end up in the final .config with the value we
# asked for. do_kernel_configcheck does not report options dropped because one of their
# dependencies is off: that is how DRM_VMWGFX and DRM_HYPERV went missing (D-041).
# The task does nothing on other machines: it checks only the fragments in SRC_URI,
# which are added for project-os-amd64 alone.
# nooelint: oelint.vars.noncoreoverride
python do_project_os_configcheck() {
    import os
    import re

    fragments = []
    for uri in d.getVar('SRC_URI').split():
        path = uri.split(';')[0]
        if path.startswith('file://') and path.endswith('.cfg'):
            fragments.append(path[len('file://'):])
    if not fragments:
        return

    final = {}
    with open(os.path.join(d.getVar('B'), '.config')) as f:
        for line in f:
            m = re.match(r'^CONFIG_(\w+)=(.*)$', line.strip())
            if m:
                final[m.group(1)] = m.group(2)

    errors = []
    for frag in fragments:
        path = os.path.join(d.getVar('UNPACKDIR'), frag)
        with open(path) as f:
            for n, raw in enumerate(f, 1):
                line = raw.strip()
                m = re.match(r'^CONFIG_(\w+)=(.*)$', line)
                if m:
                    symbol, wanted = m.group(1), m.group(2)
                else:
                    m = re.match(r'^#\s*CONFIG_(\w+) is not set', line)
                    if not m:
                        continue
                    symbol, wanted = m.group(1), 'n'
                got = final.get(symbol, 'n')
                if got != wanted:
                    errors.append("%s:%d: CONFIG_%s=%s requested, final configuration has %s"
                                  % (frag, n, symbol, wanted, got))
    if errors:
        bb.fatal("Kernel options from the project-os fragments did not make it into the "
                 "final configuration (missing dependency?):\n" + "\n".join(errors))
    bb.note("project-os kernel fragments: all options are in the final configuration")
}
do_project_os_configcheck[doc] = "Check the project-os fragments against the final .config"
addtask project_os_configcheck after do_kernel_configcheck before do_compile
