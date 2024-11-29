CREATE TABLE IF NOT EXISTS `shop_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account` int(11) NOT NULL,
  `player` int(11) NOT NULL,
  `date` datetime NOT NULL,
  `title` varchar(100) NOT NULL,
  `price` int(11) NOT NULL,
  `count` int(11) NOT NULL DEFAULT '0',
  `target` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`account`) REFERENCES `accounts` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`player`) REFERENCES `players` (`id`) ON DELETE CASCADE
);
