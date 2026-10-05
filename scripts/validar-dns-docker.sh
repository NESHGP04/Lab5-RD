#!/usr/bin/env bash
# Valida la config de BIND9 del repo dentro de un contenedor Ubuntu (NO es la
# evidencia final: esa debe salir de la VM real). Sirve para detectar errores
# de sintaxis y probar dig A/NS/MX/SOA/NXDOMAIN antes de pasar los archivos a la VM.
#
# Uso: ./scripts/validar-dns-docker.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/evidencias/dns/validacion-docker.txt"
mkdir -p "$(dirname "$OUT")"

docker run --rm -v "$ROOT/dns:/repo-dns:ro" ubuntu:24.04 bash -c '
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq bind9 bind9-utils dnsutils >/dev/null 2>&1

mkdir -p /etc/bind/zones
cp /repo-dns/named.conf.options /repo-dns/named.conf.local /etc/bind/
cp /repo-dns/zones/db.agencia.redes.test /etc/bind/zones/

echo "=== named-checkconf ==="
named-checkconf -z /etc/bind/named.conf && echo "named-checkconf: OK"

echo; echo "=== named-checkzone ==="
named-checkzone agencia.redes.test /etc/bind/zones/db.agencia.redes.test

# En el contenedor la IP 192.168.71.10 no existe: para la prueba de consultas
# se escucha en todas las interfaces (solo en este contenedor).
sed -i "s|listen-on { .*|listen-on { any; };|; s|allow-query { .*|allow-query { any; };|; s|allow-recursion { .*|allow-recursion { any; };|" /etc/bind/named.conf.options
named-checkconf /etc/bind/named.conf
named -u bind
sleep 2

echo; echo "=== DNS-01 ns1 (A) ===";        dig @127.0.0.1 ns1.agencia.redes.test A +noall +answer +comments | grep -E "flags|IN"
echo; echo "=== DNS-02 ldap/www/mail/ftp (A) ==="
for h in ldap www mail ftp; do dig @127.0.0.1 $h.agencia.redes.test A +short | sed "s/^/$h -> /"; done
echo; echo "=== DNS-03 SOA (flag aa) ===";    dig @127.0.0.1 agencia.redes.test SOA | grep -E "flags|SOA"
echo; echo "=== NS ===";                      dig @127.0.0.1 agencia.redes.test NS +noall +answer
echo; echo "=== DNS-04 MX ===";               dig @127.0.0.1 agencia.redes.test MX +noall +answer
echo; echo "=== DNS-05 inexistente (NXDOMAIN) ==="; dig @127.0.0.1 noexiste.agencia.redes.test A | grep -E "status|flags"
' 2>&1 | tee "$OUT"

echo; echo "Salida guardada en: $OUT"
