# Pendientes por persona (pasar a cada quien)

Dominio del grupo: **agencia.redes.test** (Concesionaria de vehículos). Entrega: **8 de octubre de 2026**.

## 🔴 Para todo el equipo (hay que decidirlo YA, bloquea las IPs)
- [x] **Decidido:** cada quien tiene su VM en su Mac → UTM en modo **Bridged** (interfaz `en0`), ver `docs/guia-vm-utm.md`.
- [ ] **Elegir la red Wi-Fi común** donde se harán las pruebas/evidencias (la universidad puede aislar clientes; plan B: hotspot de celular).
- [ ] Cada quien crea su VM (Ubuntu Server 24.04, misma versión) y manda `ip -br a` y `ip route | grep default` a Marines.
- [ ] Confirmar la tabla de IPs de `docs/tabla-resolucion-dns.md` (propuestas, red 192.168.68.0/22). Bloque fijo `192.168.71.10`–`.14` para no chocar con el DHCP del router.

## Cisco (OpenLDAP)
- [ ] Base `dc=agencia,dc=redes,dc=test`, `ou=People`, un usuario por integrante con `uid, cn, sn, mail (@agencia.redes.test), userPassword` y contraseñas **exclusivas del lab**.
- [ ] Pasarle a Kevin/Carlitos/Cami el DN de bind y la URL: `ldap://ldap.agencia.redes.test`.
- [ ] Configurar la VM con DNS = `192.168.71.10` (ns1), sin `/etc/hosts`.

## Carlitos (Apache)
- [ ] VM con DNS = ns1; sitio en `http://www.agencia.redes.test`; IP fija = la de `www` en la tabla.

## Kevin (Correo)
- [ ] VM con DNS = ns1; IP fija = la de `mail`. El MX ya apunta a `mail.agencia.redes.test` (prioridad 10).
- [ ] Si necesita otro registro (p. ej. `imap`, `smtp` como CNAME o un `PTR`), avisarle a Marines.

## Cami (FTP)
- [ ] VM con DNS = ns1; IP fija = la de `ftp`. Rango pasivo definido (decirle a Ernesto cuál, para INT-03).

## Ernesto (Matriz de pruebas)
- [ ] Las filas DNS-01..05, WEB-01, MAIL-01, FTP-01 e INT-01..04 tienen comandos en `docs/pruebas-dns.md` y el script `scripts/test-dns.sh`.
- [ ] Necesita una VM **cliente** (Thunderbird, navegador, cliente FTP) con DNS = ns1.

## Lo que Marines necesita de los demás
- IP final de cada VM y confirmación de que ya usan ns1 como resolver.
- Cuando cada servicio esté arriba: avisar para correr el `test-dns.sh` completo y las pruebas INT.
