DROP TABLE IF EXISTS `message`;
CREATE TABLE `message` (
    `created` DATETIME NOT NULL,
    `id` varchar(128) NOT NULL,
    `int_id` char(16) NOT NULL,
    `str` text NOT NULL,
    `status` BOOLEAN,
    CONSTRAINT message_id_pk PRIMARY KEY(`id`)
);
CREATE INDEX message_created_idx ON message (created);
CREATE INDEX message_int_id_idx ON message (int_id);

DROP TABLE IF EXISTS `log`;
CREATE TABLE log (
    `created` DATETIME NOT NULL,
    `int_id` CHAR(16) NOT NULL,
    `str` text,
    `address` VARCHAR(255)
);
CREATE INDEX log_address_idx ON `log` (`address`) USING HASH;