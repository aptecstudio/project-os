# Funzioni di systemd per la partizione dati cifrata (D-026):
#   repart       crea la partizione dati al primo avvio
#   cryptsetup   sblocca i volumi LUKS2 (crypttab) e dm-verity (passo 4c)
#   openssl      richiesto da repart
PACKAGECONFIG:append = " repart cryptsetup openssl"
