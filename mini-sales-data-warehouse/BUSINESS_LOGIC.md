## Business Requirement & Data Modeling Logic

### 1️⃣ Business Context

Perusahaan ingin menganalisis performa penjualan berdasarkan:

- Toko
- Kota
- Produk
- Kategori
- Salesperson
- Customer
- Waktu (hari, bulan, tahun)

Tujuan analisis:

- Mengetahui total revenue per toko
- Mengidentifikasi produk dengan penjualan tertinggi
- Menganalisis performa sales
- Melihat tren penjualan per bulan
- Membandingkan performa antar kota

---

### 2️⃣ Grain Definition (Level of Detail)

Grain dari tabel fact ditentukan sebagai:

> Satu baris = satu transaksi penjualan produk pada tanggal tertentu.

Artinya setiap record merepresentasikan:
- 1 produk
- 1 toko
- 1 customer
- 1 salesperson
- 1 tanggal transaksi

---

### 3️⃣ Fact Table Logic

Tabel: `fact_sales`

Fact table menyimpan data numerik yang dapat diukur (measurable metrics).

Metric yang dipilih:

- `qty` → jumlah unit terjual
- `harga` → harga per unit
- `revenue` → qty × harga


Karena fact itu:
- Nilainya bisa dijumlahkan (additive)
- Digunakan untuk analisis performa bisnis
- Menjadi pusat agregasi

---

### 4️⃣ Dimension Table Logic

Attribute yang bersifat deskriptif dipisahkan ke dimension table.

#### dim_time
Digunakan untuk:
- Analisis tren waktu
- Group by bulan, tahun, kuartal

#### dim_store
Digunakan untuk:
- Analisis performa per toko
- Analisis performa per kota

#### dim_product
Digunakan untuk:
- Analisis kategori produk
- Identifikasi produk paling laris

#### dim_customer
Digunakan untuk:
- Analisis perilaku customer
- Identifikasi customer aktif

#### dim_salesperson
Digunakan untuk:
- Evaluasi performa sales
- Perbandingan antar sales

---

### 5️⃣ Why Star Schema?

Dipilih Star Schema karena:

- Struktur sederhana dan mudah dipahami
- Query aggregation lebih cepat
- Cocok untuk kebutuhan reporting dan BI
- Mudah dikembangkan ke data mart

Struktur:

           dim_time
               |
dim_store — fact_sales — dim_product
               |
         dim_customer
               |
        dim_salesperson

---

### 6️⃣ Data Mart Logic

Data Mart dibuat untuk:

- Menyederhanakan query BI
- Mengurangi kompleksitas join
- Menyediakan dataset siap pakai untuk reporting tools

---

### 7️⃣ Analytical Metrics Defined

Beberapa KPI yang didefinisikan:

- Total Revenue = SUM(qty × harga)
- Total Quantity Sold = SUM(qty)
- Revenue per Store
- Revenue per City
- Revenue per Product
- Revenue per Salesperson
- Monthly Sales Trend

---

