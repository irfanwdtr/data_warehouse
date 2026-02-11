/* =========================================================
   SALES DATA WAREHOUSE (STAR SCHEMA) - MySQL 8.x
   End-to-end: DB -> Staging -> Dimensions -> Fact -> Mart
   ========================================================= */

-- 0) RESET DATABASE (untuk latihan/portfolio)
DROP DATABASE IF EXISTS sales_dw;

CREATE DATABASE sales_dw
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE sales_dw;

-- =========================================================
-- 1) STAGING TABLE (tempat data mentah masuk)
-- =========================================================
DROP TABLE IF EXISTS stg_sales;

CREATE TABLE stg_sales (
  tanggal   DATE NOT NULL,
  toko      VARCHAR(50) NOT NULL,
  kota      VARCHAR(50) NOT NULL,
  produk    VARCHAR(50) NOT NULL,
  kategori  VARCHAR(50) NOT NULL,
  sales     VARCHAR(50) NOT NULL,
  customer  VARCHAR(20) NOT NULL,
  qty       INT NOT NULL,
  harga     INT NOT NULL
);

-- =========================================================
-- 2) LOAD DATA INTO STAGING
--   
-- =========================================================
INSERT INTO stg_sales (tanggal,toko,kota,produk,kategori,sales,customer,qty,harga) VALUES
('2024-01-01','Toko A','Jakarta','Pensil','ATK','Andi','C001',10,2000),
('2024-01-01','Toko A','Jakarta','Buku','ATK','Andi','C002',5,5000),
('2024-01-02','Toko B','Bandung','Pulpen','ATK','Budi','C003',7,3000),
('2024-01-02','Toko A','Jakarta','Buku','ATK','Andi','C001',2,5000),
('2024-01-03','Toko C','Surabaya','Pensil','ATK','Citra','C004',12,2000),
('2024-01-03','Toko C','Surabaya','Spidol','ATK','Citra','C005',6,8000),
('2024-01-04','Toko A','Jakarta','Pulpen','ATK','Andi','C006',9,3000),
('2024-01-04','Toko B','Bandung','Buku','ATK','Budi','C003',4,5000),
('2024-01-05','Toko D','Medan','Pensil','ATK','Dedi','C007',20,2000),
('2024-01-05','Toko D','Medan','Buku','ATK','Dedi','C008',10,5000),
('2024-01-06','Toko B','Bandung','Spidol','ATK','Budi','C009',3,8000),
('2024-01-06','Toko A','Jakarta','Penghapus','ATK','Andi','C002',15,1500),
('2024-01-07','Toko C','Surabaya','Buku','ATK','Citra','C004',7,5000),
('2024-01-07','Toko C','Surabaya','Pulpen','ATK','Citra','C010',11,3000),
('2024-01-08','Toko E','Yogyakarta','Pensil','ATK','Eka','C011',8,2000),
('2024-01-08','Toko E','Yogyakarta','Buku','ATK','Eka','C012',6,5000),
('2024-01-09','Toko B','Bandung','Penghapus','ATK','Budi','C003',14,1500),
('2024-01-09','Toko D','Medan','Spidol','ATK','Dedi','C013',5,8000),
('2024-01-10','Toko A','Jakarta','Buku','ATK','Andi','C014',3,5000),
('2024-01-10','Toko A','Jakarta','Pensil','ATK','Andi','C001',6,2000),
('2024-01-11','Toko E','Yogyakarta','Pulpen','ATK','Eka','C015',10,3000),
('2024-01-11','Toko C','Surabaya','Penghapus','ATK','Citra','C016',18,1500),
('2024-01-12','Toko B','Bandung','Pensil','ATK','Budi','C017',9,2000),
('2024-01-12','Toko D','Medan','Buku','ATK','Dedi','C018',4,5000);

-- (B) Opsional: kalau mau load dari CSV
-- NOTE: tergantung setting secure-file-priv & permission OS.
-- LOAD DATA INFILE 'C:/path/sales_data.csv'
-- INTO TABLE stg_sales
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS
-- (tanggal,toko,kota,produk,kategori,sales,customer,qty,harga);

-- =========================================================
-- 3) DIMENSION TABLES
-- =========================================================
DROP TABLE IF EXISTS dim_time;
DROP TABLE IF EXISTS dim_store;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_salesperson;

CREATE TABLE dim_time (
  time_key   INT PRIMARY KEY,        -- YYYYMMDD
  tanggal    DATE NOT NULL,
  tahun      SMALLINT NOT NULL,
  bulan      TINYINT NOT NULL,
  nama_bulan VARCHAR(15) NOT NULL,
  hari       TINYINT NOT NULL,
  nama_hari  VARCHAR(15) NOT NULL,
  kuartal    TINYINT NOT NULL
);

CREATE TABLE dim_store (
  store_key BIGINT AUTO_INCREMENT PRIMARY KEY,
  toko      VARCHAR(50) NOT NULL,
  kota      VARCHAR(50) NOT NULL,
  UNIQUE KEY ux_store_toko_kota (toko, kota)
);

CREATE TABLE dim_product (
  product_key BIGINT AUTO_INCREMENT PRIMARY KEY,
  produk      VARCHAR(50) NOT NULL,
  kategori    VARCHAR(50) NOT NULL,
  UNIQUE KEY ux_product_produk_kategori (produk, kategori)
);

CREATE TABLE dim_customer (
  customer_key BIGINT AUTO_INCREMENT PRIMARY KEY,
  customer_code VARCHAR(20) NOT NULL,
  UNIQUE KEY ux_customer_code (customer_code)
);

CREATE TABLE dim_salesperson (
  salesperson_key BIGINT AUTO_INCREMENT PRIMARY KEY,
  sales VARCHAR(50) NOT NULL,
  UNIQUE KEY ux_sales_name (sales)
);

-- =========================================================
-- 4) POPULATE DIMENSIONS FROM STAGING
-- =========================================================
INSERT INTO dim_time (time_key, tanggal, tahun, bulan, nama_bulan, hari, nama_hari, kuartal)
SELECT DISTINCT
  CAST(DATE_FORMAT(tanggal, '%Y%m%d') AS UNSIGNED) AS time_key,
  tanggal,
  YEAR(tanggal),
  MONTH(tanggal),
  MONTHNAME(tanggal),
  DAY(tanggal),
  DAYNAME(tanggal),
  QUARTER(tanggal)
FROM stg_sales;

INSERT INTO dim_store (toko, kota)
SELECT DISTINCT TRIM(toko), TRIM(kota)
FROM stg_sales;

INSERT INTO dim_product (produk, kategori)
SELECT DISTINCT TRIM(produk), TRIM(kategori)
FROM stg_sales;

INSERT INTO dim_customer (customer_code)
SELECT DISTINCT TRIM(customer)
FROM stg_sales;

INSERT INTO dim_salesperson (sales)
SELECT DISTINCT TRIM(sales)
FROM stg_sales;

-- =========================================================
-- 5) FACT TABLE
-- =========================================================
DROP TABLE IF EXISTS fact_sales;

CREATE TABLE fact_sales (
  sales_id BIGINT AUTO_INCREMENT PRIMARY KEY,

  time_key INT NOT NULL,
  store_key BIGINT NOT NULL,
  product_key BIGINT NOT NULL,
  customer_key BIGINT NOT NULL,
  salesperson_key BIGINT NOT NULL,

  qty INT NOT NULL,
  harga INT NOT NULL,

  -- revenue otomatis (materialized)
  revenue BIGINT AS (qty * harga) STORED,

  -- foreign keys (opsional tapi bagus untuk portfolio)
  CONSTRAINT fk_fact_time        FOREIGN KEY (time_key)        REFERENCES dim_time(time_key),
  CONSTRAINT fk_fact_store       FOREIGN KEY (store_key)       REFERENCES dim_store(store_key),
  CONSTRAINT fk_fact_product     FOREIGN KEY (product_key)     REFERENCES dim_product(product_key),
  CONSTRAINT fk_fact_customer    FOREIGN KEY (customer_key)    REFERENCES dim_customer(customer_key),
  CONSTRAINT fk_fact_salesperson FOREIGN KEY (salesperson_key) REFERENCES dim_salesperson(salesperson_key)
);

-- index untuk performa query
CREATE INDEX idx_fact_time   ON fact_sales(time_key);
CREATE INDEX idx_fact_store  ON fact_sales(store_key);
CREATE INDEX idx_fact_prod   ON fact_sales(product_key);

-- =========================================================
-- 6) LOAD FACT FROM STAGING (lookup surrogate keys)
-- =========================================================
INSERT INTO fact_sales (time_key, store_key, product_key, customer_key, salesperson_key, qty, harga)
SELECT
  dt.time_key,
  ds.store_key,
  dp.product_key,
  dc.customer_key,
  dsp.salesperson_key,
  s.qty,
  s.harga
FROM stg_sales s
JOIN dim_time dt ON dt.tanggal = s.tanggal
JOIN dim_store ds ON ds.toko = TRIM(s.toko) AND ds.kota = TRIM(s.kota)
JOIN dim_product dp ON dp.produk = TRIM(s.produk) AND dp.kategori = TRIM(s.kategori)
JOIN dim_customer dc ON dc.customer_code = TRIM(s.customer)
JOIN dim_salesperson dsp ON dsp.sales = TRIM(s.sales);

-- =========================================================
-- 7) DATA MART (LOGICAL) - VIEW
-- =========================================================
DROP VIEW IF EXISTS mart_sales;

CREATE VIEW mart_sales AS
SELECT
  dt.tanggal,
  dt.tahun,
  dt.bulan,
  dt.nama_bulan,
  ds.toko,
  ds.kota,
  dp.produk,
  dp.kategori,
  dsp.sales AS salesperson,
  dc.customer_code,
  f.qty,
  f.harga,
  f.revenue
FROM fact_sales f
JOIN dim_time dt ON f.time_key = dt.time_key
JOIN dim_store ds ON f.store_key = ds.store_key
JOIN dim_product dp ON f.product_key = dp.product_key
JOIN dim_salesperson dsp ON f.salesperson_key = dsp.salesperson_key
JOIN dim_customer dc ON f.customer_key = dc.customer_key;

-- =========================================================
-- 8) QUICK CHECKS (portfolio-friendly)
-- =========================================================
-- cek rowcount
SELECT 'stg_sales' t, COUNT(*) c FROM stg_sales
UNION ALL SELECT 'dim_time', COUNT(*) FROM dim_time
UNION ALL SELECT 'dim_store', COUNT(*) FROM dim_store
UNION ALL SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL SELECT 'dim_salesperson', COUNT(*) FROM dim_salesperson
UNION ALL SELECT 'fact_sales', COUNT(*) FROM fact_sales;

-- contoh query BI: revenue per toko
SELECT toko, SUM(revenue) AS total_revenue
FROM mart_sales
GROUP BY toko
ORDER BY total_revenue DESC;

-- contoh query BI: top produk
SELECT produk, SUM(revenue) AS total_revenue
FROM mart_sales
GROUP BY produk
ORDER BY total_revenue DESC
LIMIT 5;

-- =========================================================
-- 9) BONUS: PHYSICAL MART (TABLE SUMMARY) - OPTIONAL
--    kalau mau data mart beneran tersimpan sebagai tabel agregat
-- =========================================================
DROP TABLE IF EXISTS mart_sales_summary_by_store;

CREATE TABLE mart_sales_summary_by_store AS
SELECT
  toko,
  kota,
  SUM(revenue) AS total_revenue,
  SUM(qty) AS total_qty
FROM mart_sales
GROUP BY toko, kota;

-- cek physical mart
SELECT * FROM mart_sales_summary_by_store ORDER BY total_revenue DESC;
