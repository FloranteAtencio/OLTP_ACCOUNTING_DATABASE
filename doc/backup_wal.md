docker exec -it erp_postgres ls -ld /var/lib/postgresql/wal_archive

docker exec -it erp_postgres \
ls -lh /var/lib/postgresql/wal_archive

docker exec -it erp_postgres \
  chown postgres:postgres /var/lib/postgresql/wal_archive

  docker exec -it erp_postgres \
  chmod 700 /var/lib/postgresql/wal_archive

  docker exec -it erp_postgres psql -U erp_admin -d erp_db \
-c "SELECT pg_switch_wal();"

docker logs erp_postgres