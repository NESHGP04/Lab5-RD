# Plan de ejecución grupal de la matriz (sesión con todos los servicios arriba)

Responsable: Ernesto. Objetivo: correr las 33 filas de `docs/matriz-pruebas.md` en una sola sesión y salir con todas las evidencias.
Duración estimada: 90–120 min. Entrega: 8 de octubre de 2026.

## 0. Antes de la sesión (cada quien, Ernesto verifica)
- [ ] Todos en la **misma red Wi-Fi** (192.168.68.0/22). Desde la Mac: `ping -c2 192.168.71.10` responde.
- [ ] Cada VM: `ip -br a` muestra su IP fija, `cat /etc/hosts` sin entradas del dominio, `dig www.agencia.redes.test +short` = .12.
- [ ] Servicios `enabled` + `active`: `systemctl is-enabled slapd apache2 postfix dovecot vsftpd` (el que corresponda a cada VM).
- [ ] Datos recibidos por Ernesto: DN/usuario/clave LDAP de prueba, ruta protegida, 2 buzones + puertos + TLS, usuario FTP + directorio + rango pasivo.
- [ ] Mac de Ernesto: DNS = 192.168.71.10, Thunderbird instalado, `lftp` instalado (`brew install lftp`), carpeta `evidencias/matriz/` creada.
- [ ] Todos los usuarios LDAP existen (6) y el mismo usuario sirve en web, correo y FTP (si FTP usa usuarios locales, anotarlo).

## 1. Orden de ejecución
Cada paso: quién ejecuta · qué se captura · archivo de evidencia (`evidencias/matriz/<ID>.png|txt`). Toda captura incluye hora y hostname visibles.

| # | Bloque | Filas | Quién | Cómo |
|---|---|---|---|---|
| 1 | Corrida automática base | DNS-01..05, WEB-01, MAIL-01, FTP-01, INT-01 | Ernesto | `./scripts/test-matriz.sh` (con variables); guarda `matriz-<fecha>.txt` |
| 2 | LDAP | LDAP-01..04 | Ernesto (+ Cisco muestra `slapcat`/log) | script + captura de terminal |
| 3 | Web | WEB-02..04 | Ernesto | Firefox/Safari: página principal, login válido, login inválido, usuario inexistente |
| 4 | **WEB-05** | WEB-05 | Cisco + Carlitos + Ernesto | Cisco: `sudo systemctl stop slapd`. Ernesto: intenta login (captura). Carlitos: `sudo tail -n 20 /var/log/apache2/error.log` (captura). Cisco: `sudo systemctl start slapd`. **Reiniciar LDAP antes de seguir** |
| 5 | Correo | MAIL-02..07 | Ernesto + Kevin | Thunderbird: configurar cuenta (captura MAIL-02), login válido (MAIL-03), clave mala (MAIL-04), enviar usuario1→usuario2 (MAIL-05), leer en usuario2 (MAIL-06), enviar a `noexiste@` (MAIL-07). Kevin captura `journalctl -u postfix -u dovecot` tras cada paso |
| 6 | FTP | FTP-02..08 | Ernesto + Cami | `lftp` interactivo para capturas (login, `ls`, `put`, `get`, `cd /etc`, anónimo, clave mala); script como respaldo. Cami: `ls -l` del directorio y `vsftpd.log` |
| 7 | **INT-03** puertos | INT-03 | cada responsable | `sudo ss -lntup` en su VM (captura con hostname) |
| 8 | **INT-04** logs | INT-04 | cada responsable | extractos de logs del paso 2–6 (`journalctl`/`tail`) |
| 9 | **INT-02** reinicio | INT-02 | cada responsable, uno por uno | `sudo reboot` → `systemctl status` → Ernesto repite `test-matriz.sh`. Hacerlo **al final** para no perder sesiones |
| 10 | Corrida final | todas | Ernesto | segunda `test-matriz.sh` post-reinicio → prueba de persistencia |

Capturas de MAIL-03/04 y de WEB-03/04: pedir al responsable el log del mismo minuto.

## 2. Evidencia que debe quedar (checklist)
- [ ] `evidencias/matriz/matriz-<fecha>.txt` ×2 (antes y después del reinicio).
- [ ] Capturas con nombre = ID: `web-02.png`, `web-03.png`, `web-04.png`, `web-05.png`, `mail-02.png` … `mail-07.png`, `ftp-02.png` … `ftp-08.png`.
- [ ] Logs de cada servicio como `.txt`: `log-ldap.txt`, `log-apache.txt`, `log-mail.txt`, `log-ftp.txt`.
- [ ] `ss-<vm>.png` ×5 (INT-03) y `status-<vm>.png` ×5 (INT-02).
- [ ] Ninguna captura contiene contraseñas personales (solo claves del lab).

## 3. Después de la sesión
1. Actualizar columnas "Resultado obtenido" / "Estado" en `docs/matriz-pruebas.md` (⬜ → ✅/❌).
2. Fallas ❌: abrir con el responsable, corregir, repetir **solo** esa fila y guardar nueva evidencia.
3. Commit de `evidencias/matriz/` y `docs/matriz-pruebas.md`.
4. Armar la sección del PDF (ver abajo). Restaurar DNS de la Mac: `sudo networksetup -setdnsservers Wi-Fi Empty`.

## 4. Qué va en el PDF (sección de Ernesto)
Se agrega después del Ejercicio 1 (mismo formato: título, tabla, figuras con pie):
1. **Tabla de roles y responsables** (entregable e): integrante · carnet · servicio · VM/IP · ejercicio.
2. **Ejercicio 6 – Matriz de pruebas**: tabla completa de 33 filas (ID, prueba, procedimiento, resultado obtenido, evidencia/figura, estado). Reutilizar la fila-DNS de Marines; no duplicarla con otro formato.
3. **Evidencias**: figuras numeradas continuando la numeración del PDF (Fig. 7 en adelante), una por fila o grupo de filas, con pie que cite el ID.
4. **Pruebas de integración** (INT-01..04) de los 5 servidores, no solo DNS.
5. **Explicación de conceptos** que pide el enunciado y que aplique a la matriz (p. ej. FTP: conexión de control vs. datos; ver Ejercicio 5).
6. Enlace al repo (ya está en la portada) y la corrida final de `test-matriz.sh` como apéndice.

## 5. Plan B si algo falla en la sesión
| Problema | Acción |
|---|---|
| Mac no ve las VMs | cliente aislado por el AP → hotspot/otra red (recalcular IPs y serial de la zona) |
| Thunderbird no acepta certificado | usar STARTTLS con excepción de certificado de laboratorio y documentarlo |
| FTP pasivo falla desde Mac | abrir rango pasivo en la VM (`ufw`) y confirmar `pasv_address`; probar `lftp -e 'set ftp:passive-mode on'` |
| Un servicio no está listo | marcar la fila ❌/⬜ con motivo; no inventar evidencia |
