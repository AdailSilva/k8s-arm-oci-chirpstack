#!/bin/bash

# Requires permissions
# pg_dump database_name > backup_name

# Verify database owner
#sudo psql -h k8s.adailsilva.com.br -p 5442 -U postgres -W postgres -d postgres connect_timeout=10
#sudo psql --host k8s.adailsilva.com.br --port 5442 --username postgres --password postgres --dbname postgres connect_timeout=10

#sudo psql -h chirpstack-v4.adailsilva.com.br -p 5442 -U chirpstack -W chirpstack -d chirpstack connect_timeout=10
#sudo psql --host chirpstack-v4.adailsilva.com.br --port 5442 --username chirpstack --password chirpstack --dbname chirpstack connect_timeout=10


# List databases:
#\l

# Exit database:
#\q


# How to pass in password to pg_dump?

# Create a .pgpass file in the home directory of the account that pg_dump will run as.
# The format is:
# hostname:port:database:username:password

# sudo nano .pgpass
# k8s.adailsilva.com.br:5442:posgres:posgres:posgres
# chirpstack-v4.adailsilva.com.br:5442:chirpstack:chirpstack:chirpstack

# Then, set the file's mode to 0600. Otherwise, it will be ignored.
# chmod 600 ~/.pgpass
# chmod 600 ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/00.UsefulScripts

# See the Postgresql documentation libpq-pgpass for more details.

# Check contents of backup files
#cat ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/00.UsefulScripts/_.backups/00.postgres__*.psql.gz | less
#cat ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/00.UsefulScripts/_.backups/01.chirpstack-v4__*.psql.gz | less


# Database ChirpStack v4 back-up on K8S
echo "Start back-up ChirpStack-v4..."

# Back-UP database commands:

echo "Enter the password for postgres database Back-UP..."
#sudo pg_dump -h chirpstack-v4.adailsilva.com.br -p 5442 -U postgres -d postgres --no-owner | gzip > ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/00.UsefulScripts/_.backups/00.postgres__$(date +%Y-%m-%d).psql.gz
sudo pg_dump --host chirpstack-v4.adailsilva.com.br --port 5442 --username postgres --dbname postgres --no-owner | gzip > ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/00.UsefulScripts/_.backups/00.postgres__$(date +%Y-%m-%d).psql.gz

echo "Enter the password for chirpstack database Back-UP..."
#sudo pg_dump -h chirpstack-v4.adailsilva.com.br -p 5442 -U chirpstack -d chirpstack --no-owner | gzip > ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/00.UsefulScripts/_.backups/01.chirpstack-v4__$(date +%Y-%m-%d).psql.gz
sudo pg_dump --host chirpstack-v4.adailsilva.com.br --port 5442 --username chirpstack --dbname chirpstack --no-owner | gzip > ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/00.UsefulScripts/_.backups/01.chirpstack-v4__$(date +%Y-%m-%d).psql.gz

echo "End back-up ChirpStack-v4..."
