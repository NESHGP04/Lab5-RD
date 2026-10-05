# Guía de implementación – DNS autoritativo con BIND9 (Ejercicio 1)

Zona: **agencia.redes.test** · Responsable: Marines · VM Ubuntu Server (UTM)

> Red Bridged `192.168.68.0/22`, gateway `192.168.68.1`. IPs fijas propuestas: bloque `192.168.71.x`
> (ns1 = `192.168.71.10`). Si cambian, se editan en `dns/zones/db.agencia.redes.test`,
> `dns/named.conf.options` y `dns/netplan-ns1.yaml`. Usuario de la VM: `adminn`.

## 0. Pasar los archivos del repo a la VM (desde la Mac)
La VM ya tiene IP por DHCP (`192.168.68.50` en este momento):
```bash
cd ~/Documents/UVG/REDES/Lab5-RD
scp -r dns scripts adminn@192.168.68.50:~/
ssh adminn@192.168.68.50
```

## 1. Instalar BIND9 (primero, con la red DHCP actual para tener internet)
```bash
sudo apt update
sudo apt install -y bind9 bind9-utils dnsutils
```

## 2. Copiar la configuración
```bash
sudo mkdir -p /etc/bind/zones
sudo cp ~/dns/named.conf.options /etc/bind/named.conf.options
sudo cp ~/dns/named.conf.local   /etc/bind/named.conf.local
sudo cp ~/dns/zones/db.agencia.redes.test /etc/bind/zones/
sudo chown -R root:bind /etc/bind/zones
```

## 3. IP fija (la sesión SSH se corta; reconectar a la IP nueva)
Cloud-init crea `50-cloud-init.yaml` con DHCP; hay que desactivarlo para que no se mezcle con la IP fija:
```bash
sudo mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak
echo 'network: {config: disabled}' | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
sudo cp ~/dns/netplan-ns1.yaml /etc/netplan/01-ns1.yaml
sudo chmod 600 /etc/netplan/01-ns1.yaml
sudo netplan apply          # si usas SSH se desconecta
# reconectar:  ssh adminn@192.168.71.10
ip -br a                    # debe mostrar 192.168.71.10/22
ping -c 2 192.168.68.1      # gateway
```
Si pierdes conexión y no vuelve, entra por la consola de UTM y revisa `sudo netplan try` / el YAML.

## 4. Validar (evidencia: captura de ambas salidas)
```bash
sudo named-checkconf -z
sudo named-checkzone agencia.redes.test /etc/bind/zones/db.agencia.redes.test
```

## 5. Arrancar y dejar persistente tras reinicio (INT-02)
```bash
sudo systemctl enable --now named      # en Ubuntu el servicio es "named" (alias bind9)
sudo systemctl status named
sudo ss -lntup | grep ':53'            # INT-03: debe escuchar en 53 TCP/UDP
```

## 6. Probar
```bash
./scripts/test-dns.sh 192.168.71.10    # guarda la salida en evidencias/dns/
```

## 7. Configurar los clientes (los demás integrantes, ver pendientes)
Cada VM debe usar `ns1` como DNS (en netplan: `nameservers: addresses: [192.168.71.10]`,
`search: [agencia.redes.test]`). **No usar `/etc/hosts`** (el PDF lo prohíbe).

## Notas / problemas típicos
- `systemd-resolved` escucha en `127.0.0.53:53`; no choca con BIND porque `listen-on` solo
  usa `127.0.0.1` y la IP de ns1.
- Al editar la zona: **subir el serial**, luego `sudo rndc reload agencia.redes.test`.
- Logs: `sudo journalctl -u named -n 50` (evidencia INT-04).
- Firewall: si `ufw` está activo → `sudo ufw allow 53`.
