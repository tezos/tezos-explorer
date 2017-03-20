-- ---
-- Globals
-- ---

-- SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
-- SET FOREIGN_KEY_CHECKS=0;


-- ---
-- Define a few useful types
-- ---

CREATE DOMAIN hash256 BINARY(32) NOT NULL;
CREATE DOMAIN hash160 BINARY(20) NOT NULL;
CREATE DOMAIN blob VARBINARY(MAX) NOT NULL;
-- ---
-- Table 'git_store'
-- A direct representation of the Irmin git store.
-- ---

DROP TABLE IF EXISTS "git_store";

CREATE TABLE "git_store" (
  "id" hash160,
  "type" ENUM('blob', 'tree') NOT NULL,
  "content" blob,
  PRIMARY KEY ("id")
);

COMMENT ON TABLE "git_store" IS 'A direct representation of the Irmin git store.';
COMMENT ON COLUMN "git_store.id" IS 'A git object hash.';
COMMENT ON COLUMN "git_store.type" IS 'A blob or tree.';
COMMENT ON COLUMN "git_store.content" IS 'The content of the blob or tree.';

-- ---
-- Table 'raw_operation'
-- A raw operation, as seen by the network shell.
-- ---

DROP TABLE IF EXISTS "raw_operation";
		
CREATE TABLE "raw_operation" (
  "id" hash256,
  "net_id" hash256 NULL,
  PRIMARY KEY ("id")
);

COMMENT ON TABLE "raw_operation" IS 'A raw operation, as seen by the network shell.';
COMMENT ON COLUMN "raw_operation.id" IS 'Hash of the raw operation.';
COMMENT ON COLUMN "raw_operation.net_id" IS 'TODO - explain';

-- ---
-- Table 'raw_block'
-- raw block
-- ---

DROP TABLE IF EXISTS "raw_block";
		
CREATE TABLE "raw_block" (
  "id" hash256,
  "height" INTEGER NOT NULL,
  "predecessor" hash256,
  "timestamp" DATETIME NOT NULL,
  "fitness" VARCHAR NOT NULL,
  "protocol" hash256,
  "net" hash256,
  "test_protocol" hash256,
  PRIMARY KEY ("id")
);

COMMENT ON TABLE "raw_block" IS 'Raw information about a block, as seen by the network shell.';
COMMENT ON COLUMN "raw_block.id" IS 'Hash of the block.';
COMMENT ON COLUMN "raw_block.height" IS 'Height of the block, starting at 0 with the genesis block.';
COMMENT ON COLUMN "raw_block.predecessor" IS 'Predecessor of this block.';
COMMENT ON COLUMN "raw_block.timestamp" IS 'When the block was created.';
COMMENT ON COLUMN "raw_block.fitness" IS 'Fitness of the chain after this block.';
COMMENT ON COLUMN "raw_block.protocol" IS 'Protocol used in this block.';
COMMENT ON COLUMN "raw_block.net" IS 'Network this block belongs to.';
COMMENT ON COLUMN "raw_block.test_protocol" IS 'Whether this is a block from a test network.';


-- ---
-- Table 'protocol'
-- Known protocols.
-- ---

DROP TABLE IF EXISTS "protocol";
		
CREATE TABLE "protocol" (
  "id" hash256,
  "name" VARCHAR NOT NULL,
  "tarball" blob,
  PRIMARY KEY ("id")
);

COMMENT ON TABLE "protocol" IS 'Known protocols.';
COMMENT ON COLUMN "protocol.id" IS 'Hash of the protocol.';
COMMENT ON COLUMN "protocol.name" IS 'Name of the protocol.';
COMMENT ON COLUMN "protocol.tarball" IS 'Tarball of the protocol sources.';

-- ---
-- Table 'block_operations'
-- 
-- ---

DROP TABLE IF EXISTS "block_operations";
		
CREATE TABLE "block_operations" (
  "operation" hash256 COMMENT 'an operation included in a block',
  "block" hash256 COMMENT 'block the operation is included in',
  PRIMARY KEY ("operation", "block")
) COMMENT 'association table betwen operations and the block they belong to. N.B. an operation
may be included in several blocks';



-- ---
-- Tables prefixed by seed_ refer to the entities which are only meaningful
-- to the seed protocol.
-- ---

-- ---
-- Table 'seed_operations'
-- 
-- ---

DROP TABLE IF EXISTS "seed_operations";
		
CREATE TABLE "seed_operations" (
  "id" hash256 COMMENT 'hash of the operation',
  "source" hash256 'source contract',
  "public_key" hash256 'public key of the source contract''s manager',
  "fee" INTEGER NOT NULL 'fee paid to the miner',
  "counter" INTEGER NOT NULL 'counter value of the source contract',
  -- TODO do we accept partially valid operations?
  "valid" BOOLEAN NOT NULL DEFAULT NULL 'is the operation valid or ignored',
  PRIMARY KEY ("id")
) COMMENT 'an operation as viewed by the seed protocol'

-- ---
-- Table 'seed_sub_operation'
-- 
-- ---

DROP TABLE IF EXISTS "seed_sub_operation";
		
CREATE TABLE "seed_sub_operation" (
  "id" hash256 COMMENT 'hash of the operation',
  "kind" ENUM NOT NULL COMMENT 'kind of operation',
  PRIMARY KEY ("id")
) COMMENT 'seed protocol operations are packages of multiple operations';

-- ---
-- Table 'seed_account'
-- Account in the seed protocol
-- ---

DROP TABLE IF EXISTS "seed_account";
		
CREATE TABLE "seed_account" (
  "id" hash256 COMMENT 'hash handle of the account',
  "counter" INTEGER NOT NULL COMMENT 'contract counter to avoid replay attacks',      
  "manager" hash256 COMMENT 'manager of the contract',
  "public_key" hash256 NULL DEFAULT NULL COMMENT 'public key of the manager, if known',
  "delegate" hash256 COMMENT 'delegate of the contract',
  "spendable" BOOLEAN NOT NULL COMMENT 'whether the funds are spendable',
  "delegatable" BOOLEAN NOT NULL COMMENT 'whether the delegate may be changed',
  "balance" INTEGER NOT NULL COMMENT 'balance in tez',
  PRIMARY KEY ("id","counter")
) COMMENT 'a contract in the seed protocol';

-- ---
-- Table 'seed_contract'
-- Contract attached to a seed account
-- ---

DROP TABLE IF EXISTS "seed_contract";

CREATE TABLE "seed_contract" (
  "id" hash256 'handle of the associated account',
  "counter" INTEGER NOT NULL 'counter of the associated account',        
  -- TODO set a better default than MAX for these fields
  "source" blob 'source code of the smart contract, null if none',
  "storage" blob 'storage of the smart contract, IF not too large',
  "storage_root" hash256 'root hash of the storage',
  "type" blob 'type of the attached michelson code and storage'
  PRIMARY KEY ("id", "counter")
) COMMENT 'contract attached to an account'

-- ---
-- Table 'seed_transaction'
-- a transaction in the seed protocol
-- ---

DROP TABLE IF EXISTS "seed_transaction";
		
CREATE TABLE "seed_transaction" (
  "id" hash256 COMMENT 'hash of the related seed_sub_operation',
  "amount" INTEGER NOT NULL COMMENT 'amount of the transaction',
  "destination" INTEGER NOT NULL 'destination contract',
  "input_data" blob NULL DEFAULT NULL 'input data passed if any',
  PRIMARY KEY ("id")
) COMMENT 'a transaction in the seed protocol';

-- ---
-- Table 'seed_origination'
-- origination in the seed protocol
-- ---

DROP TABLE IF EXISTS "seed_origination";
		
CREATE TABLE "seed_origination" (
  "id" hash256 COMMENT 'hash of the related seed_sub_operation',
  "account" hash256 NULL DEFAULT NULL COMMENT 'account created if succesful',
  "contract" hash256 NULL DEFAULT NULL COMMENT 'contract created if succesful',
  PRIMARY KEY ("id")
) COMMENT 'origination of an account / contract in the seed protocol'

-- ---
-- Table 'seed_delegation'
-- delegation in the seed protocol
-- ---

DROP TABLE IF EXISTS "seed_delegation";

CREATE TABLE "seed_delegation" (
  "id" hash256 COMMENT 'hash of the related seed_sub_operation',
  "delegate" hash256 COMMENT 'delegate key',
  PRIMARY KEY ("id")
)

-- ---
-- Foreign Keys 
-- ---

ALTER TABLE "raw_operation" ADD FOREIGN KEY (net_id) REFERENCES "raw_block" ("id");
ALTER TABLE "raw_block" ADD FOREIGN KEY (predecessor) REFERENCES "raw_block" ("id");
ALTER TABLE "raw_block" ADD FOREIGN KEY (protocol) REFERENCES "protocol" ("id");
ALTER TABLE "raw_block" ADD FOREIGN KEY (net) REFERENCES "raw_block" ("id");
ALTER TABLE "raw_block" ADD FOREIGN KEY (test_protocol) REFERENCES "protocol" ("id");
ALTER TABLE "block_operations" ADD FOREIGN KEY (id) REFERENCES "raw_block" ("id");
ALTER TABLE "block_operations" ADD FOREIGN KEY (operation) REFERENCES "raw_operation" ("id");
ALTER TABLE "seed_operations" ADD FOREIGN KEY (id) REFERENCES "raw_operation" ("id");
ALTER TABLE "seed_operations" ADD FOREIGN KEY (source) REFERENCES "seed_contract" ("id");
ALTER TABLE "seed_sub_operation" ADD FOREIGN KEY (id) REFERENCES "seed_operation" ("id");
ALTER TABLE "seed_transaction" ADD FOREIGN KEY (id) REFERENCES "seed_sub_operation" ("id");
ALTER TABLE "seed_transaction" ADD FOREIGN KEY (destination) REFERENCES "seed_account" ("id");
ALTER TABLE "seed_contract" ADD FOREIGN KEY account_fk (id, counter) REFERENCES "seed_account" ("id", "counter");
ALTER TABLE "seed_origination" ADD FOREIGN KEY (id) REFERENCES "seed_sub_operation" ("id");
ALTER TABLE "seed_origination" ADD FOREIGN KEY (account) REFERENCES "seed_account" ("id");
ALTER TABLE "seed_origination" ADD FOREIGN KEY (contract) REFERENCES "seed_contract" ("id");

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

-- INSERT INTO "raw_operation" ("id","net_id") VALUES
-- ('','');
-- INSERT INTO "raw_block" ("id","predecessor","timestamp","fitness","protocol","net","test_protocol") VALUES
-- ('','','','','','','');
-- INSERT INTO "protocol" ("id","name") VALUES
-- ('','');
-- INSERT INTO "block_operations" ("id","operation") VALUES
-- ('','');
-- INSERT INTO "seed_operations" ("id","source","public_key","fee","counter") VALUES
-- ('','','','','');
-- INSERT INTO "seed_sub_operation" ("id","kind") VALUES
-- ('','');
-- INSERT INTO "seed_contract" ("id") VALUES
-- ('');
-- INSERT INTO "seed_transaction" ("id","amount","destination") VALUES
-- ('','','');

