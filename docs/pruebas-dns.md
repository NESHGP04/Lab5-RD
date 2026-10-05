# Pruebas relacionadas con DNS (Ejercicio 6 – parte de Marines)

Estado: ⬜ pendiente de ejecutar en la VM real · 🟨 validado solo en Docker · ✅ evidencia real en `evidencias/dns/`

Todas se ejecutan con `./scripts/test-dns.sh <IP_ns1>` (guarda salida con fecha en `evidencias/dns/`)
y la **captura de pantalla** se toma de esa misma ejecución.

| ID | Prueba | Comando | Resultado esperado | Estado |
|---|---|---|---|---|
| DNS-01 | Resolución de ns1 | `dig @IP ns1.agencia.redes.test A` | `192.168.71.10` (ajustar a IP final) | ✅ |
| DNS-02 | Resolución de ldap, www, mail, ftp | `dig @IP <host>.agencia.redes.test A` | Cada nombre → su IP | ✅ |
| DNS-03 | SOA autoritativo | `dig @IP agencia.redes.test SOA` | Flag **`aa`**, serial correcto | ✅ |
| DNS-04 | MX | `dig @IP agencia.redes.test MX` | `10 mail.agencia.redes.test.` | ✅ |
| DNS-05 | Nombre inexistente | `dig @IP noexiste.agencia.redes.test` | `status: NXDOMAIN` | ✅ |
| WEB-01 | Resolver www | `nslookup www.agencia.redes.test` | IP del Apache | ✅ |
| MAIL-01 | Resolver mail + MX | `nslookup mail…` y `dig … MX` | IP del correo + MX | ✅ |
| FTP-01 | Resolver ftp | `nslookup ftp.agencia.redes.test` | IP del vsftpd | ✅ |
| INT-01 | Uso exclusivo de FQDN | Cliente con DNS=ns1, **sin `/etc/hosts`**, `dig +short` sin `@` | Resuelve todo | ✅ |
| INT-02 | Reinicio de servicios | `sudo reboot` → `systemctl status named` → repetir pruebas | Persiste y responde | ✅ |
| INT-03 | Puertos | `sudo ss -lntup \| grep ':53'` | `named` en 53 TCP/UDP | ✅ |
| INT-04 | Logs | `sudo journalctl -u named -n 50` | Consultas/arranque registrados | ✅ |

## Resultados de la ejecución en la VM real (2026-10-05 01:07 UTC = 2026-10-04 19:07 GT)
Ejecutado en `ns1` (192.168.71.10) con `./scripts/test-dns.sh 192.168.71.10`; archivo `evidencias/dns/pruebas-dns-20261005-010740.txt`.

- DNS-01: `ns1` → 192.168.71.10 (NOERROR, `aa`).
- DNS-02: `ldap` → .11, `www` → .12, `mail` → .13, `ftp` → .14 (todos NOERROR, `aa`).
- DNS-03: SOA `ns1.agencia.redes.test. admin.agencia.redes.test. 2026100402 …` con flag `aa`.
- DNS-04: MX `10 mail.agencia.redes.test.` (+ A de mail en la sección ADDITIONAL).
- DNS-05: `noexiste.agencia.redes.test` → `NXDOMAIN` con `aa` y SOA en AUTHORITY.
- WEB-01 / MAIL-01 / FTP-01: `nslookup` devuelve .12 / .13 / .14.
- INT-01: ver sección siguiente (✅ desde un cliente).

### INT-01 – Desde un cliente (Mac de Marines, 2026-10-04 19:25 CST)
Con el DNS del Wi-Fi fijado en `192.168.71.10` (`scutil --dns` → `nameserver[0] : 192.168.71.10`) y `/etc/hosts` con solo las entradas
por defecto, **sin usar `@`**: `ns1`→.10, `ldap`→.11, `www`→.12, `mail`→.13, `ftp`→.14, MX `10 mail.agencia.redes.test.` y `NXDOMAIN` para un
nombre inexistente. Evidencia: `evidencias/dns/int01-desde-mac.txt`. Pendiente solo repetirlo desde la VM de un compañero si se quiere reforzar.

### INT-02 – Reinicio de la VM (2026-10-05 01:14 UTC)
Tras `sudo reboot`: `named.service` quedó `enabled` y `active (running)` desde 01:14:43 sin intervención manual, la IP fija
`192.168.71.10` persistió, y `dig @192.168.71.10 agencia.redes.test SOA` respondió con flag `aa` y serial 2026100402 (captura de pantalla).

### INT-03 – Puertos (2026-10-05, tras el reinicio)
`sudo ss -lntup | grep ':53'`: `named` (pid 609) escucha en UDP y TCP 53 solo en `127.0.0.1` y `192.168.71.10`,
sin direcciones IPv6 (coincide con `listen-on-v6 { none; }`). `systemd-resolved` ocupa `127.0.0.53` y `127.0.0.54`, sin conflicto.

### INT-04 – Logs (2026-10-05)
`journalctl -u named` muestra el arranque, `command channel listening`, `zone agencia.redes.test/IN: loaded serial 2026100402`,
`all zones loaded` y `running`. Aparecen avisos `network unreachable resolving './NS/IN': 2001:...` (BIND intenta los root
servers por IPv6 y la VM no tiene IPv6): son inofensivos; se silencian arrancando `named` con `-4` (`OPTIONS="-u bind -4"` en `/etc/default/named`).
Con `sudo rndc querylog on` y dos `dig` (01:21 UTC) el log registró:
`query: www.agencia.redes.test IN A` y `query: noexiste.agencia.redes.test IN A` (cliente 192.168.71.10), más el aviso
`query logging is now on`. Nota: `querylog` por `rndc` es temporal; se pierde al reiniciar `named` (para dejarlo fijo: `querylog yes;` en `options`).

Nota: DNS-01..05 y WEB/MAIL/FTP-01 salieron desde la propia ns1; INT-01 cubre la resolución desde un cliente distinto (Mac).

## Evidencias adicionales que pide el Ejercicio 1
- `named-checkzone` sin errores (captura).
- Consultas A, NS y MX con `dig`/`nslookup` (captura).
- Respuesta autoritativa (flag `aa`) y serial válido en el SOA.
- Constancia de que **no** se usa `/etc/hosts` (`cat /etc/hosts` en el cliente).
