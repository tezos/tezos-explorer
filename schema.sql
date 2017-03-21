-- ---
-- Globals
-- ---

-- SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
-- SET FOREIGN_KEY_CHECKS=0;

-- ---
-- Define a few useful types
-- ---

CREATE DOMAIN tezos_hash char(64);

-- ---
-- Table 'git_store'
-- A direct representation of the Irmin git store.
-- ---

-- CREATE DOMAIN sha1 char(40);

-- CREATE TYPE git_store_type AS ENUM('blob', 'tree');
-- CREATE TABLE git_store (
--   id sha1 PRIMARY KEY,
--   type git_store_type NOT NULL,
--   content bytea
-- );

-- COMMENT ON TABLE git_store IS 'A direct representation of the Irmin git store.';
-- COMMENT ON COLUMN git_store.id IS 'A git object hash.';
-- COMMENT ON COLUMN git_store.type IS 'A blob or tree.';
-- COMMENT ON COLUMN git_store.content IS 'The content of the blob or tree.';

-- ---
-- Table 'protocol'
-- Known protocols.
-- ---

CREATE TABLE protocol (
  hash tezos_hash PRIMARY KEY,
  name VARCHAR
);

COMMENT ON TABLE protocol IS 'Known protocols.';
COMMENT ON COLUMN protocol.hash IS 'Hash of the protocol.';
COMMENT ON COLUMN protocol.name IS 'Optional name of the protocol.';

-- ---
-- Table 'raw_block'
-- raw block
-- ---

CREATE TABLE raw_block (
  hash tezos_hash PRIMARY KEY,
  predecessor tezos_hash REFERENCES raw_block (hash) DEFERRABLE INITIALLY DEFERRED,
  fitness bytea[] NOT NULL,
  timestamp timestamp NOT NULL,

  protocol tezos_hash REFERENCES protocol (hash),
  test_protocol tezos_hash REFERENCES protocol (hash),

  network tezos_hash REFERENCES raw_block (hash) DEFERRABLE INITIALLY DEFERRED,
  test_network tezos_hash REFERENCES raw_block (hash) DEFERRABLE INITIALLY DEFERRED,
  test_network_expiration timestamp
);

COMMENT ON TABLE raw_block IS 'Raw information about a block, as seen by the network shell.';
COMMENT ON COLUMN raw_block.hash IS 'Hash of the block.';
COMMENT ON COLUMN raw_block.predecessor IS 'Predecessor of this block.';
COMMENT ON COLUMN raw_block.fitness IS 'Fitness of the chain after this block.';
COMMENT ON COLUMN raw_block.timestamp IS 'When the block was created.';

COMMENT ON COLUMN raw_block.protocol IS 'Protocol active in this block.';
COMMENT ON COLUMN raw_block.test_protocol IS 'Test protocol active in this block.';

COMMENT ON COLUMN raw_block.network IS 'Network this block belongs to.';
COMMENT ON COLUMN raw_block.test_network IS 'Network this block belongs to.';
COMMENT ON COLUMN raw_block.test_network_expiration IS 'When the test network will expire';

-- ---
-- Table 'alpha_block'
-- parsed block, alpha protocol
-- ---

CREATE TABLE alpha_block (
  hash tezos_hash PRIMARY KEY REFERENCES raw_block,

  level int NOT NULL,
  priority int NOT NULL,

  cycle int NOT NULL,
  cycle_position int NOT NULL,

  voting_period int NOT NULL,
  voting_period_position int NOT NULL,

  commited_nonce_hash tezos_hash NOT NULL,
  pow_nonce bytea NOT NULL
);

COMMENT ON COLUMN alpha_block.hash IS 'Hash of the block.';
COMMENT ON COLUMN alpha_block.level IS 'Level of the block.';
COMMENT ON COLUMN alpha_block.priority IS 'Miner id who signed the block';
COMMENT ON COLUMN alpha_block.cycle IS 'current cycle id';
COMMENT ON COLUMN alpha_block.cycle_position IS 'current position in the cycle';
COMMENT ON COLUMN alpha_block.voting_period IS 'current voting period';
COMMENT ON COLUMN alpha_block.voting_period_position IS 'current position in the voting period';
COMMENT ON COLUMN alpha_block.commited_nonce_hash IS 'Hash of the random number committed to by the miner';
COMMENT ON COLUMN alpha_block.pow_nonce IS 'PoW nonce of the block';

-- ---
-- Table 'raw_operation'
-- A raw operation, as seen by the network shell.
-- ---

CREATE TABLE raw_operation (
  hash tezos_hash PRIMARY KEY,
  network tezos_hash REFERENCES raw_block (hash)
);

COMMENT ON TABLE raw_operation IS 'A raw operation, as seen by the network shell.';
COMMENT ON COLUMN raw_operation.hash IS 'Hash of the raw operation.';
COMMENT ON COLUMN raw_operation.network IS 'The ancestor genesis block of this operation';

-- ---
-- Table 'block_operations'
--
-- ---

CREATE TABLE block_operations (
  operation_hash tezos_hash REFERENCES raw_operation (hash),
  block_hash tezos_hash REFERENCES raw_block (hash),
  PRIMARY KEY (operation_hash, block_hash)
);

COMMENT ON TABLE block_operations is 'association table between operations and the block they belong to. N.B. an operation may be included in several blocks';
COMMENT ON COLUMN block_operations.operation_hash IS 'The operation hash ';
COMMENT ON COLUMN block_operations.block_hash IS 'The hash of the block the operation is included in';

-- ---
-- Table 'alpha_operation'
-- An alpha operation, as seen by the network shell.
-- ---

CREATE TYPE alpha_operation_type AS ENUM (
  'seed_nonce_revelation',
  'faucet',
  'transaction',
  'origination',
  'delegation',
  'endorsement',
  'proposal',
  'ballot',
  'activate',
  'activate_testnet'
);

CREATE TABLE alpha_operation (
  hash tezos_hash NOT NULL,
  id smallint NOT NULL,
  type alpha_operation_type NOT NULL,
  PRIMARY KEY (hash, id)
);

CREATE TABLE alpha_seed_nonce_revelation (
  hash tezos_hash NOT NULL,
  id smallint NOT NULL,
  level int NOT NULL,
  nonce bytea NOT NULL,
  FOREIGN KEY (hash, id) REFERENCES alpha_operation
);

CREATE TABLE alpha_faucet (
  hash tezos_hash NOT NULL,
  id smallint NOT NULL,
  pkh tezos_hash NOT NULL,
  nonce bytea NOT NULL,
  PRIMARY KEY (hash, id),
  FOREIGN KEY (hash, id) REFERENCES alpha_operation
);

CREATE TABLE alpha_key (
  hash tezos_hash PRIMARY KEY,
  data tezos_hash
);

CREATE TABLE alpha_transaction (
  hash tezos_hash NOT NULL,
  id smallint NOT NULL,
  source tezos_hash NOT NULL REFERENCES alpha_key (hash),
  destination tezos_hash NOT NULL REFERENCES alpha_key (hash),
  fee int NOT NULL,
  counter int NOT NULL,
  amount bigint NOT NULL,
  parameters bytea,
  PRIMARY KEY (hash, id),
  FOREIGN KEY (hash, id) REFERENCES alpha_operation
);

COMMENT ON TABLE alpha_transaction IS 'a transaction in the alpha protocol';
COMMENT ON COLUMN alpha_transaction.hash IS 'hash of the related alpha_operation';
COMMENT ON COLUMN alpha_transaction.amount IS 'amount of the transaction';
COMMENT ON COLUMN alpha_transaction.destination IS 'destination contract';
COMMENT ON COLUMN alpha_transaction.parameters IS 'input data passed if any';

CREATE TABLE alpha_origination (
  hash tezos_hash NOT NULL,
  id smallint NOT NULL,
  source tezos_hash NOT NULL,
  fee int NOT NULL,
  counter int NOT NULL,
  manager tezos_hash NOT NULL,
  delegate tezos_hash,
  script bytea,
  spendable boolean NOT NULL,
  delegatable boolean NOT NULL,
  credit bigint NOT NULL,
  PRIMARY KEY (hash, id),
  FOREIGN KEY (hash, id) REFERENCES alpha_operation
);

COMMENT ON TABLE alpha_origination IS 'origination of an account / contract in the seed protocol';
COMMENT ON COLUMN alpha_origination.hash IS 'hash of the related alpha_operation';

CREATE TABLE alpha_delegation (
  hash tezos_hash NOT NULL,
  id smallint NOT NULL,
  source tezos_hash NOT NULL,
  pubkey tezos_hash,
  fee int NOT NULL,
  counter int NOT NULL,
  delegate tezos_hash,
  PRIMARY KEY (hash, id),
  FOREIGN KEY (hash, id) REFERENCES alpha_operation
);

COMMENT ON COLUMN alpha_delegation.hash IS 'hash of the related alpha_operations';
COMMENT ON COLUMN alpha_delegation.delegate IS 'delegate pubkey hash';

CREATE TABLE alpha_endorsement (
  hash tezos_hash NOT NULL,
  id smallint NOT NULL,
  source tezos_hash NOT NULL REFERENCES alpha_key (hash),
  block_hash tezos_hash NOT NULL REFERENCES raw_block (hash),
  slot smallint NOT NULL,
  PRIMARY KEY (hash, id),
  FOREIGN KEY (hash, id) REFERENCES alpha_operation
);

CREATE TABLE alpha_proposals (
  hash tezos_hash NOT NULL,
  id smallint NOT NULL,
  source tezos_hash NOT NULL,
  voting_period int NOT NULL,
  proposals char(54)[] NOT NULL,
  PRIMARY KEY (hash, id),
  FOREIGN KEY (hash, id) REFERENCES alpha_operation
);

CREATE TYPE alpha_ballot_vote AS ENUM ('Yay', 'Nay', 'Pass');

CREATE TABLE alpha_ballots (
  hash tezos_hash NOT NULL,
  id smallint NOT NULL,
  source tezos_hash NOT NULL,
  voting_period int NOT NULL,
  proposal tezos_hash NOT NULL,
  ballot alpha_ballot_vote NOT NULL,
  PRIMARY KEY (hash, id),
  FOREIGN KEY (hash, id) REFERENCES alpha_operation
);

CREATE TABLE alpha_dictator (
  hash tezos_hash NOT NULL,
  id smallint NOT NULL,
  protocol_hash tezos_hash NOT NULL,
  PRIMARY KEY (hash, id),
  FOREIGN KEY (hash, id) REFERENCES alpha_operation
);

-- ---
-- Table 'alpha_account'
-- Account in the seed protocol
-- ---

CREATE TABLE alpha_account (
  hash tezos_hash,
  counter int,
  manager tezos_hash NOT NULL REFERENCES alpha_key (hash),
  delegate tezos_hash REFERENCES alpha_key (hash),
  spendable boolean NOT NULL,
  delegatable boolean NOT NULL,
  balance int NOT NULL,
  PRIMARY KEY (hash, counter)
);

COMMENT ON TABLE alpha_account IS 'an account in the seed protocol';
COMMENT ON COLUMN alpha_account.hash IS 'hash handle of the account';
COMMENT ON COLUMN alpha_account.manager IS 'manager of the contract';
COMMENT ON COLUMN alpha_account.delegate IS 'delegate of the contract';
COMMENT ON COLUMN alpha_account.spendable IS 'whether the funds are spendable';
COMMENT ON COLUMN alpha_account.delegatable IS 'whether the delegate may be changed';
COMMENT ON COLUMN alpha_account.balance IS 'balance in tez';

-- ---
-- Table 'seed_contract'
-- Contract attached to a seed account
-- ---

-- CREATE TABLE seed_contract (
--   hash tezos_hash,
--   counter int,
--   -- TODO set a better default than MAX for these fields
--   source bytea,
--   storage bytea,
--   storage_root tezos_hash,
--   type bytea,
--   PRIMARY KEY (hash, counter),
--   FOREIGN KEY (hash, counter) REFERENCES alpha_account
-- );

-- COMMENT ON TABLE seed_contract IS 'contract attached to an account';
-- COMMENT ON COLUMN seed_contract.hash IS 'handle of the associated account';
-- COMMENT ON COLUMN seed_contract.counter IS 'counter of the associated account';
-- COMMENT ON COLUMN seed_contract.source IS 'source code of the smart contract, null if none';
-- COMMENT ON COLUMN seed_contract.storage IS 'storage of the smart contract, IF not too large';
-- COMMENT ON COLUMN seed_contract.storage_root IS 'root hash of the storage';
-- COMMENT ON COLUMN seed_contract.type IS 'type of the attached michelson code and storage';

-- ---
-- Table Properties
-- ---

-- ALTER TABLE "raw_operation" ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE "block" ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
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
-- INSERT INTO block (id, predecessor, timestamp, fitness, protocol, net, test_protocol) VALUES
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
