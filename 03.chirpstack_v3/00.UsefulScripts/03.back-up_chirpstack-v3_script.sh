#!/bin/bash

# Requires permissions
# pg_dump database_name > backup_name

# Verify database owner
#sudo psql -h k8s.adailsilva.com.br -p 5432 -U postgres -W postgres -d postgres connect_timeout=10
#sudo psql --host k8s.adailsilva.com.br --port 5432 --username postgres --password postgres --dbname postgres connect_timeout=10

#sudo psql -h chirpstack-v3.adailsilva.com.br -p 5432 -U chirpstack_ns -W chirpstack_ns -d chirpstack_ns connect_timeout=10
#sudo psql --host chirpstack-v3.adailsilva.com.br --port 5432 --username chirpstack_ns --password chirpstack_ns --dbname chirpstack_ns connect_timeout=10

#sudo psql -h chirpstack-v3.adailsilva.com.br -p 5432 -U chirpstack_as -W chirpstack_as -d chirpstack_as connect_timeout=10
#sudo psql --host chirpstack-v3.adailsilva.com.br --port 5432 --username chirpstack_as --password chirpstack_as --dbname chirpstack_as connect_timeout=10


# List databases:
#\l

# Exit database:
#\q


# How to pass in password to pg_dump?

# Create a .pgpass file in the home directory of the account that pg_dump will run as.
# The format is:
# hostname:port:database:username:password

# sudo nano .pgpass
# k8s.adailsilva.com.br:5432:posgres:posgres:posgres
# chirpstack-v3.adailsilva.com.br:5432:chirpstack_ns:chirpstack_ns:chirpstack_ns
# chirpstack-v3.adailsilva.com.br:5432:chirpstack_as:chirpstack_as:chirpstack_as

# Then, set the file's mode to 0600. Otherwise, it will be ignored.
# chmod 600 ~/.pgpass
# chmod 600 ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts

# See the Postgresql documentation libpq-pgpass for more details.

# Check contents of backup files
#cat ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/00.postgres__*.psql.gz | less
#cat ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/01.chirpstack-v3_ns__*.psql.gz | less
#cat ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/02.chirpstack-v3_as__*.psql.gz | less


# Database ChirpStack v3 back-up on K8S.
echo "Start back-up ChirpStack-v3..."

# Back-UP database commands:

echo "Enter the password for postgres database Back-UP..."
#sudo pg_dump -h chirpstack-v3.adailsilva.com.br -p 5437 -U postgres -d postgres --no-owner | gzip > ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/00.postgres__$(date +%Y-%m-%d).psql.gz
sudo pg_dump --host chirpstack-v3.adailsilva.com.br --port 5437 --username postgres --dbname postgres --no-owner | gzip > ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/00.postgres__$(date +%Y-%m-%d).psql.gz

echo "Enter the password for chirpstack_ns database Back-UP..."
#sudo pg_dump -h chirpstack-v3.adailsilva.com.br -p 5437 -U chirpstack_ns -d chirpstack_ns --no-owner | gzip > ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/01.chirpstack-v3_ns__$(date +%Y-%m-%d).psql.gz
sudo pg_dump --host chirpstack-v3.adailsilva.com.br --port 5437 --username chirpstack_ns --dbname chirpstack_ns --no-owner | gzip > ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/01.chirpstack-v3_ns__$(date +%Y-%m-%d).psql.gz

echo "Enter the password for chirpstack_as database Back-UP..."
#sudo pg_dump -h chirpstack-v3.adailsilva.com.br -p 5438 -U chirpstack_as -d chirpstack_as --no-owner | gzip > ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/02.chirpstack-v3_as__$(date +%Y-%m-%d).psql.gz
sudo pg_dump --host chirpstack-v3.adailsilva.com.br --port 5438 --username chirpstack_as --dbname chirpstack_as --no-owner | gzip > ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/00.UsefulScripts/_.backups/02.chirpstack-v3_as__$(date +%Y-%m-%d).psql.gz

echo "End back-up ChirpStack-v3..."
