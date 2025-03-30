--1,  Create table ‘table_to_delete’ and fill it with the following query:
--this part was okay and table was created in short time 

--2, Lookup how much space this table consumes with the following query:
--total (this will show ALL bytes IN this table): 575MB
--table (just space of table without index and toast, just for entities and information of table): 575MB
--index (space of all indexs): 0MB
--toast(The Oversized-Attribute Storage Technique, so just oversized columns (even json, binary data, large objects)):8192 bytes
--row_estimate (numbers of rowsin table): 9,999,898
--total_bytes(space of table in bytes):602611712 = 602.611712
--index_bytes(size of indexs in table): 0
--toast_bytes: 8192


--3, Issue the following DELETE operation on ‘table_to_delete’:
--it took 19s to delete, time: 22:53:41 till 22:54:00
--but when i start query again, nothing changed in memory, all is the same

--4,Issue the following TRUNCATE operation:
-- this took 0,0013s 
--now, it has changed
--row_estimate: -1 
--total_bytes: 8192
--toas_bytes: 8192
--index_bytes: 0
--table and total is also: 8192 bytes


