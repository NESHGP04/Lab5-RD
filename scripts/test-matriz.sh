#!/usr/bin/env bash
# Matriz de pruebas (Ejercicio 6) ejecutable desde el cliente (Mac con DNS = ns1).
# Solo usa dig, ldapsearch y curl (vienen con macOS). Imprime ID: PASS/FAIL/SKIP
# y guarda todo en evidencias/matriz/matriz-<fecha>.txt.
#
# Las credenciales NUNCA van en el repo: se pasan por variables de entorno.
#   LDAP_USER LDAP_PASS            usuario LDAP valido (uid) y su clave   -> LDAP-*, WEB-03
#   WEB_PATH                       ruta protegida (default /protegido/)    -> WEB-*
#   MAIL_USER1 MAIL_PASS1          remitente  (uid LDAP)                   -> MAIL-*
#   MAIL_USER2 MAIL_PASS2          destinatario (uid LDAP)
#   MAIL_CURL_OPTS                 extra de curl p/ SMTP+IMAP (ej. "--ssl -k" si hay STARTTLS)
#   SMTP_PORT (587) IMAP_PORT (143)
#   FTP_USER FTP_PASS              usuario FTP autorizado                  -> FTP-*
#   FTP_CURL_OPTS                  extra de curl p/ FTP (ej. "--ssl -k")
#   FTP_DIR                        subdirectorio escribible (ej. files/)    -> FTP-06/07
#
# Uso: LDAP_USER=ana LDAP_PASS=xxx ... ./scripts/test-matriz.sh
set -uo pipefail

Z="agencia.redes.test"
BASE="dc=agencia,dc=redes,dc=test"
NS="${NS:-192.168.71.10}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/evidencias/matriz/matriz-$(date +%Y%m%d-%H%M%S).txt"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$(dirname "$OUT")"
P=0; F=0; S=0

pass() { echo "$1: PASS - $2"; P=$((P+1)); }
fail() { echo "$1: FAIL - $2"; F=$((F+1)); }
skip() { echo "$1: SKIP - falta $2"; S=$((S+1)); }
# need ID VAR...  -> 0 si todas las variables existen; si no, SKIP
need() { local id=$1 v; shift; for v in "$@"; do [ -n "${!v:-}" ] || { skip "$id" "$v"; return 1; }; done; }

run() {
echo "Matriz de pruebas | $(date) | Host: $(hostname) | DNS: $NS"

echo; echo "##### DNS (detalle completo: scripts/test-dns.sh) #####"
# DNS-01..05, WEB-01, MAIL-01, FTP-01: por nombre, sin @servidor (INT-01)
[ "$(dig +short ns1.$Z)" = "192.168.71.10" ] && pass DNS-01 "ns1 -> 192.168.71.10" || fail DNS-01 "ns1"
ok=1; for p in ldap:11 www:12 mail:13 ftp:14; do
  [ "$(dig +short ${p%%:*}.$Z)" = "192.168.71.${p##*:}" ] || ok=0; done
[ $ok = 1 ] && pass DNS-02 "ldap .11, www .12, mail .13, ftp .14" || fail DNS-02 "alguna IP no coincide"
dig $Z SOA | grep -q "flags:.* aa" && pass DNS-03 "SOA con flag aa" || fail DNS-03 "sin aa"
[ "$(dig +short $Z MX)" = "10 mail.$Z." ] && pass DNS-04 "MX 10 mail.$Z." || fail DNS-04 "MX"
dig noexiste.$Z A | grep -q "status: NXDOMAIN" && pass DNS-05 "NXDOMAIN" || fail DNS-05 "no NXDOMAIN"
[ "$(dig +short www.$Z)" = "192.168.71.12" ] && pass WEB-01 "www -> .12" || fail WEB-01 "www"
[ "$(dig +short mail.$Z)" = "192.168.71.13" ] && pass MAIL-01 "mail -> .13 + MX" || fail MAIL-01 "mail"
[ "$(dig +short ftp.$Z)" = "192.168.71.14" ] && pass FTP-01 "ftp -> .14" || fail FTP-01 "ftp"

echo; echo "##### LDAP #####"
LDAPURI="ldap://ldap.$Z"
if need LDAP-01 LDAP_USER LDAP_PASS; then
  DN="uid=$LDAP_USER,ou=People,$BASE"
  ldapsearch -x -LLL -H $LDAPURI -D "$DN" -w "$LDAP_PASS" -b "ou=People,$BASE" "(objectClass=*)" dn uid >"$TMP/l1" 2>&1
  cat "$TMP/l1"
  n=$(grep -c '^uid:' "$TMP/l1"); [ "$n" -ge 1 ] && pass LDAP-01 "$n usuarios (comparar con #integrantes = 6)" || fail LDAP-01 "sin usuarios"
  ldapwhoami -x -H $LDAPURI -D "$DN" -w "$LDAP_PASS" 2>&1 | tee "$TMP/l2"
  grep -q "dn:$DN" "$TMP/l2" && pass LDAP-02 "bind valido aceptado" || fail LDAP-02 "bind valido rechazado"
  ldapwhoami -x -H $LDAPURI -D "$DN" -w "clave-incorrecta-$$" 2>&1 | tee "$TMP/l3"
  grep -q "Invalid credentials" "$TMP/l3" && pass LDAP-03 "Invalid credentials (49)" || fail LDAP-03 "no rechazo"
  ldapsearch -x -LLL -H $LDAPURI -D "$DN" -w "$LDAP_PASS" -b "$DN" -s base uid cn sn mail | tee "$TMP/l4"
  ok=1; for a in uid cn sn mail; do grep -q "^$a:" "$TMP/l4" || ok=0; done
  grep -q "^mail:.*@$Z" "$TMP/l4" || ok=0
  [ $ok = 1 ] && pass LDAP-04 "uid, cn, sn, mail (@$Z)" || fail LDAP-04 "atributo faltante"
else for i in 02 03 04; do skip LDAP-$i LDAP_USER/LDAP_PASS; done; fi

echo; echo "##### WEB #####"
WP="${WEB_PATH:-/protegido/}"
c=$(curl -s -o /dev/null -w '%{http_code}' http://www.$Z/); echo "GET / -> $c"
[ "$c" = 200 ] && pass WEB-02 "pagina principal 200" || fail WEB-02 "HTTP $c"
if need WEB-03 LDAP_USER LDAP_PASS; then
  c=$(curl -s -o /dev/null -w '%{http_code}' -u "$LDAP_USER:$LDAP_PASS" "http://www.$Z$WP"); echo "GET $WP (valido) -> $c"
  [ "$c" = 200 ] && pass WEB-03 "acceso 200" || fail WEB-03 "HTTP $c"
  c=$(curl -s -o /dev/null -w '%{http_code}' -u "$LDAP_USER:clave-incorrecta-$$" "http://www.$Z$WP"); echo "GET $WP (clave mala) -> $c"
  c2=$(curl -s -o /dev/null -w '%{http_code}' -u "noexiste:x" "http://www.$Z$WP"); echo "GET $WP (usuario inexistente) -> $c2"
  [ "$c" = 401 ] && [ "$c2" = 401 ] && pass WEB-04 "401 en ambos" || fail WEB-04 "HTTP $c / $c2"
else skip WEB-04 LDAP_USER/LDAP_PASS; fi
echo "WEB-05: manual (parar slapd en ldap, intentar login, capturar error.log de Apache)"

echo; echo "##### CORREO #####"
SP="${SMTP_PORT:-587}"; IP="${IMAP_PORT:-143}"; MO="${MAIL_CURL_OPTS:-}"
if need MAIL-03 MAIL_USER1 MAIL_PASS1 MAIL_USER2 MAIL_PASS2; then
  # shellcheck disable=SC2086
  curl -sS $MO "imap://mail.$Z:$IP/" -u "$MAIL_USER1:$MAIL_PASS1" && pass MAIL-03 "IMAP login valido" || fail MAIL-03 "IMAP login"
  # shellcheck disable=SC2086
  curl -sS $MO "imap://mail.$Z:$IP/" -u "$MAIL_USER1:clave-incorrecta-$$" && fail MAIL-04 "acepto clave mala" || pass MAIL-04 "IMAP rechaza clave mala"
  SUBJ="Prueba MAIL-05 $(date +%H%M%S)"
  printf 'From: %s@%s\r\nTo: %s@%s\r\nSubject: %s\r\n\r\nPrueba interna de la matriz.\r\n' \
    "$MAIL_USER1" "$Z" "$MAIL_USER2" "$Z" "$SUBJ" >"$TMP/msg"
  # shellcheck disable=SC2086
  curl -sS $MO "smtp://mail.$Z:$SP" --mail-from "$MAIL_USER1@$Z" --mail-rcpt "$MAIL_USER2@$Z" \
    -T "$TMP/msg" -u "$MAIL_USER1:$MAIL_PASS1" && pass MAIL-05 "SMTP acepto: $SUBJ" || fail MAIL-05 "SMTP"
  sleep 3
  # shellcheck disable=SC2086
  r=$(curl -sS $MO "imap://mail.$Z:$IP/INBOX" -u "$MAIL_USER2:$MAIL_PASS2" -X "SEARCH SUBJECT \"$SUBJ\"" 2>&1); echo "$r"
  echo "$r" | grep -Eq 'SEARCH +[0-9]+' && pass MAIL-06 "mensaje en INBOX de $MAIL_USER2" || fail MAIL-06 "no aparece"
  # shellcheck disable=SC2086
  r=$(curl -sS $MO "smtp://mail.$Z:$SP" --mail-from "$MAIL_USER1@$Z" --mail-rcpt "noexiste@$Z" \
    -T "$TMP/msg" -u "$MAIL_USER1:$MAIL_PASS1" 2>&1); echo "$r"
  echo "$r" | grep -Eq '55[0-9]|RCPT' && pass MAIL-07 "destinatario inexistente rechazado" || fail MAIL-07 "no rechazo"
  echo "MAIL-02: manual (captura de Thunderbird)"
else for i in 04 05 06 07; do skip MAIL-$i MAIL_USER1/2 MAIL_PASS1/2; done; fi

echo; echo "##### FTP #####"
FO="${FTP_CURL_OPTS:-}"; FU="ftp://ftp.$Z"
if need FTP-02 FTP_USER FTP_PASS; then
  # shellcheck disable=SC2086
  curl -sS $FO "$FU/" -u "$FTP_USER:$FTP_PASS" -l | tee "$TMP/f5" && pass FTP-02 "login valido" || fail FTP-02 "login"
  # shellcheck disable=SC2086
  curl -sS $FO "$FU/" -u "$FTP_USER:clave-incorrecta-$$" && fail FTP-03 "acepto clave mala" || pass FTP-03 "rechaza clave mala"
  # shellcheck disable=SC2086
  curl -sS $FO "$FU/" -u "anonymous:a@b.c" && fail FTP-04 "acepto anonimo" || pass FTP-04 "rechaza anonimo"
  # shellcheck disable=SC2086
  curl -sS $FO "$FU/" -u "$FTP_USER:$FTP_PASS" && pass FTP-05 "listado OK" || fail FTP-05 "listado"
  echo "contenido de prueba $(date)" >"$TMP/up.txt"
  # shellcheck disable=SC2086
  curl -sS $FO -T "$TMP/up.txt" "$FU/${FTP_DIR:-}prueba-matriz.txt" -u "$FTP_USER:$FTP_PASS" && pass FTP-06 "carga OK" || fail FTP-06 "carga"
  # shellcheck disable=SC2086
  curl -sS $FO "$FU/${FTP_DIR:-}prueba-matriz.txt" -u "$FTP_USER:$FTP_PASS" -o "$TMP/down.txt" \
    && [ "$(shasum "$TMP/up.txt" | cut -d' ' -f1)" = "$(shasum "$TMP/down.txt" | cut -d' ' -f1)" ] \
    && pass FTP-07 "descarga identica (shasum)" || fail FTP-07 "descarga"
  # '//etc/' = ruta absoluta; con chroot no debe salir el /etc real del servidor
  # shellcheck disable=SC2086
  r=$(curl -sS $FO "$FU//etc/" -u "$FTP_USER:$FTP_PASS" -l 2>&1); echo "$r"
  echo "$r" | grep -qw passwd && fail FTP-08 "ve /etc/passwd" || pass FTP-08 "no sale del directorio autorizado"
else for i in 03 04 05 06 07 08; do skip FTP-$i FTP_USER/FTP_PASS; done; fi

echo; echo "##### INT-01 (solo FQDN, sin /etc/hosts) #####"
echo "--- /etc/hosts"; cat /etc/hosts
echo "--- DNS del sistema"; scutil --dns | grep nameserver | head -2
grep -q "redes.test" /etc/hosts && fail INT-01 "/etc/hosts tiene entradas del dominio" || pass INT-01 "sin entradas en /etc/hosts; todo por FQDN"
echo "INT-02/03/04: manual en cada servidor (ver docs/matriz-pruebas.md)"

echo; echo "RESUMEN: $P PASS, $F FAIL, $S SKIP"
}

run 2>&1 | tee "$OUT"
echo; echo "Evidencia guardada en: $OUT"
