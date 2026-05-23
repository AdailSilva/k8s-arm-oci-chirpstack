#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE ROLE chirpstack_as WITH LOGIN PASSWORD 'chirpstack_as' NOINHERIT;
    CREATE DATABASE chirpstack_as WITH OWNER chirpstack_as;
    \connect chirpstack_as
    GRANT ALL PRIVILEGES ON DATABASE chirpstack_as TO chirpstack_as;
EOSQL

# kubectl exec -it pods/chirpstack-v3-postgresql-deployment-78644666ff-4j6vn -n chirpstack-v3 -- /bin/sh
# psql -U postgres -d postgres
