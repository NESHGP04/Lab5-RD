# Instrucciones para recolectar evidencia (Lab 5)

Para: Cisco (ldap), Carlitos (www), Kevin (mail), Cami (ftp). Pide: Ernesto. Entrega: 8 de octubre de 2026.

Con `recolectar-evidencia.sh` se genera en tu VM un `.txt` con lo que Ernesto necesita para la matriz de pruebas y el PDF (INT-02, INT-03, INT-04 y configuraciones).

## 1. Pasar el script a tu VM

Desde tu Mac, con el nombre o la IP de tu VM:

```bash
scp recolectar-evidencia.sh <usuario>@<IP-de-tu-VM>:~
```

IPs: ldap `192.168.71.11` · www `192.168.71.12` · mail `192.168.71.13` · ftp `192.168.71.14`.

O copia el contenido con `nano recolectar-evidencia.sh` dentro de la VM.

## 2. Correrlo

Dentro de tu VM, elige **tu** servicio:

```bash
sudo bash recolectar-evidencia.sh ldap    # Cisco
sudo bash recolectar-evidencia.sh www     # Carlitos
sudo bash recolectar-evidencia.sh mail    # Kevin
sudo bash recolectar-evidencia.sh ftp     # Cami
```

Genera `evidencia-<servicio>-<fecha>.txt` en la carpeta actual.

## 3. Qué recolecta

| VM | Contenido |
|---|---|
| todas | `ss -lntup` (INT-03), `uptime` y estado del servicio (INT-02) |
| ldap | usuarios con `ldapsearch`, log de `slapd`, `usuarios-<fecha>.ldif` (entregable d) |
| www | sitio y módulos LDAP de Apache, carpeta protegida, `access.log`, `error.log` |
| mail | `postconf -n`, `doveconf -n`, buzones, log de Postfix y Dovecot |
| ftp | `vsftpd.conf` activo, `ufw`, usuarios, `ls -l` del directorio, `vsftpd.log` |

Las líneas con `pass`, `pw` o `secret` salen como `<oculto>`.

## 4. Reinicio (INT-02)

1. Corre el script (guarda el `.txt`).
2. `sudo reboot`.
3. Entra de nuevo y corre el script otra vez.
4. Manda **los dos** `.txt`.

## 5. Mandar a Ernesto

- El `.txt` (o los dos, si hiciste el reinicio).
- Cisco: también `usuarios-<fecha>.ldif`.
- Antes de mandar: abre el `.txt` y revisa que no haya claves personales. Solo se aceptan claves del laboratorio.

Para traer los archivos a tu Mac:

```bash
scp <usuario>@<IP-de-tu-VM>:~/evidencia-*.txt .
```

## 6. Lo manual por responsable

| Quién | Qué | Fila |
|---|---|---|
| Cisco | `sudo systemctl stop slapd`, esperar el intento de login de Ernesto, `sudo systemctl start slapd` | WEB-05 |
| Carlitos | `sudo tail -n 20 /var/log/apache2/error.log` justo después del intento, con captura | WEB-05 |
| Kevin | `sudo journalctl -u postfix -u dovecot -n 80 --no-pager` después de cada prueba de correo | MAIL-03..07 |
| Cami | `ls -l` del directorio autorizado tras la carga de Ernesto | FTP-06 |

Las capturas de pantalla deben mostrar el **hostname** y la **hora**.

## 7. Notas

- Esto es solo para el laboratorio. No se suben credenciales personales al repo.
- El `.ldif` incluye hashes de `userPassword` de las cuentas del lab. No lo pegues en capturas.
- Si algo falla, manda el error exacto a Ernesto.
