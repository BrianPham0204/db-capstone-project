import argparse
import csv
import datetime as dt
import os
import time
from pathlib import Path
import mysql.connector as connection

ROOT = Path(__file__).resolve().parent
DEFAULT_SQL_FILE = ROOT / "sql" / "LittleLemonDB_Schema.sql"

def parse_date(value: str):
    value = (value or "").strip()
    if not value:
        return None
    return dt.datetime.strptime(value, "%Y-%m-%d").date()

def parse_decimal(value: str):
    value = (value or "").strip()
    return float(value) if value else 0.0

def db_config(include_database = True):
    config = {
        "host": os.getenv("DB_HOST", "127.0.0.1"),
        "port": int(os.getenv("DB_PORT", 3306)),
        "user": os.getenv("DB_USER", "root"),
        "password": os.getenv("DB_PASSWORD", ""),
        "autocommit": False,
    }
    if include_database:
        config["database"] = os.getenv("DB_NAME", "restaurant_db")
    return config

def get_connection(include_database = True):
    return connection.connect(**db_config(include_database))

def execute_sql_file(cursor, sql_path: Path):
    delimiter = ";"
    buffer =[]

    with sql_path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("--"):
                continue
            buffer.append(line)
            joined = "".join(buffer).rstrip()
            if joined.endswith(delimiter):
                statement = joined[: -len(delimiter)].strip()
                if statement:
                    cursor.execute(statement)
                buffer = []
    remaining = "".join(buffer).strip()
    if remaining:
        cursor.execute(remaining)

def init_schema(sql_file : Path):
    with get_connection(include_database=False) as conn:
        with conn.cursor() as cursor:
            execute_sql_file(cursor, sql_file)
        conn.commit()

def normalize_row (row):
    clean = {}
    for k,v in row.items():
        if k is None:
            continue
        clean[k.strip()] = v.strip() if isinstance(v, str) else v
    return clean

def get_or_create_menu_id (cursor, menu_cache, row):
    menu_key = (
        row["Course Name"],
        row["Cuisine Name"],
        row["Starter Name"],
        row["Desert Name"],
        row["Drink"],
        row["Sides"],
    )

    if menu_key in menu_cache:
        return menu_cache[menu_key]
    
    cursor.execute(
        """
        SELECT MenuID FROM Menus
        WHERE CourseName = %s AND CuisineName = %s AND StarterName = %s
            AND DesertName = %s AND Drink = %s AND Sides = %s
        """,
        menu_key
    )

    hit = cursor.fetchone()
    if hit:
        menu_id = hit[0]
        menu_cache[menu_key] = menu_id
        return menu_id
    
    cursor.execute(
        """
        INSERT INTO Menus (CourseName, CuisineName, StarterName, DesertName, Drink, Sides)
        VALUES (%s, %s, %s, %s, %s, %s)
        """,
        menu_key
    )
    menu_id = cursor.lastrowid
    menu_cache[menu_key] = menu_id
    return menu_id

def load_data (data_file : Path):
    inserted = 0
    menu_cache = {}
    with get_connection(include_database=True) as conn:
        with conn.cursor() as cursor:
            with data_file.open("r", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                for raw in reader:
                    row = normalize_row(raw)
                    customer_id = row["Customer ID"]
                    cursor.execute(
                        """
                        INSERT INTO Customers (CustomerID, FirstName, LastName, Email, PhoneNumber, DateOfBirth)
                        VALUES (%s, %s, %s, %s, %s, %s)
                        ON DUPLICATE KEY UPDATE
                            CustomerName = VALUES(CustomerName),
                            City = VALUES(City),
                            Country = VALUES(Country),
                            PostalCode = VALUES(PostalCode),
                            CountryCode = VALUES(CountryCode)
                        """,
                        (
                            customer_id,
                            row["Customer Name"],
                            row["City"],
                            row["Country"],
                            row["Postal Code"],
                            row["Country Code"],
                        )
                    )

                    menu_id = get_or_create_menu_id(cursor, menu_cache, row)

                    cursor.execute(
                        """
                        INSERT INTO Orders (OrderID, OrderDate, DeliveryDate, CustomerID, MenuID, Cost,Sales, Quantity, Discount, DeliveryCost)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                        ON DUPLICATE KEY UPDATE
                            OrderDate = VALUES(OrderDate),
                            DeliveryDate = VALUES(DeliveryDate),
                            CustomerID = VALUES(CustomerID),
                            MenuID = VALUES(MenuID),
                            Cost = VALUES(Cost),
                            Sales = VALUES(Sales),
                            Quantity = VALUES(Quantity),
                            Discount = VALUES(Discount),
                            DeliveryCos = VALUES(DeliveryCost)
                        """,
                        (
                            row["Order ID"],
                            parse_date(row["Order Date"]),
                            parse_date(row["Delivery Date"]),
                            customer_id,
                            menu_id,
                            parse_decimal(row["Cost"]),
                            parse_decimal(row["Sales"]),
                            int(row["Quantity"]) if row["Quantity"] else 0,
                            parse_decimal(row["Discount"]),
                            parse_decimal(row["Delivery Cost"]),
                        ),
                    )

                    inserted += 1
                    if inserted % 1000 == 0:
                        conn.commit()
                        print(f"Processed rows: {inserted}")
            conn.commit()
    print(f"Finished processing. Total rows: {inserted}")

def next_booking_id(cursor):
    cursor.execute("SELECT COALESCE(MAX(BookingID),0) +1 FROM Bookings")
    return cursor.fetchone()[0]

def call_and_print(cursor, proc_name, args):
    print(f"\nCalling {proc_name} with args: {args}")
    cursor.callproc(proc_name, args)
    for result in cursor.stored_results():
        for row in result.fetchall():
            print(" ",row)

def monitor_bookings(seconds, interval):
    last_seen = set()
    end_at = time.time() + seconds

    with get_connection(include_database=True) as conn:
        with conn.cursor(dictionary= True) as cursor:
            print(f"Monitoring booking change for {seconds} seconds...")
            while time.time() < end_at:
                cursor.execute("SELECT MAX(UpdatedAt) as max_updated FROM Bookings")
                current = cursor.fetchone()["max_updated"]
                if current and (last_seen is None or current > last_seen):
                    since = last_seen or dt.datetime(1970,1,1)
                    cursor.execute(
                        """
                        SELECT BookingID,CustomerID, TableNo, BookingDate, BookingStatus, UpdatedAt FROM Bookings
                        WHERE UpdatedAt > %s
                        ORDER BY UPdatedAt ASC
                        """,
                        (since,),
                    )

                    changed_rows = cursor.fetchall()
                    for row in changed_rows:
                        print("Booking changed:",row)
                    last_seen = current
                time.sleep(interval)

def write_csv(path: Path, headers, rows):
    with path.open("w", encoding="utf-8", newline="") as f:
        write = csv.writer(f)
        write.writerow(headers)
        write.writerows(rows)

def export_tableau(outdir: Path):
    outdir.mkdir(parents=True, exist_ok=True)

    sales_csv = outdir / "sales_by_cuisine.csv"
    bookings_csv = outdir / "bookings_by_date.csv"
    monthly_csv = outdir / "monthly_sales.csv"

    with get_connection(include_database=True) as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                SELECT m.CuisineName, COUNT(*) OrdersCount, ROUND(SUM(o.Sales),2) as TotalSales
                FROM Orders o
                JOIN Menus m ON o.MenuID = m.MenuID
                GROUP BY CuisineName
                ORDER BY TotalSales DESC
                """
            )

            rows = cursor.fetchall()
            write_csv(sales_csv, ["CuisineName", "OrdersCount", "TotalSales"], rows)

            cursor.execute(
                """
                SELECT BookingDate, TableNo, BookingStatus, COUNT(*) as BookingCount
                FROM Bookings
                GROUP BY BookingDate, TableNo, BookingStatus
                ORDER BY BookingDate, TableNo
                """
            )
            rows = cursor.fetchall()
            write_csv(bookings_csv, ["BookingDate", "TableNo", "BookingStatus", "BookingCount"], rows)

            cursor.execute(
                """
                SELECT DATE_FORMAT(ORderDate, '%Y-%m') as Month, ROUND(SUM(Sales),2) as TotalSales
                FROM Orders
                GROUP BY DATE_FORMAT(OrderDate, '%Y-%m')
                ORDER BY Month
                """
            )
            rows = cursor.fetchall()
            write_csv(monthly_csv, ["Month", "TotalSales"], rows)

    print(f"Exported Tableau data to {outdir}")

def parse_args():
    parser = argparse.ArgumentParser(description="Little Lemon Restaurant DB Client")
    parser.add_argument("init-schema", action="store_true", help="Initialize database schema")
    parser.add_argument("load-data", type=Path, help="Path to CSV file to load data from")
    parser.add_argument("monitor-bookings", type=int, help="Monitor booking changes for given seconds")
    parser.add_argument("export-tableau", type=Path, help="Export data for Tableau to given directory")
    return parser.parse_args()

def main():
    args = parse_args()
    if args.command == "init-schema":
        init_schema(args.sql_file)
    elif args.command == "load-data":
        load_data(args.data_file)
    elif args.command == "monitor-bookings":
        monitor_bookings(args.seconds, args.interval)
    elif args.command == "export-tableau":
        export_tableau(args.outdir)
    else:
        raise ValueError("Unknown command: {args.command}")

if __name__ == "__main__":
    main()