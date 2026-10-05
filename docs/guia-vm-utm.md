# Guía para crear la VM en UTM (Mac) – modo Bridged

Sirve para la VM de DNS (`ns1`) y como base para que cada integrante cree la suya.

## 1. Descargas
- **UTM**: https://mac.getutm.app (o `brew install --cask utm`).
- **Ubuntu Server 24.04 LTS para ARM64** (si tu Mac es Apple Silicon M1–M4): https://cdimage.ubuntu.com/releases/24.04/release/
  → archivo `ubuntu-24.04.x-live-server-arm64.iso`.
  Si tu Mac es Intel, usa la imagen `amd64` desde ubuntu.com/download/server.
  **Todo el equipo debe usar la misma versión.**

## 2. Recursos recomendados por VM

| VM | CPU | RAM | Disco |
|---|---|---|---|
| ns1 (DNS) – Marines | 1 | 1 GB | 10 GB |
| ldap (OpenLDAP) – Cisco | 1 | 1 GB | 10 GB |
| www (Apache) – Carlitos | 1 | 1 GB | 10 GB |
| mail (Postfix+Dovecot) – Kevin | 2 | 2 GB | 15 GB |
| ftp (vsftpd) – Cami | 1 | 1 GB | 10 GB |
| cliente (Thunderbird/navegador) | 2 | 2–4 GB | 20 GB, **Ubuntu Desktop** o usar Thunderbird de macOS |

> Si el cliente es tu propia Mac (Thunderbird/navegador de macOS), no hace falta VM de cliente: solo cambia el DNS de tu Mac a ns1.

## 3. Crear la VM en UTM
1. **Create a New Virtual Machine → Virtualize → Linux**.
2. *Boot ISO Image*: elige el `.iso`. 
3. *Memory/CPU*: según la tabla (para ns1: 1024 MB, 1 core).
4. *Storage*: 10 GB.
5. *Shared Directory*: omitir. Nombre: `ns1`. Antes de guardar marca **Open VM Settings**.
6. En **Settings → Network**:
   - **Network Mode: Bridged (Advanced)**
   - **Bridged Interface: en0** (Wi-Fi; si usas cable/adaptador, la interfaz correspondiente).
   - Opcional: *Emulated Network Card* `virtio-net-pci` (por defecto).
7. Guardar → ▶ Play.

## 4. Instalador de Ubuntu Server (valores)
| Pantalla | Valor |
|---|---|
| Idioma | English (evita errores de locale) |
| Teclado | Spanish (Latin American) |
| Tipo de instalación | **Ubuntu Server** (no minimized está bien) |
| Red | Dejar DHCP en la interfaz; anota la IP que muestra (ya está en tu red real por Bridged) |
| Proxy / mirror | por defecto |
| Disco | Usar disco completo (sin LVM cifrado) |
| Profile | Your name: `admin` · **Server name: `ns1`** · usuario `admin` · contraseña de laboratorio (no personal) |
| Ubuntu Pro | Skip |
| **OpenSSH server** | ✅ **Instalar** (para conectarte desde tu Mac y copiar salidas) |
| Featured snaps | No seleccionar ninguno |

Al terminar: **Reboot Now**. Si vuelve a mostrar el instalador, en UTM: icono CD/DVD → **Clear** (quitar ISO) y reiniciar.

## 5. Primer arranque
```bash
sudo apt update && sudo apt -y upgrade
ip -br a                 # IP actual y nombre de interfaz (p. ej. enp0s1)
ip route | grep default  # gateway
resolvectl status | grep -i 'DNS Server'
```
Desde tu Mac puedes entrar por SSH para trabajar más cómodo:
```bash
ssh admin@<IP_de_la_VM>
```

## 6. ⚠️ Lo importante de Bridged
- Con Bridged la VM queda **en la misma red que tu Mac** (la subred real del Wi-Fi, p. ej. 192.168.1.0/24 o 10.x.x.x),
  **no** en 192.168.64.0/24. Por eso las IPs que puse en el repo son solo de ejemplo.
- Las 5 VMs **tienen que estar en la misma subred** para verse: hay que probar juntos, en la **misma red Wi-Fi**.
- Elegir IPs fijas **fuera del rango DHCP del router** (p. ej. `.200`–`.205`) para evitar choques. Sin acceso al router, usar un rango alto y comprobar que no responda: `ping` y `arping`.
- Si el Wi-Fi es institucional (UVG) puede bloquear varias MAC por puerto o aislar clientes. Plan B: un hotspot del celular o un Wi-Fi casero para el día de pruebas/evidencias.
- Si cambias de red (casa → universidad) cambian subred y gateway: hay que actualizar netplan, `named.conf.options` y la zona. Por eso conviene definir **una sola red de trabajo** para evidencias.

## 7. Qué me tienes que pasar para seguir
Con la VM ya arriba y conectada a la red donde se harán las pruebas:
```bash
ip -br a
ip route | grep default
```
Con eso fijo la tabla de IPs (ns1, ldap, www, mail, ftp), actualizo el repo y seguimos con `docs/guia-implementacion-dns.md`.
