#!/usr/bin/env bash
# Corre en TU VM (ldap, www, mail o ftp) y mandale a Ernesto el .txt generado.
# Uso: sudo bash recolectar-evidencia.sh <ldap|www|mail|ftp>
# Detecta nada por magia: tu eliges el servicio. Oculta lineas con pass/pw/secret.
# Para INT-02 (reinicio): corre una vez, haz `sudo reboot`, corre otra vez, manda ambos.
set -u
S="${1:-}"; case "$S" in ldap|www|mail|ftp) ;; *) echo "Uso: sudo bash $0 <ldap|www|mail|ftp>"; exit 1;; esac
[ "$(id -u)" = 0 ] || { echo "Corre con sudo"; exit 1; }
OUT="evidencia-$S-$(date +%Y%m%d-%H%M%S).txt"
red() { sed -E 's/((pass|passwd|password|pw|secret|credentials)[^=: ]*[ ]*[=:][ ]*).*/\1<oculto>/I'; }
sec() { echo; echo "##### $* #####"; }

go() {
echo "Evidencia $S | $(date) | Host: $(hostname) | IP: $(hostname -I 2>/dev/null)"

sec "INT-03 puertos (ss -lntup)"; ss -lntup
sec "INT-02 estado tras arranque"; uptime -s; echo "uptime: $(uptime -p)"

case "$S" in
ldap)
  sec "servicio"; systemctl is-enabled slapd; systemctl status slapd --no-pager | head -8
  sec "usuarios (ldapsearch anonimo/sin claves)"
  ldapsearch -x -LLL -H ldap://localhost -b "ou=People,dc=agencia,dc=redes,dc=test" uid cn sn mail 2>&1 | head -60
  sec "INT-04 log"; journalctl -u slapd -n 50 --no-pager
  # LDIF del entregable (d): incluye hashes de userPassword, solo claves del lab
  slapcat -b "dc=agencia,dc=redes,dc=test" > "usuarios-$(date +%Y%m%d).ldif" 2>/dev/null \
    && echo "LDIF guardado: usuarios-$(date +%Y%m%d).ldif (mandalo tambien)";;
www)
  sec "servicio"; systemctl is-enabled apache2; systemctl status apache2 --no-pager | head -8
  sec "sitios y modulos"; apache2ctl -S 2>&1 | head -15; apache2ctl -M 2>/dev/null | grep -i ldap
  sec "config del sitio (sin claves)"; for f in /etc/apache2/sites-enabled/*; do echo "--- $f"; red < "$f"; done
  sec "carpeta protegida"; ls -l /var/www/html 2>&1 | head -20
  sec "INT-04 access.log"; tail -n 30 /var/log/apache2/access.log
  sec "INT-04 error.log"; tail -n 30 /var/log/apache2/error.log;;
mail)
  sec "servicios"; systemctl is-enabled postfix dovecot; systemctl status postfix dovecot --no-pager | grep -E 'Active|●'
  sec "postconf -n"; postconf -n | red
  sec "doveconf -n"; doveconf -n 2>/dev/null | red
  sec "buzones"; ls -l /var/mail/vhosts 2>&1 | head -20
  sec "INT-04 log"; journalctl -u postfix -u dovecot -n 80 --no-pager;;
ftp)
  sec "servicio"; systemctl is-enabled vsftpd; systemctl status vsftpd --no-pager | head -8
  sec "vsftpd.conf activo"; grep -vE '^#|^$' /etc/vsftpd.conf | red
  sec "firewall"; ufw status 2>&1
  sec "usuarios con home"; getent passwd | awk -F: '$3>=1000 && $3<65000 {print $1, $6}'
  sec "FTP-06 directorio autorizado (ls -l)"
  for d in $(getent passwd | awk -F: '$3>=1000 && $3<65000 {print $6}'); do echo "--- $d"; ls -lR "$d" 2>&1 | head -30; done
  sec "INT-04 log"; tail -n 40 /var/log/vsftpd.log 2>&1; journalctl -u vsftpd -n 20 --no-pager;;
esac
}

go 2>&1 | tee "$OUT"
echo; echo "Listo. Manda a Ernesto: $OUT (y el .ldif si eres Cisco)"
echo "Revisa que no tenga claves personales antes de enviarlo."
