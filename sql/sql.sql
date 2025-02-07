-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
-- -----------------------------------------------------
-- Schema bank_system
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema bank_system
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `bank_system` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci ;
USE `bank_system` ;

-- -----------------------------------------------------
-- Table `bank_system`.`customer`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `bank_system`.`customer` (
  `customer_id` INT NOT NULL AUTO_INCREMENT,
  `company_name` VARCHAR(255) NOT NULL,
  `citizen_number` VARCHAR(11) NOT NULL,
  `tax_number` VARCHAR(15) NULL DEFAULT NULL,
  `email` VARCHAR(255) NOT NULL,
  `phone_number` VARCHAR(15) NULL DEFAULT NULL,
  `create_date` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `status` ENUM('Aktif', 'Pasif') NULL DEFAULT 'Aktif',
  PRIMARY KEY (`customer_id`),
  UNIQUE INDEX `citizen_number` (`citizen_number` ASC) VISIBLE,
  UNIQUE INDEX `email` (`email` ASC) VISIBLE)
ENGINE = InnoDB
AUTO_INCREMENT = 19
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `bank_system`.`terminal`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `bank_system`.`terminal` (
  `terminal_id` INT NOT NULL AUTO_INCREMENT,
  `customer_id` INT NOT NULL,
  `city_code` VARCHAR(5) NOT NULL,
  `status` ENUM('Aktif', 'Pasif') NULL DEFAULT 'Aktif',
  `create_date` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`terminal_id`),
  INDEX `customer_id` (`customer_id` ASC) VISIBLE,
  CONSTRAINT `terminal_ibfk_1`
    FOREIGN KEY (`customer_id`)
    REFERENCES `bank_system`.`customer` (`customer_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
AUTO_INCREMENT = 41
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `bank_system`.`transaction`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `bank_system`.`transaction` (
  `transaction_id` INT NOT NULL AUTO_INCREMENT,
  `customer_id` INT NOT NULL,
  `terminal_id` INT NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `commission` DECIMAL(10,2) NOT NULL,
  `transaction_type` ENUM('Ödeme', 'İade') NOT NULL,
  `create_date` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`transaction_id`),
  INDEX `customer_id` (`customer_id` ASC) VISIBLE,
  INDEX `terminal_id` (`terminal_id` ASC) VISIBLE,
  CONSTRAINT `transaction_ibfk_1`
    FOREIGN KEY (`customer_id`)
    REFERENCES `bank_system`.`customer` (`customer_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `transaction_ibfk_2`
    FOREIGN KEY (`terminal_id`)
    REFERENCES `bank_system`.`terminal` (`terminal_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
AUTO_INCREMENT = 1122
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `bank_system`.`transaction_history`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `bank_system`.`transaction_history` (
  `history_id` INT NOT NULL AUTO_INCREMENT,
  `transaction_id` INT NOT NULL,
  `customer_id` INT NOT NULL,
  `terminal_id` INT NOT NULL,
  `amount` DECIMAL(10,2) NULL DEFAULT NULL,
  `commission` DECIMAL(10,2) NULL DEFAULT NULL,
  `transaction_type` ENUM('Ödeme', 'İade') NULL DEFAULT NULL,
  `change_type` ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
  `change_date` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`history_id`),
  INDEX `transaction_id` (`transaction_id` ASC) VISIBLE,
  CONSTRAINT `transaction_history_ibfk_1`
    FOREIGN KEY (`transaction_id`)
    REFERENCES `bank_system`.`transaction` (`transaction_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
AUTO_INCREMENT = 8
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;

USE `bank_system` ;

-- -----------------------------------------------------
-- procedure GenerateRandomData
-- -----------------------------------------------------

DELIMITER $$
USE `bank_system`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GenerateRandomData`()
BEGIN
    -- Değişkenleri tanımla
    DECLARE done INT DEFAULT 0;
    DECLARE customer_id_var INT;
    DECLARE terminal_count INT DEFAULT 0;
    DECLARE transaction_count INT DEFAULT 0;
    DECLARE j INT DEFAULT 0;
    DECLARE k INT DEFAULT 0;
    
    -- Cursor tanımla
    DECLARE cur CURSOR FOR SELECT customer_id FROM customer;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Eğer müşteri yoksa hata vererek prosedürü durdur
    IF (SELECT COUNT(*) FROM customer) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hata: Sistemde müşteri yok!';
    END IF;

    -- Cursor'u aç
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO customer_id_var;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Rastgele terminal sayısı oluştur
        SET terminal_count = FLOOR(1 + RAND() * 3);
        SET j = 0;

        WHILE j < terminal_count DO
            SET j = j + 1;

            -- Terminal ekle
            INSERT INTO terminal (customer_id, city_code, status)
            VALUES (customer_id_var, FLOOR(1 + RAND() * 81), 'Aktif');

            SET @terminal_id = LAST_INSERT_ID();

            -- Rastgele işlem sayısı oluştur
            SET transaction_count = FLOOR(10 + RAND() * 41);
            SET k = 0;

            WHILE k < transaction_count DO
                SET k = k + 1;

                -- İşlem ekle
                INSERT INTO transaction (customer_id, terminal_id, amount, commission, transaction_type)
                VALUES (
                    customer_id_var,
                    @terminal_id,
                    FLOOR(50 + RAND() * 4951),
                    FLOOR(1 + RAND() * 101),
                    CASE FLOOR(1 + RAND() * 2)
                        WHEN 1 THEN 'Ödeme'
                        ELSE 'İade'
                    END
                );
            END WHILE;
        END WHILE;
    END LOOP;

    -- Cursor'u kapat
    CLOSE cur;
END$$

DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
USE `bank_system`;

DELIMITER $$
USE `bank_system`$$
CREATE
DEFINER=`root`@`localhost`
TRIGGER `bank_system`.`trg_transaction_history`
AFTER UPDATE ON `bank_system`.`transaction`
FOR EACH ROW
BEGIN
    INSERT INTO transaction_history (
        transaction_id,
        customer_id,
        terminal_id,
        amount,
        commission,
        transaction_type,
        change_type
    )
    VALUES (
        NEW.transaction_id,
        NEW.customer_id,
        NEW.terminal_id,
        NEW.amount,
        NEW.commission,
        NEW.transaction_type,
        'UPDATE'
    );
END$$

USE `bank_system`$$
CREATE
DEFINER=`root`@`localhost`
TRIGGER `bank_system`.`trg_transaction_history_delete`
AFTER DELETE ON `bank_system`.`transaction`
FOR EACH ROW
BEGIN
    INSERT INTO transaction_history (
        transaction_id,
        customer_id,
        terminal_id,
        amount,
        commission,
        transaction_type,
        change_type
    )
    VALUES (
        OLD.transaction_id,
        OLD.customer_id,
        OLD.terminal_id,
        OLD.amount,
        OLD.commission,
        OLD.transaction_type,
        'DELETE'
    );
END$$


DELIMITER ;
