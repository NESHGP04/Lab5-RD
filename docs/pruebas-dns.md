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
| INT-01 | Uso exclusivo de FQDN | Cliente con DNS=ns1, **sin `/etc/hosts`**, `dig +short` sin `@` | Resuelve todo | 🟨 |
| INT-02 | Reinicio de servicios | `sudo reboot` → `systemctl status named` → repetir pruebas | Persiste y responde | ⬜ |
| INT-03 | Puertos | `sudo ss -lntup \| grep ':53'` | `named` en 53 TCP/UDP | ⬜ |
| INT-04 | Logs | `sudo journalctl -u named -n 50` | Consultas/arranque registrados | ⬜ |

## Resultados de la ejecución en la VM real (2026-10-05 01:07 UTC = 2026-10-04 19:07 GT)
Ejecutado en `ns1` (192.168.71.10) con `./scripts/test-dns.sh 192.168.71.10`; archivo `evidencias/dns/pruebas-dns-20261005-010740.txt`.

- DNS-01: `ns1` → 192.168.71.10 (NOERROR, `aa`).
- DNS-02: `ldap` → .11, `www` → .12, `mail` → .13, `ftp` → .14 (todos NOERROR, `aa`).
- DNS-03: SOA `ns1.agencia.redes.test. admin.agencia.redes.test. 2026100402 …` con flag `aa`.
- DNS-04: MX `10 mail.agencia.redes.test.` (+ A de mail en la sección ADDITIONAL).
- DNS-05: `noexiste.agencia.redes.test` → `NXDOMAIN` con `aa` y SOA en AUTHORITY.
- WEB-01 / MAIL-01 / FTP-01: `nslookup` devuelve .12 / .13 / .14.
- INT-01 (parcial 🟨): la VM ns1 resuelve los 5 FQDN con su resolver por defecto. **Falta repetirlo desde un cliente distinto**, sin `/etc/hosts`.

Limitación: estas pruebas salieron desde la propia ns1; para la entrega conviene repetir DNS-01/02/04 y WEB/MAIL/FTP-01 desde otra máquina (tu Mac o la VM de un compañero) con DNS = 192.168.71.10.

## Evidencias adicionales que pide el Ejercicio 1
- `named-checkzone` sin errores (captura).
- Consultas A, NS y MX con `dig`/`nslookup` (captura).
- Respuesta autoritativa (flag `aa`) y serial válido en el SOA.
- Constancia de que **no** se usa `/etc/hosts` (`cat /etc/hosts` en el cliente).
