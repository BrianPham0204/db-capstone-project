USE LittleLemonDB;

SELECT * FROM Bookings;
SELECT * FROM Customers;

ALTER TABLE Bookings
ADD COLUMN customerID INT;

ALTER TABLE Bookings
ADD CONSTRAINT customerID_fk
FOREIGN KEY (customerID) REFERENCES Customers(customerID)
ON UPDATE CASCADE
ON DELETE CASCADE;

INSERT INTO Bookings VALUES
(1,'2022-10-10',5,1),
(2,'2022-11-12',3,3),
(3,'2022-10-11',2,2),
(4,'2022-10-13',2,1);

DELIMITER //
CREATE PROCEDURE CheckBooking(IN date_book DATE, IN tableno INT) 
BEGIN
	SELECT * FROM Bookings WHERE date = date_book AND TableNo = tableno;
END //
DELIMITER ;

call CheckBooking("2022-11-12",3);

DESCRIBE Bookings;

DELIMITER //
CREATE TABLE raw_bookings_table(
bookingID INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
booking_date DATE NOT NULL,
table_no INT NOT NULL,
UNIQUE KEY uq_date_table(booking_date,table_num)
);
CREATE PROCEDURE AddValidBooking(IN p_booking_date DATE, IN p_table_no INT)
BEGIN
	DECLARE val INT DEFAULT 0;
    SET val = (SELECT COUNT(*) FROM raw_bookings_table WHERE booking_date = p_booking_date AND table_no = p_table_no);
	START TRANSACTION;
	IF val > 0 
		THEN ROLLBACK;
		SELECT CONCAT("The table number ",table_no," is not available on ", p_booking_date) 'Booking Status';
	ELSE 
		INSERT INTO Bookings(booking_date, table_no) VALUES(p_booking_date, table_no);
		COMMIT;
		SELECT CONCAT("The table number ",table_no," booking on ", p_booking_date, " is successful") 'Booking Status'
		END IF;
END //
DELIMITER ;