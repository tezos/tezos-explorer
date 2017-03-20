-- ---
-- Globals
-- ---

-- SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
-- SET FOREIGN_KEY_CHECKS=0;


-- ---
-- Define a few useful types
-- ---
DROP DOMAIN IF EXISTS hash256 CASCADE;
DROP DOMAIN IF EXISTS hash160 CASCADE;
CREATE DOMAIN hash256 varchar(52) NOT NULL;
CREATE DOMAIN hash160 varchar(32) NOT NULL;
-- ---
-- Table 'git_store'
-- A direct representation of the Irmin git store.
-- ---

DROP TABLE IF EXISTS git_store CASCADE;
DROP TYPE IF EXISTS git_store_type CASCADE;

CREATE TYPE git_store_type AS ENUM('blob', 'tree');
CREATE TABLE git_store (
  id hash160 PRIMARY KEY,
  type git_store_type NOT NULL,
  content bytea
);

COMMENT ON TABLE git_store IS 'A direct representation of the Irmin git store.';
COMMENT ON COLUMN git_store.id IS 'A git object hash.';
COMMENT ON COLUMN git_store.type IS 'A blob or tree.';
COMMENT ON COLUMN git_store.content IS 'The content of the blob or tree.';

-- ---
-- Table 'raw_operation'
-- A raw operation, as seen by the network shell.
-- ---

DROP TABLE IF EXISTS raw_operation CASCADE;

CREATE TABLE raw_operation (
  id hash256 PRIMARY KEY,
  net_id hash256 NULL
);

COMMENT ON TABLE raw_operation IS 'A raw operation, as seen by the network shell.';
COMMENT ON COLUMN raw_operation.id IS 'Hash of the raw operation.';
COMMENT ON COLUMN raw_operation.net_id IS 'TODO - explain';

-- ---
-- Table 'raw_block'
-- raw block
-- ---

DROP TABLE IF EXISTS raw_block CASCADE;

CREATE TABLE raw_block (
  id hash256 PRIMARY KEY,
  height int NOT NULL,
  predecessor hash256,
  timestamp timestamp NOT NULL,
  fitness VARCHAR NOT NULL,
  protocol hash256,
  net hash256,
  test_protocol hash256
);

COMMENT ON TABLE raw_block IS 'Raw information about a block, as seen by the network shell.';
COMMENT ON COLUMN raw_block.id IS 'Hash of the block.';
COMMENT ON COLUMN raw_block.height IS 'Height of the block, starting at 0 with the genesis block.';
COMMENT ON COLUMN raw_block.predecessor IS 'Predecessor of this block.';
COMMENT ON COLUMN raw_block.timestamp IS 'When the block was created.';
COMMENT ON COLUMN raw_block.fitness IS 'Fitness of the chain after this block.';
COMMENT ON COLUMN raw_block.protocol IS 'Protocol used in this block.';
COMMENT ON COLUMN raw_block.net IS 'Network this block belongs to.';
COMMENT ON COLUMN raw_block.test_protocol IS 'Whether this is a block from a test network.';


-- ---
-- Table 'protocol'
-- Known protocols.
-- ---

DROP TABLE IF EXISTS protocol CASCADE;

CREATE TABLE protocol (
  id hash256 PRIMARY KEY,
  name VARCHAR NOT NULL,
  tarball bytea
);

COMMENT ON TABLE protocol IS 'Known protocols.';
COMMENT ON COLUMN protocol.id IS 'Hash of the protocol.';
COMMENT ON COLUMN protocol.name IS 'Name of the protocol.';
COMMENT ON COLUMN protocol.tarball IS 'Tarball of the protocol sources.';

-- ---
-- Table 'block_operations'
--
-- ---

DROP TABLE IF EXISTS block_operations CASCADE;

CREATE TABLE block_operations (
  operation hash256,
  block hash256,
  PRIMARY KEY (operation, block)
);

COMMENT ON TABLE block_operations is 'association table between operations and the block they belong to. N.B. an operation may be included in several blocks';
COMMENT ON COLUMN block_operations.operation IS 'an operation included in a block';
COMMENT ON COLUMN block_operations.block IS 'block the operation is included in';

-- ---
-- Tables prefixed by seed_ refer to the entities which are only meaningful
-- to the seed protocol.
-- ---

-- ---
-- Table 'seed_operations'
--
-- ---

DROP TABLE IF EXISTS seed_operations CASCADE;

CREATE TABLE seed_operations (
  id hash256 PRIMARY KEY,
  source hash256,
  source_counter int,
  public_key hash256,
  fee int NOT NULL,
  valid boolean NOT NULL -- TODO do we accept partially valid operations?
);

COMMENT ON TABLE seed_operations is 'an operation as viewed by the seed protocol';
COMMENT ON COLUMN seed_operations.id is 'hash of the operation';
COMMENT ON COLUMN seed_operations.source is 'source contract';
COMMENT ON COLUMN seed_operations.source_counter is 'counter value of the source contract';
COMMENT ON COLUMN seed_operations.public_key is 'public key of the source contract''s manager';
COMMENT ON COLUMN seed_operations.fee is 'feed paid to the miner';
COMMENT ON COLUMN seed_operations.valid is 'is the operation valid or ignored';

-- ---
-- Table 'seed_sub_operation'
--
-- ---

DROP TABLE IF EXISTS seed_sub_operation CASCADE;
DROP TYPE IF EXISTS operation_kind CASCADE;

CREATE TYPE operation_kind AS ENUM('seed_nonce_revelation', 'faucet', 'transaction', 'origination', 'delegation', 'endorsement', 'proposal', 'ballot');
CREATE TABLE seed_sub_operation (
  id hash256 PRIMARY KEY,
  kind operation_kind NOT NULL
);

COMMENT ON TABLE seed_sub_operation is 'seed protocol operations are packages of multiple operations';
COMMENT ON COLUMN seed_sub_operation.id is 'hash of the operation';
COMMENT ON COLUMN seed_sub_operation.kind is 'kind of the operation';

-- ---
-- Table 'seed_account'
-- Account in the seed protocol
-- ---

DROP TABLE IF EXISTS seed_account CASCADE;

CREATE TABLE seed_account (
  id hash256,
  counter int NOT NULL,
  manager hash256,
  public_key hash256 NULL DEFAULT NULL,
  delegate hash256,
  spendable boolean NOT NULL,
  delegatable boolean NOT NULL,
  balance int NOT NULL,
  PRIMARY KEY (id, counter)
);

COMMENT ON TABLE seed_account IS 'a contract in the seed protocol';
COMMENT ON COLUMN seed_account.id IS 'hash handle of the account';
COMMENT ON COLUMN seed_account.manager IS 'manager of the contract';
COMMENT ON COLUMN seed_account.public_key IS 'public key of the manager, if known';
COMMENT ON COLUMN seed_account.delegate IS 'delegate of the contract';
COMMENT ON COLUMN seed_account.spendable IS 'whether the funds are spendable';
COMMENT ON COLUMN seed_account.delegatable IS 'whether the delegate may be changed';
COMMENT ON COLUMN seed_account.balance IS 'balance in tez';

-- ---
-- Table 'seed_contract'
-- Contract attached to a seed account
-- ---

DROP TABLE IF EXISTS seed_contract CASCADE;

CREATE TABLE seed_contract (
  id hash256,
  counter int,
  -- TODO set a better default than MAX for these fields
  source bytea,
  storage bytea,
  storage_root hash256,
  type bytea,
  PRIMARY KEY (id, counter)
);

COMMENT ON TABLE seed_contract IS 'contract attached to an account';
COMMENT ON COLUMN seed_contract.id IS 'handle of the associated account';
COMMENT ON COLUMN seed_contract.counter IS 'counter of the associated account';
COMMENT ON COLUMN seed_contract.source IS 'source code of the smart contract, null if none';
COMMENT ON COLUMN seed_contract.storage IS 'storage of the smart contract, IF not too large';
COMMENT ON COLUMN seed_contract.storage_root IS 'root hash of the storage';
COMMENT ON COLUMN seed_contract.type IS 'type of the attached michelson code and storage';

-- ---
-- Table 'seed_transaction'
-- a transaction in the seed protocol
-- ---

DROP TABLE IF EXISTS seed_transaction CASCADE;

CREATE TABLE seed_transaction (
  id hash256 PRIMARY KEY,
  amount int NOT NULL,
  destination hash256 NOT NULL,
  destination_counter int NOT NULL,
  input_data bytea NULL DEFAULT NULL
);

COMMENT ON TABLE seed_transaction IS 'a transaction in the seed protocol';
COMMENT ON COLUMN seed_transaction.id IS 'hash of the related seed_sub_operation';
COMMENT ON COLUMN seed_transaction.amount IS 'amount of the transaction';
COMMENT ON COLUMN seed_transaction.destination IS 'destination contract';
COMMENT ON COLUMN seed_transaction.destination_counter IS 'destination contract counter';
COMMENT ON COLUMN seed_transaction.input_data IS 'input data passed if any';

-- ---
-- Table 'seed_origination'
-- origination in the seed protocol
-- ---

DROP TABLE IF EXISTS seed_origination CASCADE;

CREATE TABLE seed_origination (
  id hash256 PRIMARY KEY,
  account hash256 NULL DEFAULT NULL,
  account_counter int NOT NULL,
  contract hash256 NULL DEFAULT NULL,
  contract_counter int NOT NULL
);

COMMENT ON TABLE seed_origination IS 'origination of an account / contract in the seed protocol';
COMMENT ON COLUMN seed_origination.id IS 'hash of the related seed_sub_operation';
COMMENT ON COLUMN seed_origination.account IS 'account created if succesful';
COMMENT ON COLUMN seed_origination.contract IS 'contract created if succesful';

-- ---
-- Table 'seed_delegation'
-- delegation in the seed protocol
-- ---

DROP TABLE IF EXISTS seed_delegation CASCADE;

CREATE TABLE seed_delegation (
  id hash256 PRIMARY KEY,
  delegate hash256
);

COMMENT ON COLUMN seed_delegation.id IS 'hash of the related seed_sub_operation';
COMMENT ON COLUMN seed_delegation.delegate IS 'delegate key';

-- ---
-- Foreign Keys
-- ---

ALTER TABLE raw_operation ADD FOREIGN KEY (net_id) REFERENCES raw_block (id);
ALTER TABLE raw_block ADD FOREIGN KEY (predecessor) REFERENCES raw_block (id);
ALTER TABLE raw_block ADD FOREIGN KEY (protocol) REFERENCES protocol (id);
ALTER TABLE raw_block ADD FOREIGN KEY (net) REFERENCES raw_block (id);
ALTER TABLE raw_block ADD FOREIGN KEY (test_protocol) REFERENCES protocol (id);
ALTER TABLE block_operations ADD FOREIGN KEY (block) REFERENCES raw_block (id);
ALTER TABLE block_operations ADD FOREIGN KEY (operation) REFERENCES raw_operation (id);
ALTER TABLE seed_operations ADD FOREIGN KEY (id) REFERENCES raw_operation (id);
ALTER TABLE seed_operations ADD FOREIGN KEY (source, source_counter) REFERENCES seed_contract (id, counter);
ALTER TABLE seed_sub_operation ADD FOREIGN KEY (id) REFERENCES seed_operations (id);
ALTER TABLE seed_transaction ADD FOREIGN KEY (id) REFERENCES seed_sub_operation (id);
ALTER TABLE seed_transaction ADD FOREIGN KEY (destination, destination_counter) REFERENCES seed_account (id, counter);
ALTER TABLE seed_contract ADD FOREIGN KEY (id, counter) REFERENCES seed_account (id, counter);
ALTER TABLE seed_origination ADD FOREIGN KEY (id) REFERENCES seed_sub_operation (id);
ALTER TABLE seed_origination ADD FOREIGN KEY (account, account_counter) REFERENCES seed_account (id, counter);
ALTER TABLE seed_origination ADD FOREIGN KEY (contract, contract_counter) REFERENCES seed_contract (id, counter);

-- ---
-- Table Properties
-- ---

-- ALTER TABLE "raw_operation" ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE "raw_block" ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE "protocol" ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE "block_operations" ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE "seed_operations" ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE "seed_sub_operation" ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE "seed_contract" ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE "seed_transaction" ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

-- ---
-- Test Data
-- ---

-- INSERT INTO raw_operation (id, net_id) VALUES
-- ('','');
-- INSERT INTO raw_block (id, predecessor, timestamp, fitness, protocol, net, test_protocol) VALUES
-- '','','','','','','');
-- INSERT INTO protocol (id, name) VALUES
-- ('','');
-- INSERT INTO block_operations (id, operation) VALUES
-- ('','');
-- INSERT INTO seed_operations (id, source, public_key, fee, counter) VALUES
-- ('','','','','');
-- INSERT INTO seed_sub_operation (id, kind) VALUES
-- ('','');
-- INSERT INTO seed_contract (id) VALUES
-- ('');
-- INSERT INTO seed_transaction (id, amount, destination) VALUES
-- ('','','');
