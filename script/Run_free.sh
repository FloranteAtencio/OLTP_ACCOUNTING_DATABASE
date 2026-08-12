docker-compose -f ./docker/docker-compose.prod.yml -p production up -d

docker exec -it erp_postgres chown postgres:postgres /var/lib/postgresql/wal_archive

docker exec -it erp_postgres chmod 700 /var/lib/postgresql/wal_archive

docker restart erp_postgres

docker exec -i erp_postgres psql -U erp_admin -d erp_db < ./tmp/DATA/data_sample.sql

docker exec -it erp_postgres ls -lh /var/lib/postgresql/wal_archive

