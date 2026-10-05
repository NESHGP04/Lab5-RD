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

**Pendiente / bloqueos**
- ~~Decisión de red~~ → Bridged. Falta que el equipo confirme red Wi-Fi común y sus IPs (bloque 192.168.71.x propuesto).
- Ejecutar la guía en la VM y tomar capturas reales.
- Crear la VM de ns1 y ejecutar la guía en ella; tomar capturas reales.
- Falta zona inversa (PTR): opcional; evaluar si Kevin la necesita para el correo.
- Diagrama final y exportación a imagen para el PDF.
