#!/bin/bash

# Configurações do banco de dados.
DB_NAME="chirpstack_manager"
DB_USER="postgres"
DB_PASSWORD="chirpstack-manager"
DB_HOST="localhost"  # Substitua pelo endereço do servidor.
DB_PORT="15435"  # Altere para a porta desejada.
BACKUP_DIR="~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/06.chirpstack_manager/backups"  # Substitua pelo caminho desejado.
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_$(date +%Y%m%d%H%M%S).sql"

# Exporta a senha do PostgreSQL para uso no pg_dump.
export PGPASSWORD=$DB_PASSWORD

# Cria o diretório de backup, se não existir.
mkdir -p $BACKUP_DIR

# Realiza o backup com host e porta especificados.
pg_dump -U $DB_USER -d $DB_NAME -h $DB_HOST -p $DB_PORT -F c -b -v -f $BACKUP_FILE

# Verifica se o backup foi bem-sucedido.
if [ $? -eq 0 ]; then
  echo "Backup realizado com sucesso: $BACKUP_FILE"
else
  echo "Falha ao realizar o backup!"
  exit 1
fi

# Remove a senha do ambiente.
unset PGPASSWORD

