# Tabla de resolución de nombres DNS (Entregable b)

Zona **agencia.redes.test** · Servidor autoritativo: `ns1.agencia.redes.test`

> ⚠️ IPs fijas propuestas en la red 192.168.68.0/22 (Bridged, gateway 192.168.68.1). Se usa el bloque 192.168.71.x para no chocar con el DHCP del router (que repartio 192.168.68.50). Confirmar con el equipo.

| FQDN | Tipo | Valor | Servicio | Responsable |
|---|---|---|---|---|
| `agencia.redes.test.` | SOA | `ns1.agencia.redes.test. admin.agencia.redes.test.` serial `2026100402` | Zona | Marines |
| `agencia.redes.test.` | NS | `ns1.agencia.redes.test.` | DNS | Marines |
| `agencia.redes.test.` | MX | `10 mail.agencia.redes.test.` | Correo | Kevin |
| `ns1.agencia.redes.test.` | A | 192.168.71.10 | BIND9 | Marines |
| `ldap.agencia.redes.test.` | A | 192.168.71.11 | OpenLDAP (`dc=agencia,dc=redes,dc=test`) | Cisco |
| `www.agencia.redes.test.` | A | 192.168.71.12 | Apache | Carlitos |
| `mail.agencia.redes.test.` | A | 192.168.71.13 | Postfix + Dovecot | Kevin |
| `ftp.agencia.redes.test.` | A | 192.168.71.14 | vsftpd | Cami |
