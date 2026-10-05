# Bitácora – Lab 5 (parte DNS · Marines)

## 2026-10-04

**1. Análisis del enunciado**
- Leído el PDF del lab. Dominio asignado: Concesionaria de vehículos → `agencia.redes.test`.
- Mi parte: Ejercicio 1 (DNS, 15 pts) + entregables a (diagrama), b (tabla de resolución), c (archivo de zona)
  + sección DNS del PDF + pruebas DNS-01..05 y las de resolución de WEB-01, MAIL-01, FTP-01, INT-01..04.
- Roles: Marines DNS · Cisco OpenLDAP · Carlitos Apache · Kevin Correo · Cami FTP · Ernesto matriz de pruebas.
- Referencia: diagrama de pizarra (Cliente + 5 VMs: BIND, OpenLDAP, Apache, Correo, FTP).
  La imagen de AWS (Zenite Prestige) es del Proyecto 2, **no se reutilizaron sus IPs**.

**2. Archivos creados (sin commits, para revisión)**
- `dns/zones/db.agencia.redes.test` – zona con SOA, NS, MX y A de ns1, ldap, www, mail, ftp.
- `dns/named.conf.local`, `dns/named.conf.options` – zona master, recursión solo red local.
- `dns/netplan-ns1.yaml` – IP fija de la VM.
- `scripts/validar-dns-docker.sh` – validación en contenedor Ubuntu 24.04 (no sustituye evidencia real).
- `scripts/test-dns.sh` – pruebas para correr en la VM/cliente; guarda salida en `evidencias/dns/`.
- `docs/`: guía de implementación, tabla de resolución, diagrama (mermaid), pruebas DNS, roles,
  pendientes del equipo, sección PDF.

**3. Validación local (Docker)**
- `named-checkconf -z` OK; `named-checkzone` OK (serial 2026100401).
- `dig`: A de los 5 nombres correctos, SOA con flag `aa`, NS y MX (`10 mail`) correctos, NXDOMAIN para nombre inexistente.
- Salida guardada en `evidencias/dns/validacion-docker.txt`.

**Decisiones**
- IPs **provisionales** 192.168.64.10–.14 (rango por defecto de UTM Shared). Pendiente confirmar con el equipo.
- `aerolínea` no aplica; dominio sin acentos, sin problema para `agencia`.
- Recursión habilitada solo para la red local con forwarders 1.1.1.1/8.8.8.8 para que las VMs sigan haciendo `apt`.

**4. Decisión de red (mismo día)**
- Cada integrante tiene su VM en su propia Mac → se usa UTM en modo **Bridged** (no Shared).
- Consecuencia: las IPs 192.168.64.x del repo ya no aplican; la subred será la del Wi-Fi real.
  Las IPs finales (ns1, ldap, www, mail, ftp) se fijan cuando se conozca la subred/gateway.
- Creada `docs/guia-vm-utm.md` (descargas, recursos por VM, ajustes de UTM, valores del instalador, riesgos de Bridged).
- `docs/pendientes-para-equipo.md` actualizado.

**5. VM creada y red real (2026-10-04)**
- VM `ns1` instalada (Ubuntu Server 24.04 ARM64, usuario `adminn`). El instalador se atoró al final pidiendo quitar el ISO
  (`Failed unmounting cdrom`): es normal; se resolvió con Clear del CD/DVD en UTM.
- Red Bridged detectada: `192.168.68.50/22` por DHCP, gateway `192.168.68.1`, interfaz `enp0s1` → subred `192.168.68.0/22`.
- IPs fijas definidas en el bloque `192.168.71.x` (dentro de la /22, lejos del DHCP): ns1 .10, ldap .11, www .12, mail .13, ftp .14.
- Actualizados: zona (serial → `2026100402`), `named.conf.options` (listen-on/allow-query), `netplan-ns1.yaml` (/22, gw 192.168.68.1),
  tabla de resolución, diagrama, `test-dns.sh` y docs. Revalidado en Docker: checkconf/checkzone OK, A/NS/MX/SOA(aa)/NXDOMAIN OK.
- `guia-implementacion-dns.md` reordenada: scp de archivos → instalar BIND (con DHCP/internet) → copiar config →
  IP fija (desactivando `50-cloud-init.yaml` para que no se mezcle con DHCP) → validar → probar.
- Riesgo: la red 192.168.68.0/22 es la de la casa de Marines; los demás deben estar en esa misma red para las pruebas conjuntas
  (o acordar otra red/hotspot y recalcular IPs).

**6. BIND9 funcionando en la VM (2026-10-05 UTC)**
- Archivos copiados con `scp` a la VM; `named-checkconf -z` y `named-checkzone` OK (serial 2026100402).
- IP fija `192.168.71.10/22` aplicada con netplan (`50-cloud-init.yaml` desactivado).
- Primer `dig` devolvió NXDOMAIN de los root servers y sin `aa`: `apt install` había arrancado `named` con la config por defecto y
  `enable --now` no lo recargó. Se resolvió con `sudo systemctl restart named`. (Un intento falló por teclear `names` en vez de `named`.)
- Tras el reinicio: SOA autoritativo con `aa` y serial 2026100402.
- `./scripts/test-dns.sh` ejecutado en la VM: DNS-01..05, WEB-01, MAIL-01, FTP-01 correctos; INT-01 parcial (solo desde ns1).
  Resultados detallados en `docs/pruebas-dns.md`. Archivo de evidencia en la VM: `~/evidencias/dns/pruebas-dns-20261005-010740.txt`.
- Aclaración de uso: comandos de Mac (`scp`, `cd ~/Documents/...`) ejecutados por error dentro de la VM; sin daño.

**7. INT-02 – reinicio (2026-10-05 01:14 UTC)**
- `sudo reboot` en ns1. Al volver: `named` enabled y active (running) desde 01:14:43, IP fija persistente y `dig` del SOA con `aa`
  y serial 2026100402. INT-02 ✅ (captura guardada por Marines).
- Evidencias traídas al repo: `evidencias/dns/pruebas-dns-20261005-010522.txt` y `...010740.txt` (misma corrida repetida; la válida es 010740).

**8. INT-03 – puertos (2026-10-05)**
- `ss -lntup | grep :53` tras el reinicio: `named` en 53 UDP/TCP solo en 127.0.0.1 y 192.168.71.10 (sin IPv6, como en la config);
  `systemd-resolved` en 127.0.0.53/.54 sin conflicto. INT-03 ✅.

**9. INT-04 – logs (2026-10-05)**
- `journalctl -u named`: arranque correcto, zona `agencia.redes.test` cargada (serial 2026100402), `all zones loaded`, `running`.
- Ruido en el log: `network unreachable resolving './NS/IN': 2001:...` (IPv6 inexistente en la VM). Solución opcional: `-4` en `/etc/default/named`.
- `rndc querylog on` + dos `dig` (01:21 UTC): el log registra `query: www.agencia.redes.test IN A` y `query: noexiste... IN A`. INT-04 ✅.

**10. INT-01 desde un cliente (2026-10-04 19:25 CST)**
- Mac de Marines con DNS = 192.168.71.10 (`networksetup`), `/etc/hosts` solo con entradas por defecto: los 5 FQDN resuelven sin `@`,
  MX correcto y NXDOMAIN para nombre inexistente. Evidencia: `evidencias/dns/int01-desde-mac.txt`. INT-01 ✅.
- Con esto quedan ✅ todas las pruebas DNS asignadas a Marines (DNS-01..05, WEB-01, MAIL-01, FTP-01, INT-01..04).
- Recordatorio: restaurar el DNS de la Mac al terminar (`sudo networksetup -setdnsservers Wi-Fi Empty`).

**Pendiente / bloqueos**
- ~~Decisión de red~~ → Bridged. Falta que el equipo confirme red Wi-Fi común y sus IPs (bloque 192.168.71.x propuesto).
- Falta zona inversa (PTR): opcional; evaluar si Kevin la necesita para el correo.
- Diagrama final y exportación a imagen para el PDF.
