-- Step 1: CREATE bank_accounts table
CREATE TABLE bank_accounts (
    account_id SERIAL PRIMARY KEY,
    balance DECIMAL(10, 2) NOT NULL
);

-- Step 2: Insert Test Data
INSERT INTO bank_accounts (balance) VALUES (1000.00);


-- Terminal 1 : Withdraw 200.-
BEGIN;

-- Lock the row for account_id 1
SELECT * FROM bank_accounts WHERE account_id = 1 FOR UPDATE;

-- Add delay (simulate time-consuming operation)
SELECT pg_sleep(20);  -- Sleep for 10 seconds

-- Withdraw $200 from account 1
UPDATE bank_accounts
SET balance = balance - 200.00
WHERE account_id = 1;

-- Commit the transaction
COMMIT;

-- Terminal 2: Withdraw 300.-
BEGIN;

-- Lock the row for account_id 1
SELECT * FROM bank_accounts WHERE account_id = 1 FOR UPDATE;

-- Add delay (simulate time-consuming operation)
SELECT pg_sleep(10);  -- Sleep for 5 seconds

-- Terminal 3: Withdraw $300 from account 1
UPDATE bank_accounts
SET balance = balance - 300.00
WHERE account_id = 1;

-- Commit the transaction
COMMIT;

-- Terminal 3 Script (Deposit $500 without Delay)
BEGIN;

-- Lock the row for account_id 1
SELECT * FROM bank_accounts WHERE account_id = 1 FOR UPDATE;

-- Deposit $500 into account 1
UPDATE bank_accounts
SET balance = balance + 500.00
WHERE account_id = 1;

-- Commit the transaction
COMMIT;

-- Terminal 4: result
SELECT account_id, balance FROM bank_accounts;