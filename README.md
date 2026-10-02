# SQL Data Warehouse Project

## Project Overview

This project builds a simple Data Warehouse using SQL Server based on the Superstore dataset.

The main goal is to organize sales data into a **Star Schema** and use SQL queries to analyze sales and profit.

## Tools Used

* SQL Server
* SQL Server Management Studio (SSMS)
* Excel
* GitHub

## Data Warehouse Design

The project uses a Star Schema consisting of:

* **FactSales** – stores sales transactions and measures such as Sales and Profit.
* **DimDate** – contains date-related information.
* **DimCustomer** – contains customer information.
* **DimProduct** – contains product information.
* **DimLocation** – contains location information.

### Star Schema

The `FactSales` table is connected to the dimension tables through foreign keys.

```text
                 DimDate
                    |
                    |
DimCustomer ---- FactSales ---- DimProduct
                    |
                    |
              DimLocation
```

## Project Steps

1. Prepare and clean the source data.
2. Create the dimension tables.
3. Create the fact table.
4. Insert the data into the Data Warehouse.
5. Build the Star Schema relationships.
6. Write SQL queries for sales and profit analysis.

## SQL Analysis

The project includes analytical queries such as:

* Total Sales by Product
* Total Profit by Product
* Sales by Customer
* Sales by Location
* Sales by Date
* Top-performing products

## Project Structure

```text
SQL-Data-Warehouse-Project/
│
├── DataWarehouse.sql
└── README.md
```

## Dataset

The project is based on the Superstore dataset, which contains information about orders, customers, products, dates, locations, sales, and profit.

## Learning Outcomes

Through this project, I practiced:

* Relational database design
* Data Warehousing concepts
* Star Schema
* Fact and Dimension tables
* Primary and Foreign Keys
* SQL JOINs
* Aggregation functions
* GROUP BY and ORDER BY
* Data analysis using SQL Server
