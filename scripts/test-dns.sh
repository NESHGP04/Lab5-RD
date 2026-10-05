#!/usr/bin/env bash
# Pruebas DNS-01..05 (+ resolución de WEB-01, MAIL-01, FTP-01, INT-01).
# Ejecutar DESDE un cliente (o la VM de DNS) apuntando a ns1 de la zona.
# Guarda la salida en evidencias/dns/ con fecha para usarla como evidencia.
#
# Uso: ./scripts/test-dns.sh [IP_DEL_DNS]     (por defecto 192.168.71.10)
set -uo pipefail

NS="${1:-192.168.71.10}"
Z="agencia.redes.test"
OUT="$(cd "$(dirname "$0")/.." && pwd)/evidencias/dns/pruebas-dns-$(date +%Y%m%d-%H%M%S).txt"
mkdir -p "$(dirname "$OUT")"

{
echo "Fecha: $(date)  |  Host: $(hostname)  |  Servidor DNS: $NS"
echo
echo "##### DNS-01 Resolución de ns1 #####";  dig @"$NS" ns1.$Z A
echo "##### DNS-02 Resolución de ldap, www, mail, ftp #####"
for h in ldap www mail ftp; do echo "--- $h.$Z"; dig @"$NS" $h.$Z A +noall +answer +comments; done
echo "##### DNS-03 SOA (buscar flag 'aa') #####";        dig @"$NS" $Z SOA
echo "##### NS #####";                                   dig @"$NS" $Z NS +noall +answer
echo "##### DNS-04 / MAIL-01 MX #####";                  dig @"$NS" $Z MX
echo "##### DNS-05 Nombre inexistente (NXDOMAIN) #####"; dig @"$NS" noexiste.$Z A
echo "##### WEB-01 www #####";                           nslookup www.$Z "$NS"
echo "##### MAIL-01 mail #####";                         nslookup mail.$Z "$NS"
echo "##### FTP-01 ftp #####";                           nslookup ftp.$Z "$NS"
echo "##### Resolución por defecto del sistema (sin @servidor) -> INT-01 #####"
for h in ns1 ldap www mail ftp; do echo "--- $h.$Z -> $(dig +short $h.$Z)"; done
} 2>&1 | tee "$OUT"

echo; echo "Evidencia guardada en: $OUT"
