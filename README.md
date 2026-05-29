# Trivy Security Monitoring

https://wiki.i4cloud.com.ar/es/instructivos/en_proceso/trivy_HTZSVDB007

Sistema de monitoreo y detección de vulnerabilidades utilizando Trivy, n8n y Telegram.

## Objetivo

Automatizar el escaneo de vulnerabilidades en servidores Linux y contenedores Docker, notificando únicamente vulnerabilidades nuevas mediante Telegram.

## Arquitectura

```text
Trivy
   ↓
Script Bash
   ↓
n8n (SSH Execute)
   ↓
Telegram
```

## Requisitos

* Ubuntu Server
* Trivy
* n8n
* Docker (opcional)
* Bot de Telegram

## Instalación

### Clonar repositorio

```bash
git clone https://github.com/gbenavente/trivy-security-monitoring.git
cd trivy-security-monitoring
```

### Scripts incluidos

* scripts/trivy-scan.sh
* scripts/trivy-docker-scan.sh

## Configuración Trivy

Actualizar base de vulnerabilidades:

```bash
trivy image alpine:latest
```

Escaneo manual:

```bash
bash scripts/trivy-scan.sh
```

## Configuración n8n

Workflow Host:

```text
n8n/trivy-host-flow.json
```

Importar desde:

```text
Workflows → Import from File
```

## Configuración Telegram

El workflow envía el resultado del script a un grupo de Telegram mediante un bot configurado en n8n.

Ejemplo:

```text
🚨 TRIVY SECURITY REPORT
Host=HTZSVDB007
HIGH=48
CRITICAL=0
TOTAL=48
NUEVAS=3
```

## Estructura

```text
.
├── scripts
├── n8n
├── docs
├── examples
└── README.md
```

## Licencia

Uso interno y educativo.

