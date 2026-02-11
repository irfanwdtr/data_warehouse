# Sales Data Warehouse – Star Schema Implementation (MySQL)

## Project Overview

Project ini merupakan implementasi **Data Warehouse** menggunakan pendekatan **Star Schema** di MySQL.

Tujuan utama project ini adalah:

- Membangun arsitektur Data Warehouse sederhana  
- Mengimplementasikan proses ETL (Staging → Dimension → Fact)  
- Membuat Data Mart untuk kebutuhan reporting  
- Mensimulasikan query Business Intelligence (BI)  

Dataset yang digunakan adalah data transaksi penjualan (Sales Transaction Data) dengan 24 baris sample data.

---

## Architecture Overview

Project ini terdiri dari beberapa layer:

### 1️⃣ Staging Layer

Tabel: `stg_sales`

- Berisi data mentah hasil input / CSV  
- Digunakan sebagai sumber untuk membangun dimension dan fact  
- Tidak digunakan langsung untuk reporting  

---

### 2️⃣ Data Warehouse Layer (Star Schema)

Menggunakan pendekatan **Star Schema**, terdiri dari:

#### ⭐ Fact Table

Tabel: `fact_sales`

- Menyimpan transaksi penjualan (level granular)  
- Berisi foreign key ke dimension tables  
- Memiliki kolom:
  - `qty`
  - `harga`
  - `revenue` (generated column: qty × harga)  

---

#### 📐 Dimension Tables

- `dim_time` → Informasi waktu (tahun, bulan, hari, kuartal)  
- `dim_store` → Informasi toko dan kota  
- `dim_product` → Informasi produk dan kategori  
- `dim_customer` → Informasi customer  
- `dim_salesperson` → Informasi sales  

Semua dimension menggunakan **surrogate key (AUTO_INCREMENT)**.

---

## ETL Flow

Proses ETL dalam project ini:

1. Load data ke `stg_sales`  
2. Populate `dim_*` dari staging (SELECT DISTINCT)  
3. Lookup surrogate key  
4. Insert ke `fact_sales`  
5. Generate revenue otomatis  

Semua proses dilakukan menggunakan SQL.

---

## Data Mart Layer

### 1️⃣ Logical Data Mart (VIEW)

Tabel: `mart_sales`

- Merupakan join antara fact dan dimension  
- Digunakan untuk reporting  
- Tidak menyimpan data fisik  
- Selalu up-to-date dengan fact table  

Contoh penggunaan:

```sql
SELECT toko, SUM(revenue)
FROM mart_sales
GROUP BY toko;
 ```

### 2️⃣ Physical Data Mart (Summary Table)
Tabel: `mart_sales_summary_by_store`
- Berisi agregasi revenue dan quantity per toko
- Digunakan untuk optimasi performa reporting
- Data disimpan secara fisik

contoh penggunaan
Total Revenue per Store
```SELECT toko, SUM(revenue)
FROM mart_sales
GROUP BY toko;
```

top 2 product by revenue
```
SELECT produk, SUM(revenue)
FROM mart_sales
GROUP BY produk
ORDER BY SUM(revenue) DESC
LIMIT 5;
```
renvenue per city / kota
```
SELECT kota, SUM(revenue)
FROM mart_sales
GROUP BY kota;
```


Tech Stack
- ChatGPT (digunakan untuk bantuan pengembangan dan dukungan dokumentasi)  
- MySQL Workbench
- SQL (DDL & DML)
