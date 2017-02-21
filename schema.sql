-- ---
-- Globals
-- ---

-- SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
-- SET FOREIGN_KEY_CHECKS=0;


-- ---
-- Table 'git_store'
-- git store
-- ---

DROP TABLE IF EXISTS `git_store`;

CREATE TABLE `git_store` (
  `id` BINARY(20) NOT NULL COMMENT 'git object hash'
  `type` ENUM NOT NULL COMMENT 'blob|tree'
  `content` VARBINARY(MAX) NOT NULL COMMENT 'content of the blob or tree'
) COMMENT 'a direct mapping of the irmin git store'


-- ---
-- Table 'raw_operation'
-- raw operation
-- ---

DROP TABLE IF EXISTS `raw_operation`;
		
CREATE TABLE `raw_operation` (
  `id` BINARY(32) NOT NULL COMMENT 'hash of the operation',
  `net_id` BINARY(32) NULL COMMENT 'TODO - explain',
  PRIMARY KEY (`id`)
) COMMENT 'raw operation';

-- ---
-- Table 'raw_block'
-- raw block
-- ---

DROP TABLE IF EXISTS `raw_block`;
		
CREATE TABLE `raw_block` (
  `id` BINARY(32) NOT NULL COMMENT 'hash of the block',
  `height` INTEGER NOT NULL COMMENT 'height of the block, starting at 0',
  `predecessor` BINARY(32) NOT NULL  COMMENT 'predecessor of the hash',
  `timestamp` DATETIME NOT NULL COMMENT 'when the block was created',
  `fitness` VARCHAR NOT NULL COMMENT 'fitness of the chain at this block',
  `protocol` BINARY(32) NOT NULL COMMENT 'protocol used in this block',
  `net` BINARY(32) NOT NULL COMMENT 'network this block belongs to',
  `test_protocol` BINARY(32) NOT NULL 'whether this is a block from a test network',
  PRIMARY KEY (`id`)
) COMMENT 'raw information about a block';

-- ---
-- Table 'protocol'
-- 
-- ---

DROP TABLE IF EXISTS `protocol`;
		
CREATE TABLE `protocol` (
  `id` BINARY(32) NOT NULL COMMENT 'hash of the protocol',
  `name` VARCHAR NULL COMMENT 'name of the protocol',
  PRIMARY KEY (`id`)
) COMMENT 'all known protocols';

-- ---
-- Table 'block_operations'
-- 
-- ---

DROP TABLE IF EXISTS `block_operations`;
		
CREATE TABLE `block_operations` (
  `operation` BINARY(32) NOT NULL COMMENT 'an operation included in a block',
  `block` BINARY(32) NOT NULL COMMENT 'block the operation is included in',
  PRIMARY KEY (`operation`, `block`)
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

DROP TABLE IF EXISTS `seed_operations`;
		
CREATE TABLE `seed_operations` (
  `id` BINARY(32) NOT NULL COMMENT 'hash of the operation',
  `source` BINARY(32) NOT NULL 'source contract',
  `public_key` BINARY(32) NOT NULL 'public key of the source contract''s manager',
  `fee` INTEGER NOT NULL 'fee paid to the miner',
  `counter` INTEGER NOT NULL 'counter value of the source contract',
  -- TODO do we accept partially valid operations?
  `valid` BOOLEAN NOT NULL DEFAULT NULL 'is the operation valid or ignored',
  PRIMARY KEY (`id`)
) COMMENT 'an operation as viewed by the seed protocol'

-- ---
-- Table 'seed_sub_operation'
-- 
-- ---

DROP TABLE IF EXISTS `seed_sub_operation`;
		
CREATE TABLE `seed_sub_operation` (
  `id` BINARY(32) NOT NULL COMMENT 'hash of the operation',
  `kind` ENUM NOT NULL COMMENT 'kind of operation',
  PRIMARY KEY (`id`)
) COMMENT 'seed protocol operations are packages of multiple operations';

-- ---
-- Table 'seed_account'
-- Account in the seed protocol
-- ---

DROP TABLE IF EXISTS `seed_account`;
		
CREATE TABLE `seed_account` (
  `id` BINARY(32) NOT NULL COMMENT 'hash handle of the account',
  `counter` INTEGER NOT NULL COMMENT 'contract counter to avoid replay attacks',      
  `manager` BINARY(32) NOT NULL COMMENT 'manager of the contract',
  `public_key` BINARY(32) NULL DEFAULT NULL COMMENT 'public key of the manager, if known',
  `delegate` BINARY(32) NOT NULL COMMENT 'delegate of the contract',
  `spendable` BOOLEAN NOT NULL COMMENT 'whether the funds are spendable',
  `delegatable` BOOLEAN NOT NULL COMMENT 'whether the delegate may be changed',
  `balance` INTEGER NOT NULL COMMENT 'balance in tez',
  PRIMARY KEY (`id`,`counter`)
) COMMENT 'a contract in the seed protocol';

-- ---
-- Table 'seed_contract'
-- Contract attached to a seed account
-- ---

DROP TABLE IF EXISTS `seed_contract`;

CREATE TABLE `seed_contract` (
  `id` BINARY(32) NOT NULL 'handle of the associated account',
  `counter` INTEGER NOT NULL 'counter of the associated account',        
  -- TODO set a better default than MAX for these fields
  `source` VARBINARY(MAX) NOT NULL 'source code of the smart contract, null if none',
  `storage` VARBINARY(MAX) NOT NULL 'storage of the smart contract, IF not too large',
  `storage_root` BINARY(32) NOT NULL 'root hash of the storage',
  `type` VARBINARY(MAX) NOT NULL 'type of the attached michelson code and storage'
  PRIMARY KEY (`id`, `counter`)
) COMMENT 'contract attached to an account'

-- ---
-- Table 'seed_transaction'
-- a transaction in the seed protocol
-- ---

DROP TABLE IF EXISTS `seed_transaction`;
		
CREATE TABLE `seed_transaction` (
  `id` BINARY(32) NOT NULL COMMENT 'hash of the related seed_sub_operation',
  `amount` INTEGER NOT NULL COMMENT 'amount of the transaction',
  `destination` INTEGER NOT NULL 'destination contract',
  `input_data` VARBINARY(MAX) NULL DEFAULT NULL 'input data passed if any',
  PRIMARY KEY (`id`)
) COMMENT 'a transaction in the seed protocol';

-- ---
-- Table 'seed_origination'
-- origination in the seed protocol
-- ---

DROP TABLE IF EXISTS `seed_origination`;
		
CREATE TABLE `seed_origination` (
  `id` BINARY(32) NOT NULL COMMENT 'hash of the related seed_sub_operation',
  `account` BINARY(32) NULL DEFAULT NULL COMMENT 'account created if succesful',
  `contract` BINARY(32) NULL DEFAULT NULL COMMENT 'contract created if succesful',
  PRIMARY KEY (`id`)
) COMMENT 'origination of an account / contract in the seed protocol'

-- ---
-- Table 'seed_delegation'
-- delegation in the seed protocol
-- ---

DROP TABLE IF EXISTS `seed_delegation`;

CREATE TABLE `seed_delegation` (
  `id` BINARY(32) NOT NULL COMMENT 'hash of the related seed_sub_operation',
  `delegate` BINARY(32) NOT NULL COMMENT 'delegate key',
  PRIMARY KEY (`id`)
)

-- ---
-- Foreign Keys 
-- ---

ALTER TABLE `raw_operation` ADD FOREIGN KEY (net_id) REFERENCES `raw_block` (`id`);
ALTER TABLE `raw_block` ADD FOREIGN KEY (predecessor) REFERENCES `raw_block` (`id`);
ALTER TABLE `raw_block` ADD FOREIGN KEY (protocol) REFERENCES `protocol` (`id`);
ALTER TABLE `raw_block` ADD FOREIGN KEY (net) REFERENCES `raw_block` (`id`);
ALTER TABLE `raw_block` ADD FOREIGN KEY (test_protocol) REFERENCES `protocol` (`id`);
ALTER TABLE `block_operations` ADD FOREIGN KEY (id) REFERENCES `raw_block` (`id`);
ALTER TABLE `block_operations` ADD FOREIGN KEY (operation) REFERENCES `raw_operation` (`id`);
ALTER TABLE `seed_operations` ADD FOREIGN KEY (id) REFERENCES `raw_operation` (`id`);
ALTER TABLE `seed_operations` ADD FOREIGN KEY (source) REFERENCES `seed_contract` (`id`);
ALTER TABLE `seed_sub_operation` ADD FOREIGN KEY (id) REFERENCES `seed_operation` (`id`);
ALTER TABLE `seed_transaction` ADD FOREIGN KEY (id) REFERENCES `seed_sub_operation` (`id`);
ALTER TABLE `seed_transaction` ADD FOREIGN KEY (destination) REFERENCES `seed_account` (`id`);
ALTER TABLE `seed_contract` ADD FOREIGN KEY account_fk (id, counter) REFERENCES `seed_account` (`id`, `counter`);
ALTER TABLE `seed_origination` ADD FOREIGN KEY (id) REFERENCES `seed_sub_operation` (`id`);
ALTER TABLE `seed_origination` ADD FOREIGN KEY (account) REFERENCES `seed_account` (`id`);
ALTER TABLE `seed_origination` ADD FOREIGN KEY (contract) REFERENCES `seed_contract` (`id`);

-- ---
-- Table Properties
-- ---

-- ALTER TABLE `raw_operation` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE `raw_block` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE `protocol` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE `block_operations` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE `seed_operations` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE `seed_sub_operation` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE `seed_contract` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE `seed_transaction` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

-- ---
-- Test Data
-- ---

-- INSERT INTO `raw_operation` (`id`,`net_id`) VALUES
-- ('','');
-- INSERT INTO `raw_block` (`id`,`predecessor`,`timestamp`,`fitness`,`protocol`,`net`,`test_protocol`) VALUES
-- ('','','','','','','');
-- INSERT INTO `protocol` (`id`,`name`) VALUES
-- ('','');
-- INSERT INTO `block_operations` (`id`,`operation`) VALUES
-- ('','');
-- INSERT INTO `seed_operations` (`id`,`source`,`public_key`,`fee`,`counter`) VALUES
-- ('','','','','');
-- INSERT INTO `seed_sub_operation` (`id`,`kind`) VALUES
-- ('','');
-- INSERT INTO `seed_contract` (`id`) VALUES
-- ('');
-- INSERT INTO `seed_transaction` (`id`,`amount`,`destination`) VALUES
-- ('','','');

