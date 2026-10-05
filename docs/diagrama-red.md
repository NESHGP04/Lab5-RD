# Diagrama de red local (Entregable a) – BORRADOR

Todos consultan primero a BIND9
y OpenLDAP es la fuente de credenciales para Apache, Correo y FTP.

```mermaid
flowchart LR
    C["Cliente<br/>Thunderbird · navegador · cliente FTP<br/>DNS = 192.168.71.10"]

    subgraph RED["Red local 192.168.68.0/22 (Bridged)  ·  dominio agencia.redes.test"]
        DNS["ns1 · BIND9<br/>192.168.71.10"]
        LDAP["ldap · OpenLDAP<br/>192.168.71.11<br/>dc=agencia,dc=redes,dc=test"]
        WEB["www · Apache<br/>192.168.71.12"]
        MAIL["mail · Postfix + Dovecot<br/>192.168.71.13"]
        FTP["ftp · vsftpd<br/>192.168.71.14"]
    end

    C -- "1. consulta DNS (53)" --> DNS
    C -- "HTTP 80" --> WEB
    C -- "SMTP 25/587 · IMAP 143" --> MAIL
    C -- "FTP 21 + pasivo" --> FTP
    WEB -- "bind LDAP 389" --> LDAP
    MAIL -- "bind LDAP 389" --> LDAP
    FTP -. "(si usa LDAP)" .-> LDAP
```

Pendiente: confirmar IPs, que todos estén en esta misma red Wi-Fi y puertos finales con cada responsable.
