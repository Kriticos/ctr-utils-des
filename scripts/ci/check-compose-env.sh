#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="docker-compose.yml"
ENV_EXAMPLE_FILE=".env.example"

if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "Erro: arquivo '$COMPOSE_FILE' não encontrado."
    exit 1
fi

if [[ ! -f "$ENV_EXAMPLE_FILE" ]]; then
    echo "Erro: arquivo '$ENV_EXAMPLE_FILE' não encontrado."
    exit 1
fi

echo "Lendo variáveis usadas em $COMPOSE_FILE..."
mapfile -t compose_vars < <(
    # shellcheck disable=SC2016
    grep -oE '\${[A-Za-z_][A-Za-z0-9_]*(:[-?][^}]*)?}' "$COMPOSE_FILE" \
    | sed -E 's/^\$\{([A-Za-z_][A-Za-z0-9_]*).*/\1/' \
    | sort -u
)

echo "Lendo variáveis definidas em $ENV_EXAMPLE_FILE..."
mapfile -t env_example_vars < <(
    grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$ENV_EXAMPLE_FILE" \
    | cut -d '=' -f 1 \
    | sort -u
)

if [[ ${#compose_vars[@]} -eq 0 ]]; then
    echo "Nenhuma variável encontrada em $COMPOSE_FILE."
    exit 0
fi

missing_vars=()

for var in "${compose_vars[@]}"; do
    if ! printf '%s\n' "${env_example_vars[@]}" | grep -qx "$var"; then
        missing_vars+=("$var")
    fi
done

echo
echo "Variáveis encontradas no compose:"
printf ' - %s\n' "${compose_vars[@]}"

echo
echo "Variáveis encontradas no .env.example:"
printf ' - %s\n' "${env_example_vars[@]}"

echo
if [[ ${#missing_vars[@]} -gt 0 ]]; then
    echo "Erro: as variáveis abaixo são usadas no docker-compose.yml, mas não existem no .env.example:"
    printf ' - %s\n' "${missing_vars[@]}"
    exit 1
fi

echo "Validação OK: todas as variáveis do docker-compose.yml existem no .env.example."