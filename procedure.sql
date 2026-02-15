SHOW DATABASES;
USE littleLemon;
SHOW TABLES;

CREATE VIEW OrdersView AS
(
	SELECT o.OrderID, o.Quantity, o.TotalCost
    FROM Orders o
    WHERE o.Quantity > 2
);

SELECT * FROM OrdersView;

USE restaurant_db;
SHOW TABLES;
SELECT * FROM order_details;
SELECT * FROM order_menu;
SELECT * FROM menu_items;

DELIMITER //
CREATE PROCEDURE GetMaxQuantity()
BEGIN
	SELECT COUNT(*) as 'MAX Quantity In Order'
    FROM order_details
    GROUP BY order_id
    ORDER BY COUNT(*) DESC
    LIMIT 1;
END;
DELIMITER;

DROP PROCEDURE GetMaxQuantity;
CALL GetMaxQuantity();

SET @id = 1;
PREPARE GetOrderDetail FROM 'SELECT order_id, item_name, price FROM order_menu WHERE order_id = ?';
EXECUTE GetOrderDetail USING @id;

DELIMITER //
CREATE PROCEDURE CancelOrder(IN orderID INT)
BEGIN
	DELETE FROM order_details
    WHERE order_id = orderID;
    SELECT CONCAT("Order ",orderID, " is cancelled") AS Confirmation;
END//
DELIMITER ;

DROP PROCEDURE CancelOrder;
SET SQL_SAFE_UPDATES = 0;
CALL CancelOrder(166);

DESCRIBE Bookings;

-- AddBooking information into Bookings Table

DELIMITER //
CREATE PROCEDURE AddBooking(IN p_bookingid INT, IN p_customerid INT, IN p_tableno INT, IN p_bookingdate DATE)
BEGIN
	DECLARE message VARCHAR(255) DEFAULT "New booking added";
    
	START TRANSACTION;
	INSERT INTO Bookings(bookingID, customerID, TableNo, date) 
    VALUES(p_bookingid, p_customerid, p_tableno, p_bookingdate);
    COMMIT;
	SELECT message as Confirmation;
END//

CREATE PROCEDURE UpdateBooking (IN p_bookingid INT, IN p_bookingdate DATE)
BEGIN
	UPDATE Bookings
    SET date = p_bookingdate
    WHERE bookingID = p_bookingid;
    SELECT CONCAT("The booking id: ", p_bookingid," is updated on ",p_bookingdate) Confirmation;
END//

CREATE PROCEDURE CancelBooking(IN p_bookingid INT)
BEGIN
	DELETE FROM Bookings
    WHERE bookingID = p_bookingid;
    SELECT CONCAT("The booking id: ", p_bookingid," is cancelled");
END//


DELIMITER ;

-- DROP PROCEDURE AddBooking; 


