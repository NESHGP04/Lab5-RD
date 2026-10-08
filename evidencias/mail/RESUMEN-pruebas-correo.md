# Resumen de pruebas: servicio de correo (Kevin Villagran)

Dominio `agencia.redes.test` · servidor `mail.agencia.redes.test` (192.168.71.13) · Postfix + Dovecot 2.3.21 con autenticación OpenLDAP (192.168.71.11) · Thunderbird.
Pruebas hechas el 7 y 8 de octubre de 2026 en la red del grupo (192.168.68.0/22). Fuente de los logs: `mail-log-final.txt`.

## Arquitectura (para la sección de configuraciones)
- **Postfix**: recibe y envía por SMTP (puerto 25). Autentica con SASL a través de Dovecot (`smtpd_sasl_type = dovecot`). Valida los destinatarios con `local_recipient_maps` (usuarios locales + atributo `mail` de LDAP) y entrega todo por LMTP a Dovecot (`mailbox_transport = lmtp:unix:private/dovecot-lmtp`).
- **Dovecot**: IMAP (puerto 143). `passdb` LDAP con `auth_bind` (DN `uid=%n,ou=People,dc=agencia,dc=redes,dc=test`) y `passdb` PAM de respaldo para `ana` y `kevin`. Usuarios LDAP como usuarios virtuales (`vmail`, uid/gid 5000) con buzón `maildir:~/Maildir` en `/var/mail/vhosts/<usuario>`. `auth_username_format = %Ln` (el usuario va sin dominio).
- **Thunderbird**: IMAP/SMTP contra `mail.agencia.redes.test`, puertos 143 y 25, sin TLS (laboratorio), contraseña normal.
- Archivos: `postfix-final.txt` (`postconf -n`), `dovecot-final.txt` (`doveconf -n`), `ldap-configs.txt`.

## Matriz de pruebas

| ID | Prueba | Resultado | Evidencia | Estado |
|---|---|---|---|---|
| MAIL-01 | Resolver `mail` y consultar MX | `mail.agencia.redes.test` → 192.168.71.13; MX `10 mail.agencia.redes.test.` con A en la sección adicional | Captura de `dig` (A y MX) y de `Test-NetConnection` por FQDN | Hecha. **Recomendado**: repetir `dig @192.168.71.10 ...` para que la captura muestre el servidor DNS del grupo |
| MAIL-02 | Configurar Thunderbird con el nombre DNS | Cuentas `ana` y `kevin.villagran` con IMAP/SMTP `mail.agencia.redes.test`, puertos 143/25, conectan | Captura de configuración IMAP y SMTP | Hecha |
| MAIL-03 | Autenticación válida con LDAP | `imap-login: Login: user=<kevin.villagran>` y `user=<ernesto.ascencio>` (método PLAIN, desde 192.168.68.x). `doveadm auth test` → `auth succeeded` | Bandeja de `kevin.villagran` en Thunderbird + log de Dovecot | Hecha |
| MAIL-04 | Autenticación inválida | `imap-login: Disconnected: ... (auth failed, N attempts ...): user=<kevin.villagran>`; por IMAP directo `a1 NO [AUTHENTICATIONFAILED] Authentication failed.`; `doveadm auth test` → `auth failed` | Log de Dovecot + captura del `nc` + error en Thunderbird | Hecha |
| MAIL-05 | Envío interno | `sasl_username=kevin.villagran`; `from=<kevin.villagran@...>` → `to=<ana@...>`; `relay=mail.agencia.redes.test[private/dovecot-lmtp]`; `status=sent (250 2.0.0 ... Saved)`. También `sasl_username=ernesto.ascencio` → `kevin.villagran` | Mensaje en Enviados + log de Postfix | Hecha |
| MAIL-06 | Recepción por IMAP | Mensajes de Ernesto y de `ana` en la bandeja de `kevin.villagran`; mensaje de `kevin.villagran` en la bandeja de `ana`. Dovecot: `lmtp(...): saved mail to INBOX` | Captura de las bandejas | Hecha |
| MAIL-07 | Destinatario inexistente | `550 5.1.1 <noexiste@agencia.redes.test>: Recipient address rejected: User unknown in local recipient table` | Salida del `nc` + línea `NOQUEUE: reject` del log | Hecha |
| INT-01 | Solo FQDN | Correo accedido solo por `mail.agencia.redes.test`; DNS por `ldap.agencia.redes.test` | Capturas de Thunderbird y `dig` | Mi parte hecha. Falta Web y FTP (de los otros) |
| INT-02 | Reinicio de servicios | Tras `sudo reboot` (boot 00:17:53 UTC del 8 de octubre): `systemctl is-active postfix dovecot` → `active`/`active`; `doveadm auth test kevin.villagran` → `auth succeeded` (LDAP); logins IMAP de `ana` y `ernesto.ascencio` después del arranque | Capturas de `is-active` y `auth test`, `evidencia-mail-20261008-002153.txt`, journal con `-- Boot 5cd23...` | Hecha |
| INT-03 | `ss -lntup` | Postfix en 0.0.0.0:25 (`master`); Dovecot en 0.0.0.0:143 y :993, y [::]:143 y :993 (`imap-login`) | `puertos.txt` | Hecha |
| INT-04 | Revisión de logs | Conexiones SMTP, autenticaciones SASL, logins IMAP, rechazos, fallos de auth y entrega LMTP | `mail-log-final.txt` | Hecha |

## Pendientes de mi parte
1. Traer los `evidencia-mail-*.txt` a la carpeta Lab5 (`scp "kevin@192.168.71.13:~/evidencia-*.txt" .`) y revisar que no tengan claves personales. Mandar los dos (antes y después del reinicio) a Ernesto.
2. Capturas de `dig @192.168.71.10 mail.agencia.redes.test` y `dig @192.168.71.10 MX agencia.redes.test` (con el nombre; sin nombre consulta los servidores raíz).
3. Capturas del `journalctl -u postfix -u dovecot -n 80 --no-pager` tras las pruebas MAIL-03..07 (lo pide Ernesto), con hora visible.
4. Devolver el DNS de Windows a automático al terminar:
   `Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ResetServerAddresses`

## Notas para el PDF
- Los puertos son 25 y 143 sin TLS a propósito (laboratorio). El `ss` muestra también el 993 que Dovecot abre por defecto.
- Las contraseñas de LDAP son de laboratorio y no aparecen en ninguno de los archivos de configuración ni en el log.
- Cada integrante del grupo tiene dirección de correo porque los 6 usuarios de `ou=People` tienen atributo `mail` y buzón virtual.
- En el log, dos fallos de auth (`ana` a las 00:01:48 y `ernesto.ascencio` a las 23:40:01) son de pruebas de otros; el de `kevin.villagran` (00:04:33 y 00:05:47) es el de MAIL-04 con LDAP.
