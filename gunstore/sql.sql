CREATE TABLE IF NOT EXISTS `player_weapons` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(50) NOT NULL,
  `weapon` VARCHAR(50) NOT NULL,
  `ammo` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_weapon_per_player` (`identifier`, `weapon`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Example Insert Data
INSERT IGNORE INTO `player_weapons` (`id`, `identifier`, `weapon`, `ammo`) VALUES
(8, 'steam:', 'WEAPON_PISTOL', 30);
/*(8, 'steam:11000014a98e81f', 'WEAPON_PISTOL', 30);*/
