-- CREATE TABLE account(
--     account_id serial PRIMARY KEY,
--     name text NOT NULL,
--     dob date
-- );

-- CREATE TABLE thread(
--     thread_id serial PRIMARY KEY,
--     account_id integer NOT NULL REFERENCES account(account_id),
--     title text NOT NULL
-- );

-- CREATE TABLE post(
--     post_id serial PRIMARY KEY,
--     thread_id integer NOT NULL REFERENCES thread(thread_id),
--     account_id integer NOT NULL REFERENCES account(account_id),
--     created timestamp with time zone NOT NULL DEFAULT now(),
--     visible boolean NOT NULL DEFAULT TRUE,
--     comment text NOT NULL
-- );

-- CREATE TABLE words (word TEXT) ;
-- \copy words (word) FROM '/usr/share/dict/words';

-- INSERT INTO account (name, dob)
-- SELECT
--     substring('AEIOU', (random()*4)::int + 1, 1) ||
--     substring('ctdrdwftmkndnfnjnknsntnyprpsrdrgrkrmrnzslstwl', (random()*22*2 + 1)::int, 2) ||
--     substring('aeiou', (random()*4 + 1)::int, 1) || 
--     substring('ctdrdwftmkndnfnjnknsntnyprpsrdrgrkrmrnzslstwl', (random()*22*2 + 1)::int, 2) ||
--     substring('aeiou', (random()*4 + 1):: int, 1),
--     Now() + ('1 days':: interval * random() * 365)
-- FROM generate_series (1, 100)
-- ;

-- INSERT INTO thread (account_id, title)
-- SELECT
--     RANDOM () * 99 + 1,
--     (
--         SELECT initcap(string_agg (word, ' '))
--         FROM (TABLE words ORDER BY random() * n LIMIT 5) AS words (word)
--     )
-- FROM generate_series (1, 1000) AS s(n)
-- ;

-- INSERT INTO post (thread_id, account_id, created, visible, comment)
-- SELECT
--     RANDOM () * 999 + 1,
-- 	RANDOM () * 99 + 1,
--     NOW() - ('1 days':: interval * random() * 1000),
--     CASE WHEN RANDOM() > 0.1 THEN TRUE ELSE FALSE END,
--         ( SELECT string_agg (word,' ') FROM (TABLE words ORDER BY random() * n LIMIT 20) AS words (word) )
-- FROM generate_series (1, 100000) AS s (n)
-- ;


SELECT
    t.table_name,
    pg_size_pretty(pg_total_relation_size('public.' || t.table_name)) AS total_size,
    pg_size_pretty(pg_indexes_size('public.' || t.table_name)) AS index_size,
    pg_size_pretty(pg_relation_size('public.' || t.table_name)) AS table_size,
    COALESCE(pg_class.reltuples::bigint, 0) AS num_rows
FROM
    information_schema.tables t
LEFT JOIN
    pg_class ON pg_class.relname = t.table_name
LEFT JOIN
    pg_namespace ON pg_namespace.oid = pg_class.relnamespace
WHERE
    t.table_schema = 'public'
    AND pg_namespace.nspname = 'public'
ORDER BY
    t.table_name ASC;

 table_name | total_size | index_size | table_size | num_rows 
------------+------------+------------+------------+----------
 account    | 32 kB      | 16 kB      | 8192 bytes |      100
 post       | 29 MB      | 2208 kB    | 27 MB      |   100000
 thread     | 168 kB     | 40 kB      | 96 kB      |     1000
 words      | 10024 kB   | 0 bytes    | 9984 kB    |   235976
(4 rows)


-- Query 1: See all my posts
EXPLAIN ANALYZE
SELECT * FROM post
WHERE account_id = 1
;

 Seq Scan on post  
    (cost=0.00..4660.00 rows=537 width=235) 
    (actual time=0.054..25.761 rows=499 loops=1)
        Filter: (account_id = 1)
        Rows Removed by Filter: 99501
 Planning Time: 0.280 ms
 Execution Time: 25.818 ms
(5 rows)

-- Query 2: How many post have i made?
EXPLAIN ANALYZE
SELECT COUNT(*) FROM post
WHERE account_id = 1;

 Aggregate  
    (cost=4661.34..4661.35 rows=1 width=8) 
    (actual time=26.337..26.338 rows=1 loops=1)
        ->  Seq Scan on post  
            (cost=0.00..4660.00 rows=537 width=0) 
            (actual time=0.087..26.282 rows=499 loops=1)
                Filter: (account_id = 1)
                Rows Removed by Filter: 99501
 Planning Time: 0.176 ms
 Execution Time: 26.392 ms
(6 rows)

-- Query 3: See all current posts for a Thread
EXPLAIN ANALYZE
SELECT * FROM post
WHERE thread_id = 1
AND visible = TRUE;

 Seq Scan on post  
    (cost=0.00..4660.00 rows=89 width=235) 
    (actual time=1.720..32.640 rows=56 loops=1)
        Filter: (visible AND (thread_id = 1))
        Rows Removed by Filter: 99944
 Planning Time: 0.204 ms
 Execution Time: 32.692 ms
(5 rows)

-- Query 4: How many posts have i made to a Thread?
EXPLAIN ANALYZE
SELECT COUNT(*)
FROM post
WHERE thread_id = 1 AND visible = TRUE AND account_id = 1;

 Aggregate  
    (cost=4910.00..4910.01 rows=1 width=8) 
    (actual time=32.196..32.196 rows=1 loops=1)
        ->  Seq Scan on post  
        (cost=0.00..4910.00 rows=1 width=0) 
        (actual time=32.185..32.185 rows=0 loops=1)
            Filter: (visible AND (thread_id = 1) AND (account_id = 1))
            Rows Removed by Filter: 100000
 Planning Time: 0.221 ms
 Execution Time: 32.253 ms
(6 rows)

-- Query 5: See all current posts for a Thread for this month, in order
EXPLAIN ANALYZE
SELECT *
FROM post
WHERE thread_id = 1 AND visible = TRUE AND created > NOW() - '1 month'::interval
ORDER BY created;

 Gather Merge  (cost=5243.37..5243.60 rows=2 width=235) (actual time=10.969..13.418 rows=1 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Sort  (cost=4243.34..4243.35 rows=1 width=235) (actual time=7.555..7.556 rows=0 loops=3)
         Sort Key: created
         Sort Method: quicksort  Memory: 25kB
         Worker 0:  Sort Method: quicksort  Memory: 25kB
         Worker 1:  Sort Method: quicksort  Memory: 25kB
         ->  Parallel Seq Scan on post  
            (cost=0.00..4243.33 rows=1 width=235) (actual time=5.802..7.495 rows=0 loops=3)
               Filter: (visible AND (thread_id = 1) AND (created > (now() - '1 mon'::interval)))
               Rows Removed by Filter: 33333
 Planning Time: 0.241 ms
 Execution Time: 13.443 ms
(13 rows)


----- INDEX -----
CREATE INDEX ON post(account_id);
 table_name | total_size | index_size | table_size | num_rows 
------------+------------+------------+------------+----------
 account    | 32 kB      | 16 kB      | 8192 bytes |      100
 post       | 30 MB      | 2936 kB    | 27 MB      |   100000
 thread     | 168 kB     | 40 kB      | 96 kB      |     1000
 words      | 10024 kB   | 0 bytes    | 9984 kB    |   235976
-- Query 1: See all my posts with Index
EXPLAIN ANALYZE
SELECT * FROM post
WHERE account_id = 1
;

Bitmap Heap Scan on post  
    (cost=8.45..1436.23 rows=537 width=235) 
    (actual time=0.311..1.669 rows=499 loops=1)
    Recheck Cond: (account_id = 1)
    Heap Blocks: exact=464
        ->  Bitmap Index Scan on post_account_id_idx  
            (cost=0.00..8.32 rows=537 width=0) 
            (actual time=0.226..0.227 rows=499 loops=1)
                Index Cond: (account_id = 1)    
 Planning Time: 0.560 ms
 Execution Time: 1.743 ms
(7 rows)

-- Query 2: How many post have i made? with index
EXPLAIN ANALYZE
SELECT COUNT(*) FROM post
WHERE account_id = 1;

Aggregate  
    (cost=15.03..15.04 rows=1 width=8) 
    (actual time=0.202..0.203 rows=1 loops=1)
    ->  Index Only Scan using post_account_id_idx on post  
        (cost=0.29..13.69 rows=537 width=0) 
        (actual time=0.103..0.157 rows=499 loops=1)
            Index Cond: (account_id = 1)
            Heap Fetches: 0
 Planning Time: 0.248 ms
 Execution Time: 0.297 ms
(6 rows)

-- CREATE another index
CREATE INDEX ON post (thread_id);
 table_name | total_size | index_size | table_size | num_rows 
------------+------------+------------+------------+----------
 account    | 32 kB      | 16 kB      | 8192 bytes |      100
 post       | 30 MB      | 3656 kB    | 27 MB      |   100000
 thread     | 168 kB     | 40 kB      | 96 kB      |     1000
 words      | 10024 kB   | 0 bytes    | 9984 kB    |   235976

-- Query 3: See all current posts for a Thread with index
EXPLAIN ANALYZE
SELECT * FROM post
WHERE thread_id = 1
AND visible = TRUE;

Bitmap Heap Scan on post  
    (cost=5.06..348.45 rows=89 width=235) 
    (actual time=0.203..0.382 rows=56 loops=1)
        Recheck Cond: (thread_id = 1)
        Filter: visible
        Rows Removed by Filter: 6
        Heap Blocks: exact=62
        ->  Bitmap Index Scan on post_thread_id_idx  
            (cost=0.00..5.04 rows=99 width=0) 
            (actual time=0.111..0.111 rows=62 loops=1)
                Index Cond: (thread_id = 1)
 Planning Time: 0.678 ms
 Execution Time: 0.429 ms
(9 rows)

-- Query 4: How many posts have i made to a Thread? with index
EXPLAIN ANALYZE
SELECT COUNT(*)
FROM post
WHERE thread_id = 1 AND visible = TRUE AND account_id = 1;

Aggregate  
    (cost=17.62..17.63 rows=1 width=8) 
    (actual time=0.154..0.156 rows=1 loops=1)
    ->  Bitmap Heap Scan on post  
        (cost=13.61..17.62 rows=1 width=0) 
        (actual time=0.145..0.146 rows=0 loops=1)
            Recheck Cond: ((thread_id = 1) AND (account_id = 1))
            Filter: visible
            ->  BitmapAnd  
                (cost=13.61..13.61 rows=1 width=0) 
                (actual time=0.135..0.136 rows=0 loops=1)
                    ->  Bitmap Index Scan on post_thread_id_idx  
                        (cost=0.00..5.04 rows=99 width=0) 
                        (actual time=0.060..0.061 rows=62 loops=1)
                            Index Cond: (thread_id = 1)
                    ->  Bitmap Index Scan on post_account_id_idx  
                        (cost=0.00..8.32 rows=537 width=0) 
                        (actual time=0.069..0.069 rows=499 loops=1)
                            Index Cond: (account_id = 1)
 Planning Time: 0.308 ms
 Execution Time: 0.226 ms
(11 rows)

CREATE INDEX ON post (thread_id, visible);
table_name | total_size | index_size | table_size | num_rows 
------------+------------+------------+------------+----------
 account    | 32 kB      | 16 kB      | 8192 bytes |      100
 post       | 31 MB      | 4352 kB    | 27 MB      |   100000
 thread     | 168 kB     | 40 kB      | 96 kB      |     1000
 words      | 10024 kB   | 0 bytes    | 9984 kB    |   235976
(4 rows)

-- Query 3: See all current posts for a Thread with multiple indexes
EXPLAIN ANALYZE
SELECT * FROM post
WHERE thread_id = 1
AND visible = TRUE;

Bitmap Heap Scan on post  
    (cost=5.20..315.91 rows=89 width=235) 
    (actual time=0.062..0.205 rows=56 loops=1)
        Recheck Cond: ((thread_id = 1) AND visible)
        Heap Blocks: exact=56
        ->  Bitmap Index Scan on post_thread_id_visible_idx  
            (cost=0.00..5.18 rows=89 width=0) 
            (actual time=0.044..0.045 rows=56 loops=1)
                Index Cond: ((thread_id = 1) AND (visible = true))
 Planning Time: 0.565 ms
 Execution Time: 0.230 ms
(7 rows)


-- Query 4: How many posts have i made to a Thread? with multiple indexes
EXPLAIN ANALYZE
SELECT COUNT(*)
FROM post
WHERE thread_id = 1 AND visible = TRUE AND account_id = 1;

  Aggregate  (cost=17.41..17.42 rows=1 width=8) (actual time=0.187..0.188 rows=1 loops=1)
   ->  Bitmap Heap Scan on post  (cost=13.40..17.41 rows=1 width=0) (actual time=0.179..0.179 rows=0 loops=1)
         Recheck Cond: ((thread_id = 1) AND (account_id = 1))
         Filter: visible
         ->  BitmapAnd  (cost=13.40..13.40 rows=1 width=0) (actual time=0.172..0.172 rows=0 loops=1)
               ->  Bitmap Index Scan on post_thread_id_idx  
               (cost=0.00..5.03 rows=98 width=0) (actual time=0.074..0.074 rows=62 loops=1)
                     Index Cond: (thread_id = 1)
               ->  Bitmap Index Scan on post_account_id_idx  
               (cost=0.00..8.12 rows=510 width=0) (actual time=0.091..0.091 rows=499 loops=1)
                     Index Cond: (account_id = 1)
 Planning Time: 0.512 ms
 Execution Time: 0.244 ms
(11 rows)


CREATE INDEX ON POST (thread_id, visible, account_id);

-- Query 4: How many posts have i made to a Thread? with multiple 3 indexes
EXPLAIN ANALYZE
SELECT COUNT(*)
FROM post
WHERE thread_id = 1 AND visible = TRUE AND account_id = 1;

 Aggregate  
 (cost=4.44..4.45 rows=1 width=8) 
 (actual time=0.056..0.058 rows=1 loops=1)
   ->  Index Only Scan using post_thread_id_visible_account_id_idx on post  
   (cost=0.42..4.44 rows=1 width=0) 
   (actual time=0.051..0.051 rows=0 loops=1)
         Index Cond: ((thread_id = 1) AND (visible = true) AND (account_id = 1))
         Heap Fetches: 0
 Planning Time: 1.161 ms
 Execution Time: 0.098 ms
(6 rows)


-- Add indexes name to see detail about tables and indexes
CREATE INDEX ON post(thread_id, account_id)
WHERE visible = TRUE;

SELECT
    t.table_name,
    i.indexname AS index_name,
    COALESCE(pg_class.reltuples::bigint, 0) AS num_rows,
    pg_size_pretty(pg_relation_size('public.' || t.table_name)) AS table_size,
    pg_size_pretty(pg_relation_size('public.' || i.indexname)) AS index_size
FROM
    information_schema.tables t
JOIN
    pg_class ON pg_class.relname = t.table_name
JOIN
    pg_namespace ON pg_namespace.oid = pg_class.relnamespace
LEFT JOIN
    pg_indexes i ON i.tablename = t.table_name AND i.schemaname = t.table_schema
LEFT JOIN
    pg_class ic ON ic.relname = i.indexname
WHERE
    t.table_schema = 'public'
    AND pg_namespace.nspname = 'public'
    AND pg_class.relkind = 'r'  -- 'r' is for regular tables
ORDER BY
    t.table_name ASC, i.indexname;

 table_name |              index_name               | num_rows | table_size | index_size 
------------+---------------------------------------+----------+------------+------------
 account    | account_pkey                          |      100 | 8192 bytes | 16 kB
 post       | post_account_id_idx                   |   100000 | 27 MB      | 728 kB
 post       | post_pkey                             |   100000 | 27 MB      | 2208 kB
 post       | post_thread_id_account_id_idx         |   100000 | 27 MB      | 1768 kB
 post       | post_thread_id_idx                    |   100000 | 27 MB      | 720 kB
 post       | post_thread_id_visible_account_id_idx |   100000 | 27 MB      | 2608 kB
 post       | post_thread_id_visible_idx            |   100000 | 27 MB      | 696 kB
 thread     | thread_pkey                           |     1000 | 96 kB      | 40 kB
 words      |                                       |   235976 | 9984 kB    | 
(9 rows)

-- Partial Index
-- Query 4: How many posts have i made to a Thread? with partial indexes
EXPLAIN ANALYZE
SELECT COUNT(*)
FROM post
WHERE thread_id = 1 AND visible = TRUE AND account_id = 1;

 Aggregate  (cost=4.32..4.33 rows=1 width=8) (actual time=0.115..0.116 rows=1 loops=1)
   ->  Index Only Scan using post_thread_id_account_id_idx on post  
   (cost=0.29..4.31 rows=1 width=0) (actual time=0.047..0.047 rows=0 loops=1)
         Index Cond: ((thread_id = 1) AND (account_id = 1))
         Heap Fetches: 0
 Planning Time: 0.481 ms
 Execution Time: 0.156 ms
(6 rows)


-- Query 3: See all current posts for a Thread with partial indexes
EXPLAIN ANALYZE
SELECT * FROM post
WHERE thread_id = 1
AND visible = TRUE;

 Bitmap Heap Scan on post  (cost=4.97..312.39 rows=88 width=235) (actual time=0.049..0.251 rows=56 loops=1)
   Recheck Cond: ((thread_id = 1) AND visible)
   Heap Blocks: exact=56
   ->  Bitmap Index Scan on post_thread_id_account_id_idx  
   (cost=0.00..4.95 rows=88 width=0) (actual time=0.023..0.024 rows=56 loops=1)
         Index Cond: (thread_id = 1)
 Planning Time: 0.912 ms
 Execution Time: 0.293 ms
(7 rows)


-- Query 5: See all current posts for a Thread for this month, in order all indexes
EXPLAIN ANALYZE
SELECT *
FROM post
WHERE thread_id = 1 AND visible = TRUE AND created > NOW() - '1 month'::interval
ORDER BY created;

Sort  (cost=313.05..313.06 rows=3 width=235) (actual time=0.238..0.240 rows=1 loops=1)
   Sort Key: created
   Sort Method: quicksort  Memory: 25kB
   ->  Bitmap Heap Scan on post  
        (cost=4.95..313.02 rows=3 width=235) 
        (actual time=0.095..0.227 rows=1 loops=1)
            Recheck Cond: ((thread_id = 1) AND visible)
            Filter: (created > (now() - '1 mon'::interval))
            Rows Removed by Filter: 55
            Heap Blocks: exact=56
            ->  Bitmap Index Scan on post_thread_id_account_id_idx  
                (cost=0.00..4.95 rows=88 width=0) (actual time=0.030..0.030 rows=56 loops=1)
                Index Cond: (thread_id = 1)
 Planning Time: 0.861 ms
 Execution Time: 0.263 ms
(12 rows)

-- Add index for Query 5
CREATE INDEX ON post (thread_id, created)
WHERE visible = TRUE;

-- Query 5: See all current posts for a Thread for this month, in order specic index
EXPLAIN ANALYZE
SELECT *
FROM post
WHERE thread_id = 1 AND visible = TRUE AND created > NOW() - '1 month'::interval
ORDER BY created;

 Sort  (cost=16.27..16.28 rows=3 width=235) (actual time=0.054..0.054 rows=1 loops=1)
   Sort Key: created
   Sort Method: quicksort  Memory: 25kB
   ->  Bitmap Heap Scan on post  
    (cost=4.45..16.25 rows=3 width=235) (actual time=0.049..0.049 rows=1 loops=1)
         Recheck Cond: ((thread_id = 1) AND (created > (now() - '1 mon'::interval)) AND visible)
         Heap Blocks: exact=1
         ->  Bitmap Index Scan on post_thread_id_created_idx  
            (cost=0.00..4.45 rows=3 width=0) (actual time=0.044..0.044 rows=1 loops=1)
               Index Cond: ((thread_id = 1) AND (created > (now() - '1 mon'::interval)))
 Planning Time: 0.236 ms
 Execution Time: 0.067 ms
(10 rows)


-- CREATE INDEX for query 5 agent
CREATE INDEX on POST
   (array_length(regexp_split_to_array(comment, E'\\s+'), 1));
