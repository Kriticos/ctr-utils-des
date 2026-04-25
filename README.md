ctr-utils

Container utilitário em Docker para rotinas operacionais, monitoramento, coleta de métricas e execução de tarefas agendadas com cron.

O projeto foi estruturado para apoiar ambientes self-hosted com foco em automação operacional, integração com Zabbix, diagnósticos de rede, inspeção de certificados e rotinas auxiliares de backup.

Objetivo

Disponibilizar um container de apoio para operações de infraestrutura, centralizando scripts e utilitários técnicos em uma única imagem Docker.

Os principais cenários de uso são:

monitoramento de conectividade e desempenho de internet;
envio de métricas para Zabbix com zabbix_sender;
coleta de estatísticas de containers Docker;
inspeção e descoberta de certificados TLS;
execução centralizada de scripts shell via cron;
apoio operacional com utilitários de rede, banco e sistema.
Arquitetura

O container é baseado em Debian e executa o cron em foreground, mantendo a execução contínua das rotinas agendadas.

Os scripts são montados por volume em /usr/local/bin/scripts, permitindo versionamento direto no repositório e atualização operacional sem necessidade de alterar a estrutura da imagem a cada ajuste de script.

Principais Recursos
imagem Docker baseada em debian:bookworm;
ferramentas de rede e diagnóstico como curl, wget, ping, mtr, dnsutils, net-tools e speedtest;
cliente MySQL para operações administrativas;
integração com Docker host via /var/run/docker.sock;
execução de scripts agendados com cron;
integração com Zabbix para coleta e envio de métricas;
pipeline CI/CD implementada com GitHub Actions.
Estrutura do Projeto

```text
.
├── Dockerfile
├── docker-compose.yml
├── prepare.sh
├── cron/
│ └── cron
├── scripts/
│ ├── backup/
│ ├── certificados/
│ ├── logs/
│ ├── nginx/
│ ├── zabbix/
│ │ ├── containers/
│ │ └── speedtest/
│ └── entrypoint.sh
└── .github/workflows/
```

Componentes
Dockerfile

Responsável por instalar os pacotes base do ambiente, ferramentas auxiliares, speedtest da Ookla e zabbix_sender.

Entrypoint

O arquivo scripts/entrypoint.sh é responsável por:

registrar o aceite da licença do Speedtest na primeira execução;
garantir a existência do log do cron;
iniciar o cron em foreground.
Agendamentos

O arquivo cron/cron define atualmente as seguintes rotinas:

speedtest.sh a cada 10 minutos;
check_connectivity_level.sh a cada 1 minuto;
send_docker_stats.sh a cada 1 minuto;
clean_log.sh diariamente às 23:00.
Scripts Relevantes
scripts/zabbix/speedtest/speedtest.sh
scripts/zabbix/speedtest/check_connectivity_level.sh
scripts/zabbix/containers/send_docker_stats.sh
scripts/nginx/check_cert.sh
scripts/nginx/cert-days.sh
scripts/nginx/discovery-cert.sh
scripts/backup/backup_data.sh
scripts/backup/backup_databases.sh
scripts/logs/clean_log.sh
Requisitos
Docker
Docker Compose ou docker compose
acesso ao socket Docker do host
rede Docker externa network-share
Configuração
Arquivo .env

O arquivo .env.example contém a configuração base do serviço.

Exemplo:

```env
SRV_NAME=ctr-utils
RELEASE=blackskulp/ctr-utils:latest
NETWORK_NAME=network-share
CONTAINER_IP=172.18.0.70
SUBNET=172.18.0.0/16
VOL_SCRIPTS=./scripts:/usr/local/bin/scripts:ro
VOL_CRON=./cron:/etc/cron.d:ro
VOL_DOCKER_SOCK=/var/run/docker.sock:/var/run/docker.sock
VOL_DOCKER_BIN=/usr/bin/docker:/usr/bin/docker:ro
VOL_LOCALTIME=/etc/localtime:/etc/localtime:ro
```

Variáveis adicionais

O docker-compose.yml também pode consumir variáveis adicionais para integrações externas, como:

DB_TYPE
DB_HOST
DB_PORT
DB_NAME
DB_USER
DB_PASS
SMB_SHARE
SMB_REMOTE_FILE
SMB_USER
SMB_PASS

Quando aplicável, essas variáveis devem ser incluídas no arquivo .env.

Uso
Preparação do ambiente

```bash
cp .env.example .env
```

Ajuste os valores conforme o seu ambiente.

Se desejar automatizar a preparação inicial:

```bash
./prepare.sh
```

Subida do container

```bash
docker compose up -d --build
```

Verificação

```bash
docker compose ps
docker compose logs -f ctr-utils
```

Volumes e Montagens

O serviço utiliza as seguintes montagens principais:

./scripts em /usr/local/bin/scripts
./cron em /etc/cron.d
/var/run/docker.sock para integração com Docker host
/usr/bin/docker a partir do host
/etc/localtime para alinhamento de timezone

Essa estratégia permite manter os scripts desacoplados da imagem e facilita ajustes operacionais.

Rede

O projeto utiliza uma rede Docker externa chamada network-share.

O script prepare.sh pode criar essa rede automaticamente com a subnet configurada.

Criação manual:

```bash
docker network create
--driver=bridge
--subnet 172.18.0.0/16
network-share
```

Pipeline CI/CD

O repositório possui pipeline implementada em GitHub Actions para validação, publicação e entrega da imagem.

Etapa de CI

Os workflows de integração contínua cobrem:

lint do Dockerfile com Hadolint;
validação de scripts shell com ShellCheck;
análise de segurança com Trivy;
build e smoke test da imagem;
validação estrutural do docker-compose.yml;
smoke test do docker compose.

Workflows relacionados:

.github/workflows/hadolint.yml
.github/workflows/shellcheck.yml
.github/workflows/trivy.yml
.github/workflows/ci-build.yml
.github/workflows/compose-validate.yml
.github/workflows/compose-smoke-test.yml
Etapa de Publish

A imagem é publicada no GitHub Container Registry (GHCR) com versionamento por tag.

Exemplos de tags geradas:

latest
1.0.1
1.0
1
sha-<commit>

Workflow relacionado:

.github/workflows/publish-image.yml
Etapa de Deploy e Rollback

O deploy é executado manualmente por workflow, utilizando self-hosted runner.

O fluxo permite:

deploy de uma versão específica;
rollback para uma tag anterior da imagem;
validação básica pós-deploy para confirmar que o container permaneceu em execução.

Workflow relacionado:

.github/workflows/deploy-image.yml
Desenvolvimento
Build local

```bash
docker build -t ctr-utils:local .
```

Acesso ao container

```bash
docker compose exec ctr-utils bash
```

Observações
Alguns scripts possuem parâmetros fixos de ambiente, como IPs, nomes de containers e referências específicas de Zabbix.
O .env.example deve permanecer consistente com as variáveis efetivamente usadas no docker-compose.yml.
O valor de SUBNET deve permanecer alinhado com a rede criada no ambiente.
O prepare.sh pode exigir ajustes caso seja necessário aplicar permissões em subpastas de scripts/.