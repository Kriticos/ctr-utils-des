# ctr-utils

Container utilitário em Docker para rotinas operacionais, monitoramento e tarefas agendadas com `cron`. O projeto reúne ferramentas de diagnóstico de rede, coleta de métricas, envio para Zabbix, inspeção de certificados e scripts auxiliares de backup, tudo empacotado em uma imagem baseada em Debian.

## Visão Geral

O objetivo deste repositório é disponibilizar um container de apoio para ambientes self-hosted, com foco em:

- monitoramento de conectividade e desempenho de internet;
- envio de métricas para Zabbix com `zabbix_sender`;
- coleta de estatísticas de containers Docker;
- inspeção e descoberta de certificados TLS;
- execução centralizada de scripts shell via `cron`;
- apoio operacional com utilitários de rede, banco e sistema.

Na prática, o container sobe com `cron` em primeiro plano e executa scripts montados por volume em `/usr/local/bin/scripts`, permitindo manter a automação versionada no próprio repositório.

## Principais Recursos

- Imagem Docker baseada em `debian:bookworm`
- Ferramentas de rede e diagnóstico como `curl`, `wget`, `ping`, `mtr`, `dnsutils`, `net-tools` e `speedtest`
- Cliente MySQL instalado para operações administrativas
- Integração com Docker host via `/var/run/docker.sock`
- Scripts de monitoramento para Zabbix
- Rotinas agendadas por `cron`
- Workflows de qualidade e segurança com GitHub Actions

## Estrutura do Projeto

```text
.
├── Dockerfile
├── docker-compose.yml
├── prepare.sh
├── cron/
│   └── cron
├── scripts/
│   ├── backup/
│   ├── certificados/
│   ├── logs/
│   ├── nginx/
│   ├── zabbix/
│   │   ├── containers/
│   │   └── speedtest/
│   └── entrypoint.sh
└── .github/workflows/
```

## Componentes

### Container

O `Dockerfile` instala os pacotes essenciais do ambiente, adiciona o `speedtest` da Ookla e instala o `zabbix-sender`. A inicialização efetiva é feita por [`scripts/entrypoint.sh`](/bskp-des/ctr-utils-des/scripts/entrypoint.sh), que:

- registra o aceite da licença do Speedtest na primeira execução;
- garante a existência do log de cron;
- inicia o `cron` em foreground para manter o container ativo.

### Agendamentos

O arquivo [`cron/cron`](/bskp-des/ctr-utils-des/cron/cron) agenda atualmente:

- `speedtest.sh` a cada 10 minutos;
- `check_connectivity_level.sh` a cada 1 minuto;
- `send_docker_stats.sh` a cada 1 minuto;
- `clean_log.sh` diariamente às 23:00.

### Scripts incluídos

Alguns scripts relevantes do repositório:

- [`scripts/zabbix/speedtest/speedtest.sh`](/bskp-des/ctr-utils-des/scripts/zabbix/speedtest/speedtest.sh): executa Speedtest e envia download, upload, latência, perda de pacotes e metadados para o Zabbix.
- [`scripts/zabbix/speedtest/check_connectivity_level.sh`](/bskp-des/ctr-utils-des/scripts/zabbix/speedtest/check_connectivity_level.sh): classifica o nível de conectividade da internet com testes de gateway, DNS, resolução e HTTP.
- [`scripts/zabbix/containers/send_docker_stats.sh`](/bskp-des/ctr-utils-des/scripts/zabbix/containers/send_docker_stats.sh): coleta `docker stats` e envia CPU, memória, rede, disco e PIDs de containers específicos.
- [`scripts/nginx/check_cert.sh`](/bskp-des/ctr-utils-des/scripts/nginx/check_cert.sh): lista certificados presentes dentro do container `srv-nginx`.
- [`scripts/nginx/cert-days.sh`](/bskp-des/ctr-utils-des/scripts/nginx/cert-days.sh): retorna dias restantes até a expiração de um certificado.
- [`scripts/nginx/discovery-cert.sh`](/bskp-des/ctr-utils-des/scripts/nginx/discovery-cert.sh): apoio à descoberta de certificados para monitoramento.
- [`scripts/backup/backup_data.sh`](/bskp-des/ctr-utils-des/scripts/backup/backup_data.sh): gera backups compactados de diretórios definidos no script.
- [`scripts/backup/backup_databases.sh`](/bskp-des/ctr-utils-des/scripts/backup/backup_databases.sh): realiza dump de bases MySQL em containers Docker.
- [`scripts/logs/clean_log.sh`](/bskp-des/ctr-utils-des/scripts/logs/clean_log.sh): remove logs `.log` de `/var/log`.

## Requisitos

- Docker
- Docker Compose ou `docker compose`
- Permissão para acessar o socket Docker do host
- Rede Docker externa `network-share`

## Como Usar

### 1. Preparar o ambiente

Copie o arquivo de exemplo:

```bash
cp .env.example .env
```

Depois ajuste os valores conforme o seu ambiente.

Se quiser automatizar a criação das pastas base e da rede Docker externa, execute:

```bash
./prepare.sh
```

### 2. Subir o container

```bash
docker compose up -d --build
```

### 3. Verificar o funcionamento

```bash
docker compose ps
docker compose logs -f ctr-utils
```

## Configuração

O arquivo `.env.example` já traz a configuração base do container:

```env
SRV_NAME=ctr-utils
RELEASE=blackskulp/ctr-utils:latest
NETWORK_NAME=network-share
CONTAINER_IP=172.18.0.70
SUBNET=172.18.0.16
VOL_SCRIPTS=./scripts:/usr/local/bin/scripts:ro
VOL_CRON=./cron:/etc/cron.d:ro
VOL_DOCKER_SOCK=/var/run/docker.sock:/var/run/docker.sock
VOL_DOCKER_BIN=/usr/bin/docker:/usr/bin/docker:ro
VOL_LOCALTIME=/etc/localtime:/etc/localtime:ro
```

### Variáveis usadas no `docker-compose`

Além das variáveis acima, o `docker-compose.yml` também referencia variáveis de ambiente para integrações externas:

- `DB_TYPE`
- `DB_HOST`
- `DB_PORT`
- `DB_NAME`
- `DB_USER`
- `DB_PASS`
- `SMB_SHARE`
- `SMB_REMOTE_FILE`
- `SMB_USER`
- `SMB_PASS`

Se essas integrações forem necessárias no seu cenário, inclua essas chaves no `.env`.

## Volumes e Montagens

O serviço monta:

- `./scripts` em `/usr/local/bin/scripts`
- `./cron` em `/etc/cron.d`
- `/var/run/docker.sock` para coleta de dados do Docker host
- binário do Docker do host em `/usr/bin/docker`
- `/etc/localtime` para manter o timezone alinhado ao host

Isso permite editar scripts localmente e refletir as mudanças no container sem rebuild da imagem para cada ajuste de automação.

## Rede

O projeto espera uma rede Docker externa chamada `network-share`. O script [`prepare.sh`](/bskp-des/ctr-utils-des/prepare.sh) tenta criá-la automaticamente com subnet `172.18.0.0/16`.

Se preferir criar manualmente:

```bash
docker network create \
  --driver=bridge \
  --subnet=172.18.0.0/16 \
  network-share
```

## Qualidade e Segurança

O repositório inclui workflows em GitHub Actions para:

- build e smoke test da imagem Docker;
- lint do `Dockerfile` com Hadolint;
- validação de scripts shell com ShellCheck;
- análise de vulnerabilidades com Trivy no repositório e na imagem.

Arquivos relevantes:

- [ci-build.yml](/bskp-des/ctr-utils-des/.github/workflows/ci-build.yml)
- [hadolint.yml](/bskp-des/ctr-utils-des/.github/workflows/hadolint.yml)
- [shellcheck.yml](/bskp-des/ctr-utils-des/.github/workflows/shellcheck.yml)
- [trivy.yml](/bskp-des/ctr-utils-des/.github/workflows/trivy.yml)

## Observações Importantes

- Alguns scripts possuem valores fixos de host, nomes de containers e IPs do Zabbix, como `172.18.0.3`, `srv-nginx` e nomes específicos de containers monitorados. Para reutilizar o projeto em outro ambiente, revise esses parâmetros.
- O `.env.example` atual cobre a configuração principal do container, mas não documenta todas as variáveis opcionais consumidas por `docker-compose.yml` e por scripts de backup.
- O campo `SUBNET` no `.env.example` está definido como `172.18.0.16`, enquanto o script de preparação cria a rede com `172.18.0.0/16`. Vale manter esses valores consistentes no seu ambiente.
- O script `prepare.sh` tenta aplicar permissão com `chmod +x "$BASE_DIR/scripts/"*.sh`, mas boa parte dos scripts está em subpastas. Caso necessário, ajuste permissões recursivamente.

## Desenvolvimento

Para rebuild local da imagem:

```bash
docker build -t ctr-utils:local .
```

Para abrir um shell no container:

```bash
docker compose exec ctr-utils bash
```

## Licença

Este repositório não define uma licença explícita até o momento. Se o projeto for compartilhado publicamente, vale adicionar um arquivo `LICENSE`.
