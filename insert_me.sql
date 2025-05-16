CREATE TABLE IF NOT EXISTS `hcyk_multijob` (
  `identifier` varchar(46) DEFAULT NULL,
  `job` varchar(100) NOT NULL,
  `grade` int(11) NOT NULL,
  `removable` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;