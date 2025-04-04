--1,  Create table ‘table_to_delete’ and fill it with the following query:
--this part was okay and table was created in short time, this took 28s

CREATE TABLE table_to_delete AS
               SELECT 'veeeeeeery_long_string' || x AS col
               FROM generate_series(1,(10^7)::int) x;

--2, Lookup how much space this table consumes with the following query: (i created again table and queries so here is some changes)
--total (this will show ALL bytes IN this table): 575MB
--table (just space of table without index and toast, just for entities and information of table): 575MB
--index (space of all indexs): 0MB
--toast(The Oversized-Attribute Storage Technique, so just oversized columns (even json, binary data, large objects)):8192 bytes
--row_estimate (numbers of rowsin table): 9,999,898
--total_bytes(space of table in bytes):602415104 = 602.415104
--index_bytes(size of indexs in table): 0
--toast_bytes: 8192

  SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';


--3, Issue the following DELETE operation on ‘table_to_delete’:
--it took 19s to delete, time: 22:53:41 till 22:54:00
--but when i start query again, nothing changed in memory, all is the same
  --just row_estimated : -1

  DELETE FROM table_to_delete
               WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;
  
  --i did drop to and recreated table again
  
  DROP TABLE IF EXISTS table_to_delete;
  
  
--4,Issue the following TRUNCATE operation:
-- this took 0,371s 
--now, it has changed
--row_estimate: -1 
--total_bytes: 8192
--toas_bytes: 8192
--index_bytes: 0
--table and total is also: 8192 bytes
  
   TRUNCATE table_to_delete;


