# Lab 5 – Implementación de servicios de capa 7 en una red local

**CC3067 Redes · Universidad del Valle de Guatemala · Ciclo 2 de 2026**
**Caso asignado:** Concesionaria de vehículos · **Dominio:** `agencia.redes.test`
**Fecha de entrega:** 8 de octubre de 2026

Cinco servicios de capa 7 en una red local, cada uno en su propia VM (Ubuntu Server 24.04, UTM en modo Bridged),
que se resuelven entre sí por nombre DNS (sin `/etc/hosts`) y usan OpenLDAP como fuente de credenciales.

## Arquitectura de red

Red local `192.168.68.0/22` · gateway `192.168.68.1` · todas las VMs deben estar en la **misma red Wi-Fi**.

| Nombre (FQDN) | IP fija | Servicio | Responsable |
|---|---|---|---|
| `ns1.agencia.redes.test` | 192.168.71.10 | BIND9 | Marines |
| `ldap.agencia.redes.test` | 192.168.71.11 | OpenLDAP (`dc=agencia,dc=redes,dc=test`) | Cisco |
| `www.agencia.redes.test` | 192.168.71.12 | Apache | Carlitos |
| `mail.agencia.redes.test` | 192.168.71.13 | Postfix + Dovecot | Kevin |
| `ftp.agencia.redes.test` | 192.168.71.14 | vsftpd | Cami |

Registro MX: `agencia.redes.test. MX 10 mail.agencia.redes.test.` · Diagrama: [docs/diagrama-red.md](docs/diagrama-red.md)

## Estructura del repositorio

```
dns/                          Configuración de BIND9
  named.conf.options          Opciones (listen-on, recursión, forwarders)
  named.conf.local            Declaración de la zona
  netplan-ns1.yaml            IP fija de la VM ns1
  zones/db.agencia.redes.test Archivo de zona (SOA, NS, MX, A)
scripts/
  test-dns.sh                 Pruebas DNS-01..05 + resolución WEB/MAIL/FTP (guarda evidencia)
  validar-dns-docker.sh       Validación previa de la config en un contenedor
docs/
  guia-vm-utm.md              Cómo crear la VM en UTM (Bridged) – sirve para todo el equipo
  guia-implementacion-dns.md  Pasos para montar el DNS en la VM
  tabla-resolucion-dns.md     Tabla de resolución de nombres
  diagrama-red.md             Diagrama de red
  pruebas-dns.md              Pruebas DNS y sus resultados
  pendientes-para-equipo.md   Qué necesita cada integrante
  bitacora.md                 Bitácora de lo realizado
evidencias/dns/               Salidas de dig/nslookup/ss/journalctl y capturas
```

## Entregables del laboratorio

| Entregable | Dónde está |
|---|---|
| a. Diagrama de red local | [docs/diagrama-red.md](docs/diagrama-red.md) |
| b. Tabla de resolución de nombres DNS | [docs/tabla-resolucion-dns.md](docs/tabla-resolucion-dns.md) |
| c. Archivo de zona DNS | [dns/zones/db.agencia.redes.test](dns/zones/db.agencia.redes.test) |
| d. Archivo LDIF con los usuarios | ⬜ Pendiente (Cisco) |
| e. PDF con configuraciones, matriz de pruebas, evidencias y roles | ⬜ En preparación |

## Cómo reproducir el DNS

Detalle completo en [docs/guia-implementacion-dns.md](docs/guia-implementacion-dns.md). Resumen:

```bash
sudo apt install -y bind9 bind9-utils dnsutils
sudo mkdir -p /etc/bind/zones
sudo cp dns/named.conf.options dns/named.conf.local /etc/bind/
sudo cp dns/zones/db.agencia.redes.test /etc/bind/zones/
sudo named-checkconf -z
sudo named-checkzone agencia.redes.test /etc/bind/zones/db.agencia.redes.test
sudo systemctl restart named        # restart, no solo enable --now: apt ya lo arrancó con la config por defecto
./scripts/test-dns.sh 192.168.71.10 # guarda la salida en evidencias/dns/
```

Cada VM del grupo debe usar `192.168.71.10` como DNS (en netplan: `nameservers: addresses: [192.168.71.10]`).
Al editar la zona hay que **subir el serial** y recargar: `sudo rndc reload agencia.redes.test`.

## Notas

- Contraseñas de usuarios, LDAP y demás son **exclusivas del laboratorio**; no se suben credenciales personales al repo.
- La bitácora completa del trabajo está en [docs/bitacora.md](docs/bitacora.md).
