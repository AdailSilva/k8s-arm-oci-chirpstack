#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE ROLE chirpstack_ns WITH LOGIN PASSWORD 'chirpstack_ns' NOINHERIT;
    CREATE DATABASE chirpstack_ns WITH OWNER chirpstack_ns;
    \connect chirpstack_ns
    GRANT ALL PRIVILEGES ON DATABASE chirpstack_ns TO chirpstack_ns;
EOSQL

# kubectl exec -it pods/chirpstack-v3-postgresql-deployment-78644666ff-4j6vn -n chirpstack-v3 -- /bin/sh
# psql -U postgres -d postgres
