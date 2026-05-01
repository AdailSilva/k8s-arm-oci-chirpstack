#!/bin/bash

# Deleting database before restore
# Login to psql again...
#DROP DATABASE database_name; # Replace: database_name

# Troubleshooting
# ERROR: database "database_name" is being accessed by other users
# DETAIL: There is 1 other session using the database.

# Revoke new connections to the database while performing the necessary procedures to delete it
#REVOKE CONNECT ON DATABASE database_name FROM public; # Replace: database_name

# Result: 
# REVOKE

#SELECT pg_terminate_backend(pg_stat_activity.pid) \
#FROM pg_stat_activity \
#WHERE pg_stat_activity.datname = 'database_name'; # Replace: database_name

# DROP database
#DROP DATABASE database_name; # Replace: database_name

# List databases:
#\l

# Exit database:
#\q


# RESTORE database commands:

# First, you must create a new empty database
#CREATE DATABASE database_name TEMPLATE template0; # Replace: database_name

#CREATE DATABASE postgres TEMPLATE template0;
#CREATE DATABASE chirpstack_ns TEMPLATE template0;
#CREATE DATABASE chirpstack_as TEMPLATE template0;
#CREATE DATABASE chirpstack TEMPLATE template0;


# Result: 
# CREATE DATABASE

# List databases:
#\l


# Database ChirpStack v4 restore on K8S
echo "Start restore ChirpStack-v4..."

# RESTORE database commands:

echo "Enter the password for postgres database Restore..."
#gunzip -c ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/00.UsefulScripts/_.backups/00.postgres__*.psql.gz | psql -h chirpstack-v4.adailsilva.com.br -p 5442 -U postgres -d postgres
gunzip -c ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/00.UsefulScripts/_.backups/00.postgres__*.psql.gz | psql --host chirpstack-v4.adailsilva.com.br --port 5442 --username postgres --dbname postgres


#(
#  cat <<EOF
#    -- Finaliza todas as conexões com o banco "chirpstack"
#    REVOKE CONNECT ON DATABASE chirpstack FROM public;
#    SELECT pg_terminate_backend(pid)
#    FROM pg_stat_activity
#    WHERE datname = 'chirpstack' AND pid <> pg_backend_pid();
#
#    -- Drop e criação do banco
#    DROP DATABASE IF EXISTS chirpstack;
#    CREATE DATABASE chirpstack;
#
#    -- Criação do usuário, se ainda não existir
#    DO \$\$
#    BEGIN
#      IF NOT EXISTS (
#        SELECT FROM pg_catalog.pg_roles WHERE rolname = 'chirpstack'
#      ) THEN
#        CREATE ROLE chirpstack LOGIN PASSWORD 'chirpstack';
#      END IF;
#    END
#    \$\$;
#
#    -- Concede permissões ao usuário.
#    GRANT ALL PRIVILEGES ON DATABASE chirpstack TO chirpstack;
#
#    -- Conecta ao banco.
#    \c chirpstack
#EOF
#
#  export PGPASSWORD=chirpstack
#
#  # Restore do dump
#  PGPASSWORD=chirpstack gunzip -c ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/00.UsefulScripts/_.backups/01.chirpstack-v4__*.psql.gz
#
#) | PGPASSWORD=postgres psql --host=chirpstack-v4.adailsilva.com.br --port=5442 --username=postgres --dbname=postgres


# Drop e recriação do banco + usuário.
PGPASSWORD=postgres psql --host=chirpstack-v4.adailsilva.com.br --port=5442 --username=postgres --dbname=postgres <<'EOF'
-- Finaliza conexões ativas.
REVOKE CONNECT ON DATABASE chirpstack FROM public;
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'chirpstack' AND pid <> pg_backend_pid();

-- Cria usuário, se necessário.
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'chirpstack') THEN
    CREATE ROLE chirpstack LOGIN PASSWORD 'chirpstack';
  END IF;
END$$;

-- Remove e recria banco.
DROP DATABASE IF EXISTS chirpstack;
CREATE DATABASE chirpstack OWNER chirpstack;

-- Permissões.
GRANT ALL PRIVILEGES ON DATABASE chirpstack TO chirpstack;

-- Garanta que o schema public existe.
CREATE SCHEMA IF NOT EXISTS public;

-- Conceda todas as permissões no schema public para o usuário chirpstack.
GRANT ALL ON SCHEMA public TO chirpstack;

-- Defina o dono do schema public para o usuário chirpstack.
ALTER SCHEMA public OWNER TO chirpstack;
  
EOF


export PGPASSWORD=chirpstack

echo "Enter the password for chirpstack database Restore..."
#PGPASSWORD=chirpstack gunzip -c ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/00.UsefulScripts/_.backups/01.chirpstack-v4__*.psql.gz | psql -h chirpstack-v4.adailsilva.com.br -p 5442 -U chirpstack -d chirpstack
PGPASSWORD=chirpstack gunzip -c ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/00.UsefulScripts/_.backups/01.chirpstack-v4__*.psql.gz | psql --host chirpstack-v4.adailsilva.com.br --port 5442 --username chirpstack --dbname chirpstack

echo "End restore ChirpStack-v4..."
