# Matriz de pruebas internas (Ejercicio 6 – Ernesto)

Cliente de pruebas: **Mac de Ernesto**, DNS del Wi-Fi = `192.168.71.10`, `/etc/hosts` sin entradas de `agencia.redes.test`.
Estado: ⬜ pendiente · ✅ pasó (con evidencia) · ❌ falló
Corrida 2026-10-07 17:39: **28 PASS, 0 FAIL** (`FTP_DIR=files/ SMTP_PORT=25 ./scripts/test-matriz.sh`). Mail: SMTP en puerto 25 (587 cerrado). FTP: usuario local `ftpuser1`, pasivo 40000–40010.

```bash
networksetup -setdnsservers Wi-Fi 192.168.71.10      # al terminar: ... Wi-Fi Empty
LDAP_USER=... LDAP_PASS=... MAIL_USER1=... MAIL_PASS1=... MAIL_USER2=... MAIL_PASS2=... \
FTP_USER=... FTP_PASS=... ./scripts/test-matriz.sh   # guarda en evidencias/matriz/
```
Las claves se pasan por variable de entorno; no se suben al repo. Lo marcado **manual** no lo cubre el script.

| ID | Prueba | Procedimiento (comando) | Resultado esperado | Resultado obtenido | Evidencia | Estado |
|---|---|---|---|---|---|---|
| DNS-01 | Resolución de ns1 | `dig ns1.agencia.redes.test` | 192.168.71.10 | 192.168.71.10, NOERROR, `aa` | `evidencias/dns/pruebas-dns-20261005-010740.txt` | ✅ |
| DNS-02 | Resolución de servicios | `dig {ldap,www,mail,ftp}.agencia.redes.test` | .11 .12 .13 .14 | .11 .12 .13 .14 | ídem, Fig. 3 | ✅ |
| DNS-03 | SOA autoritativo | `dig agencia.redes.test SOA` | flag `aa`, serial | serial 2026100402, `aa` | Fig. 4 | ✅ |
| DNS-04 | MX | `dig agencia.redes.test MX` | `mail.agencia.redes.test` | `10 mail.agencia.redes.test.` | Fig. 2 | ✅ |
| DNS-05 | Nombre inexistente | `dig noexiste.agencia.redes.test` | NXDOMAIN | NXDOMAIN, `aa` | Fig. 3 | ✅ |
| LDAP-01 | Consulta de usuarios | `ldapsearch -x -H ldap://ldap.agencia.redes.test -D uid=U,ou=People,dc=agencia,dc=redes,dc=test -W -b ou=People,dc=agencia,dc=redes,dc=test` | 6 usuarios | 6 usuarios | `evidencias/matriz/matriz-20261007-173955.txt` | ✅ |
| LDAP-02 | Bind válido | `ldapwhoami -x -H ldap://ldap.… -D <DN> -W` | `dn:<DN>` | bind aceptado | `evidencias/matriz/matriz-20261007-173955.txt` | ✅ |
| LDAP-03 | Bind inválido | mismo con clave errónea | `Invalid credentials (49)` | `Invalid credentials (49)` | `evidencias/matriz/matriz-20261007-173955.txt` | ✅ |
| LDAP-04 | Atributos | `ldapsearch … -b <DN> -s base uid cn sn mail` | 4 atributos, mail `@agencia.redes.test` | uid, cn, sn, mail `@agencia.redes.test` | `evidencias/matriz/matriz-20261007-173955.txt` | ✅ |
| WEB-01 | Resolución www | `dig www.agencia.redes.test +short` | 192.168.71.12 | .12 | `pruebas-dns-…010740.txt` | ✅ |
| WEB-02 | Página principal | navegador → `http://www.agencia.redes.test` (**manual** captura; script: HTTP 200) | carga | HTTP 200 | `evidencias/matriz/web-02.png` + `evidencias/matriz/matriz-20261007-173955.txt` + `evidencias/web/web-02.txt` | ✅ |
| WEB-03 | Login LDAP válido | navegador, área protegida, usuario válido (**manual** captura) | acceso | HTTP 200 con LDAP válido | `web-03.png` + `evidencias/matriz/matriz-20261007-173955.txt` + `evidencias/web/web-03.txt` | ✅ |
| WEB-04 | Login inválido | clave errónea y usuario inexistente | 401 / rechazo | 401 en script; `error.log`: `Password Mismatch` y `user noexiste not found` | `evidencias/web/web-04-error-log-password-mismatch.jpeg`, `evidencias/matriz/matriz-20261007-183236.txt` | ✅ |
| WEB-05 | Dependencia de LDAP | **manual**: en ldap `sudo systemctl stop slapd`, intentar login, en www `sudo tail /var/log/apache2/error.log`; luego `start slapd` | no autentica, error en log | `error.log`: `ldap_simple_bind() failed [Can't contact LDAP server]` | `evidencias/web/web-05-error-log-ldap-caido.jpeg` | ✅ |
| MAIL-01 | Resolución mail + MX | `dig mail.agencia.redes.test +short; dig agencia.redes.test MX +short` | .13 y `10 mail…` | .13 y `10 mail.agencia.redes.test.` | `pruebas-dns-…010740.txt`, Fig. 2 | ✅ |
| MAIL-02 | Config. Thunderbird | **manual**: cuenta con `mail.agencia.redes.test` (SMTP+IMAP) | acepta | | `mail-02.png` + `evidencias/mail/mail-02.txt` | ✅ |
| MAIL-03 | Auth válida | Thunderbird + `journalctl -u dovecot` en mail | login OK | IMAP login OK (143) | `mail-03.png` + log + `evidencias/matriz/matriz-20261007-173955.txt` + `evidencias/mail/mail-03.txt` | ✅ |
| MAIL-04 | Auth inválida | clave errónea + log Dovecot | rechazo | `Login denied` | `mail-04.png` + log + `evidencias/matriz/matriz-20261007-173955.txt` + `evidencias/mail/mail-04.txt` | ✅ |
| MAIL-05 | Envío interno | Thunderbird usuario1 → usuario2 + `journalctl -u postfix` | `status=sent` | SMTP (25) aceptó, ernesto→kevin | enviado + log + `evidencias/matriz/matriz-20261007-173955.txt` + `evidencias/mail/mail-05.txt` | ✅ |
| MAIL-06 | Recepción IMAP | Thunderbird usuario2, INBOX | mensaje aparece | mensaje en INBOX de kevin.villagran | `mail-06.png` + `evidencias/matriz/matriz-20261007-173955.txt` + `evidencias/mail/mail-06.txt` | ✅ |
| MAIL-07 | Destinatario inexistente | enviar a `noexiste@agencia.redes.test` + log Postfix | `550` / bounce | `RCPT failed: 550` | captura + log + `evidencias/matriz/matriz-20261007-173955.txt` | ✅ |
| FTP-01 | Resolución ftp | `dig ftp.agencia.redes.test +short` | 192.168.71.14 | .14 | `pruebas-dns-…010740.txt` | ✅ |
| FTP-02 | Auth válida | `ftp ftp.agencia.redes.test` (usuario autorizado) | `230` | login OK (`ftpuser1`) | captura + `evidencias/matriz/matriz-20261007-173955.txt` | ✅ |
| FTP-03 | Auth inválida | clave errónea | `530` | `530` | captura + `evidencias/matriz/matriz-20261007-173955.txt` | ✅ |
| FTP-04 | Anónimo | `anonymous` | `530` | `530` | captura + `evidencias/matriz/matriz-20261007-173955.txt` | ✅ |
| FTP-05 | Listado | `ls` | contenido autorizado | lista `files` | captura + `evidencias/matriz/matriz-20261007-173955.txt` | ✅ |
| FTP-06 | Carga | `put prueba.txt`; en el servidor `ls -l` del directorio | archivo existe | carga OK en `files/` | captura + ls + `evidencias/matriz/matriz-20261007-173955.txt` | ✅ |
| FTP-07 | Descarga | `get prueba.txt`; `shasum` igual al original | idéntico | `shasum` idéntico | captura + shasum + `evidencias/matriz/matriz-20261007-173955.txt` | ✅ |
| FTP-08 | Restricción | `cd /etc`, `cd ../..` | `550`, sigue enjaulado | `denied to change directory` | captura + `evidencias/matriz/matriz-20261007-173955.txt` | ✅ |
| INT-01 | Solo FQDN | `cat /etc/hosts`, `scutil --dns`, pruebas sin IP | todo funciona | Todo por FQDN; `/etc/hosts` sin entradas; DNS del Mac = 192.168.71.10 | `evidencias/matriz/matriz-20261007-173955.txt`, `evidencias/dns/int01-desde-mac.txt` | ✅ |
| INT-02 | Reinicio | **manual** en cada VM: `sudo reboot`; `systemctl status <svc>`; repetir pruebas | persiste | 5 servicios `active` tras reinicio; matriz repetida: 28 PASS | `evidencias/{ldap,web,mail,ftp}/`, `evidencias/dns/INT-02.png`, `evidencias/matriz/matriz-20261007-183236.txt` | ✅ |
| INT-03 | Puertos | **manual** en cada VM: `sudo ss -lntup` | 53, 389, 80, 25/587, 143, 21 + rango pasivo | 53, 389, 80, 25/143/993, 21 escuchando; pasivo 40000–40010 (`pasv_*` en `evidencias/ftp/`) | `ss -lntup` en cada carpeta; `evidencias/resumen-por-prueba.txt` | ✅ |
| INT-04 | Logs | **manual**: extractos tras las pruebas | conexiones/auth/errores | logs con conexiones, auth OK/fallida y errores en los 5 servicios | sección INT-04 de cada `evidencia-*.txt`; `evidencias/ftp/` línea `=== LOG: INT-04 ===` | ✅ |

## Comandos de logs por servidor (para INT-04 y las filas con log)
| VM | Comando |
|---|---|
| ldap | `sudo journalctl -u slapd -n 50 --no-pager` |
| www | `sudo tail -n 30 /var/log/apache2/access.log /var/log/apache2/error.log` |
| mail | `sudo journalctl -u postfix -u dovecot -n 80 --no-pager` (o `/var/log/mail.log`) |
| ftp | `sudo tail -n 30 /var/log/vsftpd.log` (requiere `xferlog_enable=YES`/`log_ftp_protocol=YES` para ver comandos) |

## Lo que cada responsable debe mandarle a Ernesto
- Cisco: URL `ldap://ldap.agencia.redes.test`, forma del DN (`uid=<u>,ou=People,…`), un usuario y clave de prueba (solo lab).
- Carlitos: ruta de la sección protegida.
- Kevin: dos buzones de prueba, puertos SMTP/IMAP y si usa STARTTLS/TLS.
- Cami: usuario FTP, directorio autorizado, rango pasivo y si usa TLS.


Resumen literal por prueba: `evidencias/resumen-por-prueba.txt`. Corrida post-reinicio: `evidencias/matriz/matriz-20261007-183236.txt` (28 PASS).
