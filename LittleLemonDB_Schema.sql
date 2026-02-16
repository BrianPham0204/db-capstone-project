-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema LittleLemonDB
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema LittleLemonDB
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `LittleLemonDB` DEFAULT CHARACTER SET utf8 ;
USE `LittleLemonDB` ;

-- -----------------------------------------------------
-- Table `LittleLemonDB`.`Bookings`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `LittleLemonDB`.`Bookings` (
  `bookingID` INT NOT NULL,
  `date` DATE NOT NULL,
  `TableNo` INT NOT NULL,
  PRIMARY KEY (`bookingID`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `LittleLemonDB`.`Customers`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `LittleLemonDB`.`Customers` (
  `customerID` INT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `contact` INT NOT NULL,
  PRIMARY KEY (`customerID`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `LittleLemonDB`.`Staffs`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `LittleLemonDB`.`Staffs` (
  `staffID` INT NOT NULL,
  `role` VARCHAR(45) NOT NULL,
  `salary` DECIMAL NOT NULL,
  PRIMARY KEY (`staffID`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `LittleLemonDB`.`DeliveryStatus`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `LittleLemonDB`.`DeliveryStatus` (
  `deliveryID` INT NOT NULL,
  `deliveryDate` DATE NOT NULL,
  `status` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`deliveryID`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `LittleLemonDB`.`Orders`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `LittleLemonDB`.`Orders` (
  `orderID` INT NOT NULL,
  `orderDate` INT NOT NULL,
  `customerID` INT NOT NULL,
  `staffID` INT NOT NULL,
  `bookingID` INT NOT NULL,
  `deliveryID` INT NOT NULL,
  PRIMARY KEY (`orderID`),
  INDEX `bookingID_idx` (`bookingID` ASC) VISIBLE,
  INDEX `customer_fk_idx` (`customerID` ASC) VISIBLE,
  INDEX `staff_fk_idx` (`staffID` ASC) VISIBLE,
  INDEX `delivery_fk_idx` (`deliveryID` ASC) VISIBLE,
  CONSTRAINT `bookingid_fk`
    FOREIGN KEY (`bookingID`)
    REFERENCES `LittleLemonDB`.`Bookings` (`bookingID`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `customer_fk`
    FOREIGN KEY (`customerID`)
    REFERENCES `LittleLemonDB`.`Customers` (`customerID`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `staff_fk`
    FOREIGN KEY (`staffID`)
    REFERENCES `LittleLemonDB`.`Staffs` (`staffID`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `delivery_fk`
    FOREIGN KEY (`deliveryID`)
    REFERENCES `LittleLemonDB`.`DeliveryStatus` (`deliveryID`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `LittleLemonDB`.`Menus`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `LittleLemonDB`.`Menus` (
  `menuItemID` INT NOT NULL,
  `name` VARCHAR(255) NULL,
  `category` VARCHAR(255) NULL,
  `price` DECIMAL NULL,
  PRIMARY KEY (`menuItemID`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `LittleLemonDB`.`OrderDetails`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `LittleLemonDB`.`OrderDetails` (
  `detailID` INT NOT NULL,
  `orderID` INT NOT NULL,
  `menuItemID` INT NOT NULL,
  `quantity` INT NOT NULL,
  `unitPrice` DECIMAL NOT NULL,
  PRIMARY KEY (`detailID`),
  INDEX `orderid_fk_idx` (`orderID` ASC) VISIBLE,
  INDEX `menuid_fk_idx` (`menuItemID` ASC) VISIBLE,
  CONSTRAINT `orderid_fk`
    FOREIGN KEY (`orderID`)
    REFERENCES `LittleLemonDB`.`Orders` (`orderID`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `menuid_fk`
    FOREIGN KEY (`menuItemID`)
    REFERENCES `LittleLemonDB`.`Menus` (`menuItemID`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
