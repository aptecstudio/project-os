# Configurazione di RAUC per il desktop e certificato della CA che verifica gli
# aggiornamenti (D-026). Il certificato NON sta nel repository: si prende dalla cartella
# delle chiavi indicata da PROJECT_OS_KEYS (vedi kas/base.yml e tools/gen-dev-keys.sh).
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
FILESEXTRAPATHS:prepend = "${PROJECT_OS_KEYS}:"
RAUC_KEYRING_FILE = "ca.cert.pem"

python do_fetch:prepend() {
    keys = d.getVar('PROJECT_OS_KEYS') or ''
    if not keys or not os.path.isfile(os.path.join(keys, 'ca.cert.pem')):
        bb.fatal("Certificato della CA non trovato. Imposta PROJECT_OS_KEYS sulla cartella "
                 "delle chiavi; per lo sviluppo creale con tools/gen-dev-keys.sh")
}
