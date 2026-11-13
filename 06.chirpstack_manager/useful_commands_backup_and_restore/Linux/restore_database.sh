#!/bin/bash

# Configurações do banco de dados.
DB_NAME="chirpstack_manager"
DB_USER="postgres"
DB_PASSWORD="chirpstack-manager"
DB_HOST="localhost"  # Substitua pelo endereço do servidor.
DB_PORT="15435"  # Substitua pela porta desejada.
BACKUP_FILE="~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/06.chirpstack_manager/backups/_.sql"  # Substitua pelo caminho do arquivo de backup.

# Exporta a senha do PostgreSQL para uso no pg_restore.
export PGPASSWORD=$DB_PASSWORD

# Restaura o banco de dados, incluindo host e porta.
pg_restore -U $DB_USER -d $DB_NAME -h $DB_HOST -p $DB_PORT -v -F c $BACKUP_FILE

# Verifica se o restore foi bem-sucedido.
if [ $? -eq 0 ]; then
  echo "Restauração realizada com sucesso!"
else
  echo "Falha ao realizar a restauração!"
  exit 1
fi

# Remove a senha do ambiente.
unset PGPASSWORD

