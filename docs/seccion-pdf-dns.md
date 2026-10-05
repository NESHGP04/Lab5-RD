# Sección DNS para el PDF final (borrador)

## Ejercicio 1 – DNS autoritativo local con BIND9

**Responsable:** Marines · **Zona:** `agencia.redes.test` · **Servidor:** `ns1.agencia.redes.test` (IP fija 192.168.71.10 – *confirmar*)

### Arquitectura
BIND9 corre en una VM Ubuntu Server (UTM) con IP fija configurada con netplan. Es el único resolver de
todas las VMs del grupo; **no se usó `/etc/hosts`**. La zona es `type master` y responde de forma
autoritativa (flag `aa`). La recursión se limita a la red local con *forwarders*, para que las VMs sigan
teniendo resolución externa (apt) sin depender de otro DNS interno.

### Configuración relevante
- `named.conf.options` → [`dns/named.conf.options`](../dns/named.conf.options)
- `named.conf.local` → [`dns/named.conf.local`](../dns/named.conf.local)
- Archivo de zona (Entregable c) → [`dns/zones/db.agencia.redes.test`](../dns/zones/db.agencia.redes.test)
- IP fija → [`dns/netplan-ns1.yaml`](../dns/netplan-ns1.yaml)
- Tabla de resolución (Entregable b) → [`docs/tabla-resolucion-dns.md`](tabla-resolucion-dns.md)

Registros: SOA (serial `AAAAMMDDNN`, se incrementa en cada cambio), NS, MX (`10 mail`) y A para
`ns1`, `ldap`, `www`, `mail`, `ftp`.

### Evidencias a incluir (capturas desde la VM real)
1. `named-checkconf -z` y `named-checkzone` sin errores.
2. `systemctl status named` y `ss -lntup | grep :53`.
3. `dig` A (ns1, ldap, www, mail, ftp), NS, MX y SOA (con `aa`).
4. NXDOMAIN para un nombre inexistente.
5. `cat /etc/hosts` en un cliente demostrando que no hay entradas manuales.
6. Resolución tras reiniciar la VM (INT-02).

### Explicación breve (para defensa)
- **SOA**: define el servidor primario, el contacto y los tiempos; el *serial* debe subir con cada cambio.
- **NS**: indica qué servidor es autoritativo para la zona. **A**: nombre → IPv4. **MX**: servidor de correo del dominio (prioridad menor = preferido).
- **Autoritativo vs. recursivo**: ns1 responde con `aa` por su zona y usa recursión/forwarders solo para nombres externos.
- **NXDOMAIN**: el servidor autoritativo afirma que el nombre no existe en la zona.

*(Las capturas reales se agregan cuando se ejecute en la VM; ver `docs/pruebas-dns.md`.)*
