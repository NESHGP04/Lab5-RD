# Pruebas relacionadas con DNS (Ejercicio 6 – parte de Marines)

Estado: ⬜ pendiente de ejecutar en la VM real · 🟨 validado solo en Docker · ✅ evidencia real en `evidencias/dns/`

Todas se ejecutan con `./scripts/test-dns.sh <IP_ns1>` (guarda salida con fecha en `evidencias/dns/`)
y la **captura de pantalla** se toma de esa misma ejecución.

| ID | Prueba | Comando | Resultado esperado | Estado |
|---|---|---|---|---|
| DNS-01 | Resolución de ns1 | `dig @IP ns1.agencia.redes.test A` | `192.168.71.10` (ajustar a IP final) | 🟨 |
| DNS-02 | Resolución de ldap, www, mail, ftp | `dig @IP <host>.agencia.redes.test A` | Cada nombre → su IP | 🟨 |
| DNS-03 | SOA autoritativo | `dig @IP agencia.redes.test SOA` | Flag **`aa`**, serial correcto | 🟨 |
| DNS-04 | MX | `dig @IP agencia.redes.test MX` | `10 mail.agencia.redes.test.` | 🟨 |
| DNS-05 | Nombre inexistente | `dig @IP noexiste.agencia.redes.test` | `status: NXDOMAIN` | 🟨 |
| WEB-01 | Resolver www | `nslookup www.agencia.redes.test` | IP del Apache | ⬜ |
| MAIL-01 | Resolver mail + MX | `nslookup mail…` y `dig … MX` | IP del correo + MX | ⬜ |
| FTP-01 | Resolver ftp | `nslookup ftp.agencia.redes.test` | IP del vsftpd | ⬜ |
| INT-01 | Uso exclusivo de FQDN | Cliente con DNS=ns1, **sin `/etc/hosts`**, `dig +short` sin `@` | Resuelve todo | ⬜ |
| INT-02 | Reinicio de servicios | `sudo reboot` → `systemctl status named` → repetir pruebas | Persiste y responde | ⬜ |
| INT-03 | Puertos | `sudo ss -lntup \| grep ':53'` | `named` en 53 TCP/UDP | ⬜ |
| INT-04 | Logs | `sudo journalctl -u named -n 50` | Consultas/arranque registrados | ⬜ |

## Evidencias adicionales que pide el Ejercicio 1
- `named-checkzone` sin errores (captura).
- Consultas A, NS y MX con `dig`/`nslookup` (captura).
- Respuesta autoritativa (flag `aa`) y serial válido en el SOA.
- Constancia de que **no** se usa `/etc/hosts` (`cat /etc/hosts` en el cliente).
