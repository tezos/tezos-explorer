-- ---
-- Globals
-- ---

-- SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
-- SET FOREIGN_KEY_CHECKS=0;

-- ---
-- Table 'raw_operation'
-- raw operation
-- ---

DROP TABLE IF EXISTS `raw_operation`;
		
CREATE TABLE `raw_operation` (
  `id` BINARY(32) NOT NULL,
  `net_id` BINARY(32) NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) COMMENT 'raw operation';

-- ---
-- Table 'raw_block'
-- 
-- ---

DROP TABLE IF EXISTS `raw_block`;
		
CREATE TABLE `raw_block` (
  `id` BINARY(32) NOT NULL COMMENT 'hash of the block',
  `height` INTEGER NOT NULL COMMENT 'height of the block, starting at 0',
  `predecessor` BINARY(32) NOT NULL  COMMENT 'predecessor of the hash',
  `timestamp` DATETIME NOT NULL COMMENT 'when the block was created',
  `fitness` VARCHAR NOT NULL,
  `protocol` BINARY(32) NOT NULL,
  `net` BINARY(32) NOT NULL,
  `test_protocol` BINARY(32) NOT NULL DEFAULT 'NUL',
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'protocol'
-- 
-- ---

DROP TABLE IF EXISTS `protocol`;
		
CREATE TABLE `protocol` (
  `id` BINARY(32) NOT NULL COMMENT 'hash of the protocol',
  `name` VARCHAR NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'block_operations'
-- 
-- ---

DROP TABLE IF EXISTS `block_operations`;
		
CREATE TABLE `block_operations` (
  `id` BINARY(32) NOT NULL,
  `operation` BINARY(32) NOT NULL COMMENT 'an operation included in a block',
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'seed_operations'
-- 
-- ---

DROP TABLE IF EXISTS `seed_operations`;
		
CREATE TABLE `seed_operations` (
  `id` BINARY(32) NULL,
  `source` BINARY(32) NULL DEFAULT NULL,
  `public_key` BINARY(32) NOT NULL,
  `fee` INTEGER NOT NULL,
  `counter` INTEGER NOT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'seed_sub_operation'
-- 
-- ---

DROP TABLE IF EXISTS `seed_sub_operation`;
		
CREATE TABLE `seed_sub_operation` (
  `id` INTEGER NULL AUTO_INCREMENT DEFAULT NULL,
  `kind` ENUM NOT NULL COMMENT 'kind of operation',
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'seed_contract'
-- 
-- ---

DROP TABLE IF EXISTS `seed_contract`;
		
CREATE TABLE `seed_contract` (
  `id` BINARY(32) NOT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'seed_transaction'
-- a transaction in the seed protocol
-- ---

DROP TABLE IF EXISTS `seed_transaction`;
		
CREATE TABLE `seed_transaction` (
  `id` BINARY(32) NOT NULL,
  `amount` INTEGER NOT NULL DEFAULT NUL,
  `destination` INTEGER NOT NULL,
  -- TODO probably add some optional script data here
  PRIMARY KEY (`id`)
) COMMENT 'a transaction in the seed protocol';

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
ALTER TABLE `seed_sub_operation` ADD FOREIGN KEY (id) REFERENCES `seed_operations` (`id`);
ALTER TABLE `seed_transaction` ADD FOREIGN KEY (id) REFERENCES `seed_sub_operation` (`id`);
ALTER TABLE `seed_transaction` ADD FOREIGN KEY (destination) REFERENCES `seed_contract` (`id`);

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
