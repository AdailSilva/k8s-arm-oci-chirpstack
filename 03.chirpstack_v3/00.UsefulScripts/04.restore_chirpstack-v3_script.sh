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


# Database ChirpStack v3 restore on K8S.
echo "Start restore ChirpStack-v3..."

# RESTORE database commands:

echo "Enter the password for postgres database Restore..."
#gunzip -c ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/00.postgres__*.psql.gz | psql -h chirpstack-v3.adailsilva.com.br -p 5437 -U postgres -d postgres
gunzip -c ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/00.postgres__*.psql.gz | psql --host chirpstack-v3.adailsilva.com.br --port 5437 --username postgres --dbname postgres

echo "Enter the password for chirpstack_ns database Restore..."
#gunzip -c ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/01.chirpstack-v3_ns__*.psql.gz | psql -h chirpstack-v4.adailsilva.com.br -p 5437 -U chirpstack_ns -d chirpstack_ns
gunzip -c ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/01.chirpstack-v3_ns__*.psql.gz | psql --host chirpstack-v3.adailsilva.com.br --port 5437 --username chirpstack_ns --dbname chirpstack_ns

echo "Enter the password for chirpstack_as database Restore..."
#gunzip -c ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/02.chirpstack-v3_as__*.psql.gz | psql -h chirpstack-v3.adailsilva.com.br -p 5438 -U chirpstack_as -d chirpstack_as
gunzip -c ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/02.chirpstack-v3_as__*.psql.gz | psql --host chirpstack-v4.adailsilva.com.br --port 5438 --username chirpstack_as --dbname chirpstack_as

echo "End restore ChirpStack-v3..."
