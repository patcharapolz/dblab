DROP TABLE IF EXISTS supergame;
CREATE TABLE
    supergame (
        player_id INT,
        player_name VARCHAR(100),
        player_email VARCHAR(100),
        player_level VARCHAR(50),
        player_rank VARCHAR(50),
        player_country VARCHAR(50),
        total_spend DECIMAL(10, 2),
        item_purchased VARCHAR(100),
        item_price DECIMAL(10, 2),
        quest_completed VARCHAR(100),
        event_participated VARCHAR(100),
        item_category VARCHAR(50)
    );

-- เพิ่มข้อมูลรายการที่ 1
INSERT INTO
    supergame (
        player_id,
        player_name,
        player_email,
        player_level,
        player_rank,
        player_country,
        total_spend,
        item_purchased,
        item_price,
        quest_completed,
        event_participated,
        item_category
    )
VALUES
    (
        1,
        'John',
        'john@email.com',
        'Beginner',
        'Bronze',
        'Thailand',
        150.00,
        'Sword',
        100.00,
        'The First Challenge',
        'The Awakening Tournament',
        'Weapon'
    );
-- เพิ่มข้อมูลรายการที่ 2
INSERT INTO supergame (player_id, player_name, player_email, player_level, player_rank, player_country, total_spend, item_purchased, item_price, quest_completed, event_participated, item_category)
VALUES
(1, 'John', 'john@email.com', 'Beginner', 'Bronze', 'Thailand', 150.00, 'Shield', 50.00, 'Guardian’s Test', 'The Battle for Glory', 'Armor');

-- เพิ่มข้อมูลรายการที่ 3
INSERT INTO supergame (player_id, player_name, player_email, player_level, player_rank, player_country, total_spend, item_purchased, item_price, quest_completed, event_participated, item_category)
VALUES
(2, 'Alice', 'alice@email.com', 'Intermediate', 'Silver', 'USA', 220.00, 'Bow', 120.00, 'The Lost Treasure', 'The Awakening Tournament', 'Weapon');

-- เพิ่มข้อมูลรายการที่ 4
INSERT INTO supergame (player_id, player_name, player_email, player_level, player_rank, player_country, total_spend, item_purchased, item_price, quest_completed, event_participated, item_category)
VALUES
(2, 'Alice', 'alice@email.com', 'Intermediate', 'Silver', 'USA', 220.00, 'Arrow', 30.00, 'The Lost Treasure', 'The Eternal Quest', 'Weapon');

-- เพิ่มข้อมูลรายการที่ 5
INSERT INTO supergame (player_id, player_name, player_email, player_level, player_rank, player_country, total_spend, item_purchased, item_price, quest_completed, event_participated, item_category)
VALUES
(2, 'Alice', 'alice@email.com', 'Intermediate', 'Silver', 'USA', 220.00, 'Helmet', 70.00, 'The Lost Treasure', 'The Awakening Tournament', 'Armor');

-- เพิ่มข้อมูลรายการที่ 6
INSERT INTO supergame (player_id, player_name, player_email, player_level, player_rank, player_country, total_spend, item_purchased, item_price, quest_completed, event_participated, item_category)
VALUES
(3, 'Bob', 'bob@email.com', 'Expert', 'Gold', 'UK', 300.00, 'Sword', 100.00, 'Guardian’s Test', 'The Battle for Glory', 'Weapon');

-- เพิ่มข้อมูลรายการที่ 7
INSERT INTO supergame (player_id, player_name, player_email, player_level, player_rank, player_country, total_spend, item_purchased, item_price, quest_completed, event_participated, item_category)
VALUES
(3, 'Bob', 'bob@email.com', 'Expert', 'Gold', 'UK', 300.00, 'Sword', 100.00, 'Battle of the Ancients', 'The Battle for Glory', 'Weapon');

-- เพิ่มข้อมูลรายการที่ 8
INSERT INTO supergame (player_id, player_name, player_email, player_level, player_rank, player_country, total_spend, item_purchased, item_price, quest_completed, event_participated, item_category)
VALUES
(3, 'Bob', 'bob@email.com', 'Expert', 'Gold', 'UK', 300.00, 'Sword', 100.00, 'Victory’s Edge', 'The Battle for Glory', 'Weapon');

-- เริ่มทำ 2NF
DROP TABLE IF EXISTS players;
CREATE TABLE players (
    player_id INT PRIMARY KEY,
    player_name VARCHAR(100),
    player_email VARCHAR(100),
    player_level VARCHAR(50),
    player_rank VARCHAR(50),
    player_country VARCHAR(50),
    total_spend DECIMAL(10, 2)
);

-- ใช้ GROUP BY เพื่อรวมข้อมูล player_id และคำนวณ total_spend
INSERT INTO players (player_id, player_name, player_email, player_level, player_rank, player_country, total_spend)
SELECT
    player_id,
    player_name,  -- เลือก player_name สำหรับแต่ละ player_id
    player_email,        -- เลือก email สำหรับแต่ละ player_id
    player_level, -- เลือกระดับ player_level สำหรับแต่ละ player_id
    player_rank,  -- เลือก rank สำหรับแต่ละ player_id
    player_country, -- เลือก country สำหรับแต่ละ player_id
    SUM(item_price) as total_spend  -- รวมยอดใช้จ่ายทั้งหมดของแต่ละ player_id
FROM supergame
GROUP BY player_id, player_name, player_email, player_level, player_rank, player_country, total_spend;


DROP TABLE IF EXISTS item_purchases;
CREATE TABLE item_purchases (
    item_purchase_id SERIAL PRIMARY KEY,
    player_id INT,
    item_name VARCHAR(100),
    item_price DECIMAL(10, 2),
    quest_completed VARCHAR(100),
    event_participated VARCHAR(100),
    item_category VARCHAR(50)
);

INSERT INTO item_purchases (player_id, item_name, item_price
, quest_completed, event_participated, item_category)
SELECT
    player_id,
    item_purchased,
    item_price,
    quest_completed,
    event_participated,
    item_category
FROM supergame;


-- check 2NF

SELECT * FROM players;

SELECT * FROM item_purchases;

SELECT
    players.player_id,
    players.player_name,
    players.player_email,
    players.player_level,
    players.player_rank,
    players.player_country,
    players.total_spend,
    item_purchases.item_name,
    item_purchases.item_price,
    item_purchases.quest_completed ,
    item_purchases.event_participated ,
    item_purchases.item_category
FROM players JOIN item_purchases ON players.player_id=item_purchases.player_id
ORDER BY players.player_id,
    players.player_name;

-- เริ่มทำ 3NF
DROP TABLE IF EXISTS items;
CREATE TABLE items (
    item_id SERIAL PRIMARY KEY,           -- ใช้ SERIAL เพื่อให้มีค่าหมายเลขอัตโนมัติ
    item_name VARCHAR(100) NOT NULL,      -- ชื่อไอเทม
    item_category VARCHAR(50),            -- ประเภทของไอเทม (เช่น Weapon, Armor)
    item_price DECIMAL(10, 2) NOT NULL    -- ราคาของไอเทม
);
INSERT INTO items (item_name, item_category, item_price)
SELECT DISTINCT item_purchased, item_category, item_price
FROM supergame;

SELECT * FROM items;

DROP TABLE IF EXISTS quests;
CREATE TABLE quests (
    quest_id SERIAL PRIMARY KEY,             -- ใช้ SERIAL เพื่อให้ quest_id เป็นหมายเลขอัตโนมัติ
    quest_name VARCHAR(100) NOT NULL         -- ชื่อของเควสต์ (quest)
);
INSERT INTO quests (quest_name)
SELECT DISTINCT quest_completed
FROM supergame;

SELECT * FROM quests;

DROP TABLE IF EXISTS events;
CREATE TABLE events (
    event_id SERIAL PRIMARY KEY,            -- ใช้ SERIAL เพื่อสร้างหมายเลขอัตโนมัติสำหรับ event_id
    event_name VARCHAR(100) NOT NULL         -- ชื่อของเหตุการณ์ (event)
);
INSERT INTO events (event_name)
SELECT DISTINCT event_participated
FROM supergame;

SELECT * FROM events;

DROP TABLE IF EXISTS item_purchases;
CREATE TABLE item_purchases (
    item_purchase_id SERIAL PRIMARY KEY,
    player_id INT,
    item_id INT,
    quest_id INT,                            -- เพิ่มคอลัมน์ quest_id ที่เชื่อมโยงกับตาราง quests
    event_id INT,                            -- เพิ่มคอลัมน์ event_id ที่เชื่อมโยงกับตาราง events
    FOREIGN KEY (item_id) REFERENCES items(item_id),     -- เชื่อมโยงกับ items
    FOREIGN KEY (quest_id) REFERENCES quests(quest_id),  -- เชื่อมโยงกับ quests
    FOREIGN KEY (event_id) REFERENCES events(event_id) -- เชื่อมโยงกับ events
);

INSERT INTO
    item_purchases (player_id, item_id, quest_id, event_id)
SELECT
    supergame.player_id,
    items.item_id,
    quests.quest_id,
    events.event_id
FROM
    supergame
    JOIN items ON items.item_name = supergame.item_purchased
    JOIN quests ON quests.quest_name = supergame.quest_completed
    JOIN events ON events.event_name = supergame.event_participated
ORDER BY
    supergame.player_id;

SELECT * FROM item_purchases;


-- Workshop

SELECT * FROM supergame;

SELECT * FROM item_purchases;

-- check players with item
SELECT
    players.player_id,
    players.player_name,
    items.item_name,
    items.item_price,
    items.item_category
FROM
    item_purchases
    JOIN players ON item_purchases.player_id = players.player_id
    JOIN items ON item_purchases.item_id = items.item_id
ORDER BY
    players.player_id;

-- check item players with event
SELECT
    players.player_id,
    players.player_name,
    events.event_id,
    events.event_name AS event_participated
FROM
    item_purchases
    JOIN players ON item_purchases.player_id = players.player_id
    JOIN events ON item_purchases.event_id = events.event_id
ORDER BY
    players.player_id;

-- check player with quests
SELECT
    players.player_id,
    players.player_name,
    quests.quest_id,
    quests.quest_name AS quest_completed
FROM
    item_purchases
    JOIN players ON item_purchases.player_id = players.player_id
    JOIN quests ON item_purchases.quest_id = quests.quest_id
ORDER BY
    players.player_id;

-- Which player purchased Sheild, and which quest they purchased?
SELECT
    p.player_name,
    q.quest_name
FROM
    item_purchases ip
    JOIN players p ON ip.player_id = p.player_id
    JOIN quests q ON ip.quest_id = q.quest_id
    JOIN items i ON ip.item_id = i.item_id
WHERE
    i.item_name = 'Shield';

-- How man items purchases by players
SELECT
    players.player_id,
    players.player_name,
    COUNT(items.item_id) AS item_count
FROM
    item_purchases
    JOIN players ON item_purchases.player_id = players.player_id
    JOIN items ON item_purchases.item_id = items.item_id
GROUP BY
    players.player_id
ORDER BY
    players.player_id;

-- check item players with event
SELECT players.player_id,
    players.player_name,
    COUNT(DISTINCT events.event_id)  AS event_count
FROM item_purchases 
    JOIN players ON item_purchases.player_id=players.player_id
    JOIN events ON item_purchases.event_id=events.event_id
GROUP BY players.player_id
ORDER BY 
    players.player_id
;

-- How man quests played by user
SELECT players.player_id,
    players.player_name,
    COUNT(DISTINCT quests.quest_id)  AS quest_count
FROM item_purchases 
    JOIN players ON item_purchases.player_id=players.player_id
    JOIN quests ON item_purchases.quest_id=quests.quest_id
GROUP BY players.player_id
ORDER BY 
    players.player_id
;


-- ASSIGNMENT
INSERT INTO players (
    player_id,
    player_name, 
    player_email, 
    player_level, 
    player_rank, 
    player_country, 
    total_spend
) 
VALUES (
    (SELECT COALESCE(MAX(player_id), 0) + 1 FROM players),  -- auto-increment player_id
    'James', 
    'james@email.com', 
    'Beginner', 
    'Bronze', 
    'Japan', 
    0.00
);
INSERT INTO events (event_name)
VALUES ('The Final Stand');

INSERT INTO quests (quest_name)
VALUES 
    ('Gather the Fallen Relics'),
    ('Prepare for the Final Battle'),
    ('Unite the Forces');

INSERT INTO items (item_name, item_category, item_price)
VALUES ('Magic Sword', 'Weapon', 150.00);

INSERT INTO items (item_name, item_category, item_price)
VALUES ('Healing Potion', 'Consumable', 50.00);

ALTER TABLE item_purchases
ADD COLUMN play_time INTERVAL;

UPDATE item_purchases
SET play_time = '45 minutes';

INSERT INTO item_purchases (player_id, item_id, quest_id, event_id, play_time)
VALUES
    (4, 6, 6, 4, '30 minutes'),  -- Purchase "Magic Sword" for 'Gather the Fallen Relics'
    (4, 7, 7, 4, '30 minutes'),  -- Purchase "Healing Potion" for 'Prepare for the Final Battle'
    (4, 6, 8, 4, '30 minutes');  -- Purchase "Magic Sword" for 'Unite the Forces'

UPDATE players
SET total_spend = (
    SELECT SUM(i.item_price)
    FROM item_purchases ip
    JOIN items i ON ip.item_id = i.item_id
    WHERE ip.player_id = 4
)
WHERE player_id = 4;

-- The Final Stand
SELECT 
    item_purchases.player_id,
    players.player_name,
    players.player_email,
    players.player_level,
    players.player_rank,
    players.player_country,
    players.total_spend,
    items.item_name AS items_purchased,
    items.item_price,
    items.item_category,
    quests.quest_name AS quest_completed,
    events.event_name AS event_participated,
    item_purchases.play_time
FROM item_purchases
JOIN players ON item_purchases.player_id = players.player_id
JOIN items ON item_purchases.item_id = items.item_id
JOIN quests ON item_purchases.quest_id = quests.quest_id
JOIN events ON item_purchases.event_id = events.event_id
ORDER BY  item_purchases.player_id, players.player_name;
