/* =========================================================
   DATA WAREHOUSE RUMAH SAKIT (Star Schema) - PostgreSQL
   Fokus: 1 FACT utama = fact_kunjungan (1 baris = 1 kunjungan)
   DIM: waktu, pasien, dokter, poli, pembayaran, diagnosa, tindakan
   ========================================================= */

-- 0) Schema
CREATE SCHEMA IF NOT EXISTS dw_rs;

-- 1) DIM: Waktu (Tanggal)
CREATE TABLE IF NOT EXISTS dw_rs.dim_waktu (
  waktu_key     INT PRIMARY KEY,           -- contoh: 20260211
  tanggal       DATE NOT NULL UNIQUE,
  hari          SMALLINT NOT NULL,
  bulan         SMALLINT NOT NULL,
  nama_bulan    VARCHAR(12) NOT NULL,
  kuartal       SMALLINT NOT NULL,
  tahun         SMALLINT NOT NULL,
  minggu_ke     SMALLINT NOT NULL,
  is_weekend    BOOLEAN NOT NULL
);

-- 2) DIM: Pasien
CREATE TABLE IF NOT EXISTS dw_rs.dim_pasien (
  pasien_key        BIGSERIAL PRIMARY KEY,
  pasien_id         TEXT NOT NULL UNIQUE,          -- business key (MRN/No RM)
  nama_pasien       TEXT,
  jenis_kelamin     CHAR(1),                       -- L/P
  tgl_lahir         DATE,
  umur_tahun        SMALLINT,
  kota              TEXT,
  provinsi          TEXT,
  tipe_pasien       TEXT,                          -- Umum/BPJS/Asuransi (opsional)
  created_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 3) DIM: Dokter
CREATE TABLE IF NOT EXISTS dw_rs.dim_dokter (
  dokter_key        BIGSERIAL PRIMARY KEY,
  dokter_id         TEXT NOT NULL UNIQUE,          -- business key (NIP/ID dokter)
  nama_dokter       TEXT NOT NULL,
  spesialisasi      TEXT,
  status_dokter     TEXT,                          -- aktif/nonaktif
  created_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 4) DIM: Poli
CREATE TABLE IF NOT EXISTS dw_rs.dim_poli (
  poli_key          BIGSERIAL PRIMARY KEY,
  poli_id           TEXT NOT NULL UNIQUE,          -- business key
  nama_poli         TEXT NOT NULL,
  tipe_poli         TEXT,                          -- Rawat Jalan/IGD/Rawat Inap (opsional)
  lantai            TEXT,
  created_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 5) DIM: Metode Pembayaran
CREATE TABLE IF NOT EXISTS dw_rs.dim_pembayaran (
  pembayaran_key    BIGSERIAL PRIMARY KEY,
  pembayaran_id     TEXT NOT NULL UNIQUE,          -- contoh: CASH/BPJS/ASURANSI
  nama_pembayaran   TEXT NOT NULL,
  kategori          TEXT,                          -- Umum/Jaminan
  created_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 6) DIM: Diagnosa (sederhana)
CREATE TABLE IF NOT EXISTS dw_rs.dim_diagnosa (
  diagnosa_key      BIGSERIAL PRIMARY KEY,
  diagnosa_code     TEXT NOT NULL UNIQUE,          -- contoh: ICD10
  diagnosa_nama     TEXT NOT NULL,
  grup              TEXT,
  created_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 7) DIM: Tindakan (sederhana)
CREATE TABLE IF NOT EXISTS dw_rs.dim_tindakan (
  tindakan_key      BIGSERIAL PRIMARY KEY,
  tindakan_code     TEXT NOT NULL UNIQUE,          -- contoh: kode tindakan internal
  tindakan_nama     TEXT NOT NULL,
  kategori          TEXT,                          -- Lab/Radiologi/Operasi/dll
  created_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 8) FACT: Kunjungan Pasien (>= 20 kolom)
--    1 baris = 1 kunjungan / 1 episode kunjungan
CREATE TABLE IF NOT EXISTS dw_rs.fact_kunjungan (
  fact_key            BIGSERIAL PRIMARY KEY,

  -- FK ke DIM
  waktu_key           INT NOT NULL REFERENCES dw_rs.dim_waktu(waktu_key),
  pasien_key          BIGINT NOT NULL REFERENCES dw_rs.dim_pasien(pasien_key),
  dokter_key          BIGINT NOT NULL REFERENCES dw_rs.dim_dokter(dokter_key),
  poli_key            BIGINT NOT NULL REFERENCES dw_rs.dim_poli(poli_key),
  pembayaran_key      BIGINT NOT NULL REFERENCES dw_rs.dim_pembayaran(pembayaran_key),
  diagnosa_key        BIGINT REFERENCES dw_rs.dim_diagnosa(diagnosa_key),
  tindakan_key        BIGINT REFERENCES dw_rs.dim_tindakan(tindakan_key),

  -- ID dari sistem sumber (degenerate dimension / trace)
  kunjungan_id        TEXT NOT NULL,               -- nomor kunjungan/registrasi dari HIS
  no_antrian          TEXT,
  sumber_sistem       TEXT NOT NULL DEFAULT 'HIS',

  -- Detail kunjungan
  jenis_kunjungan     TEXT NOT NULL,               -- Rawat Jalan / IGD / Rawat Inap
  waktu_masuk         TIMESTAMP,
  waktu_keluar        TIMESTAMP,
  status_kunjungan    TEXT NOT NULL DEFAULT 'SELESAI',   -- SELESAI/BATAL/ONGOING
  is_rujukan          BOOLEAN NOT NULL DEFAULT FALSE,
  rujukan_dari        TEXT,                        -- Puskesmas/RS lain/dll
  kelas_perawatan     TEXT,                        -- VIP/Kls 1/2/3 (kalau inap)
  kamar               TEXT,                        -- nomor/kelas kamar (opsional)
  lama_rawat_hari     INT NOT NULL DEFAULT 0 CHECK (lama_rawat_hari >= 0),

  -- Measures (angka)
  jumlah_tindakan     INT NOT NULL DEFAULT 0 CHECK (jumlah_tindakan >= 0),
  biaya_konsultasi    NUMERIC(14,2) NOT NULL DEFAULT 0,
  biaya_tindakan      NUMERIC(14,2) NOT NULL DEFAULT 0,
  biaya_obat          NUMERIC(14,2) NOT NULL DEFAULT 0,
  biaya_kamar         NUMERIC(14,2) NOT NULL DEFAULT 0,
  biaya_lain          NUMERIC(14,2) NOT NULL DEFAULT 0,
  diskon              NUMERIC(14,2) NOT NULL DEFAULT 0,
  pajak               NUMERIC(14,2) NOT NULL DEFAULT 0,

  total_biaya         NUMERIC(14,2) GENERATED ALWAYS AS
    (biaya_konsultasi + biaya_tindakan + biaya_obat + biaya_kamar + biaya_lain - diskon + pajak) STORED,

  -- Audit DW
  load_batch_id       TEXT,
  ingested_at         TIMESTAMP NOT NULL DEFAULT NOW(),

  -- Hindari dobel load kunjungan yang sama
  UNIQUE (kunjungan_id, sumber_sistem)
);

-- Index untuk performa analitik
CREATE INDEX IF NOT EXISTS idx_fact_kunjungan_waktu      ON dw_rs.fact_kunjungan(waktu_key);
CREATE INDEX IF NOT EXISTS idx_fact_kunjungan_poli       ON dw_rs.fact_kunjungan(poli_key);
CREATE INDEX IF NOT EXISTS idx_fact_kunjungan_dokter     ON dw_rs.fact_kunjungan(dokter_key);
CREATE INDEX IF NOT EXISTS idx_fact_kunjungan_pasien     ON dw_rs.fact_kunjungan(pasien_key);
CREATE INDEX IF NOT EXISTS idx_fact_kunjungan_bayar      ON dw_rs.fact_kunjungan(pembayaran_key);
CREATE INDEX IF NOT EXISTS idx_fact_kunjungan_diagnosa   ON dw_rs.fact_kunjungan(diagnosa_key);

-- =========================================================
-- SEED DATA (contoh) + generate dim_waktu
-- =========================================================

-- Generate dim_waktu untuk 2025-01-01 s/d 2026-12-31 (ubah sesuai kebutuhan)
INSERT INTO dw_rs.dim_waktu (
  waktu_key, tanggal, hari, bulan, nama_bulan, kuartal, tahun, minggu_ke, is_weekend
)
SELECT
  (EXTRACT(YEAR FROM d)::int * 10000 + EXTRACT(MONTH FROM d)::int * 100 + EXTRACT(DAY FROM d)::int) AS waktu_key,
  d::date AS tanggal,
  EXTRACT(DAY FROM d)::int AS hari,
  EXTRACT(MONTH FROM d)::int AS bulan,
  TO_CHAR(d, 'Mon') AS nama_bulan,
  EXTRACT(QUARTER FROM d)::int AS kuartal,
  EXTRACT(YEAR FROM d)::int AS tahun,
  EXTRACT(WEEK FROM d)::int AS minggu_ke,
  (EXTRACT(ISODOW FROM d) IN (6,7)) AS is_weekend
FROM generate_series(DATE '2025-01-01', DATE '2026-12-31', INTERVAL '1 day') d
ON CONFLICT (waktu_key) DO NOTHING;

-- Seed DIM contoh
INSERT INTO dw_rs.dim_pembayaran (pembayaran_id, nama_pembayaran, kategori)
VALUES
('CASH','Tunai','Umum'),
('BPJS','BPJS','Jaminan'),
('ASURANSI','Asuransi','Jaminan')
ON CONFLICT (pembayaran_id) DO NOTHING;

INSERT INTO dw_rs.dim_poli (poli_id, nama_poli, tipe_poli, lantai)
VALUES
('POLI-UMUM','Poli Umum','Rawat Jalan','1'),
('POLI-ANAK','Poli Anak','Rawat Jalan','2'),
('IGD','Instalasi Gawat Darurat','IGD','G')
ON CONFLICT (poli_id) DO NOTHING;

INSERT INTO dw_rs.dim_dokter (dokter_id, nama_dokter, spesialisasi, status_dokter)
VALUES
('D001','dr. Andi','Umum','aktif'),
('D002','dr. Sari, Sp.A','Anak','aktif')
ON CONFLICT (dokter_id) DO NOTHING;

INSERT INTO dw_rs.dim_diagnosa (diagnosa_code, diagnosa_nama, grup)
VALUES
('J06.9','ISPA (infeksi saluran pernapasan akut), tidak spesifik','ISPA'),
('K30','Dispepsia','Pencernaan')
ON CONFLICT (diagnosa_code) DO NOTHING;

INSERT INTO dw_rs.dim_tindakan (tindakan_code, tindakan_nama, kategori)
VALUES
('T001','Konsultasi Dokter','Konsultasi'),
('T010','Tes Lab Darah Sederhana','Lab')
ON CONFLICT (tindakan_code) DO NOTHING;

-- Pasien contoh
INSERT INTO dw_rs.dim_pasien (pasien_id, nama_pasien, jenis_kelamin, tgl_lahir, umur_tahun, kota, provinsi, tipe_pasien)
VALUES
('RM0001','Budi','L','1995-05-01',30,'Jakarta','DKI Jakarta','BPJS'),
('RM0002','Ayu','P','2000-09-12',25,'Bandung','Jawa Barat','Umum')
ON CONFLICT (pasien_id) DO NOTHING;

-- =========================================================
-- CONTOH INSERT FACT (pakai lookup key dari DIM)
-- =========================================================

-- 1) Ambil key-key dim yang diperlukan (contoh lewat CTE)
WITH k AS (
  SELECT
    (SELECT waktu_key FROM dw_rs.dim_waktu WHERE tanggal = DATE '2026-02-11') AS waktu_key,
    (SELECT pasien_key FROM dw_rs.dim_pasien WHERE pasien_id = 'RM0001') AS pasien_key,
    (SELECT dokter_key FROM dw_rs.dim_dokter WHERE dokter_id = 'D001') AS dokter_key,
    (SELECT poli_key FROM dw_rs.dim_poli WHERE poli_id = 'POLI-UMUM') AS poli_key,
    (SELECT pembayaran_key FROM dw_rs.dim_pembayaran WHERE pembayaran_id = 'BPJS') AS pembayaran_key,
    (SELECT diagnosa_key FROM dw_rs.dim_diagnosa WHERE diagnosa_code = 'J06.9') AS diagnosa_key,
    (SELECT tindakan_key FROM dw_rs.dim_tindakan WHERE tindakan_code = 'T001') AS tindakan_key
)
INSERT INTO dw_rs.fact_kunjungan (
  waktu_key, pasien_key, dokter_key, poli_key, pembayaran_key, diagnosa_key, tindakan_key,
  kunjungan_id, no_antrian, sumber_sistem,
  jenis_kunjungan, waktu_masuk, waktu_keluar, status_kunjungan,
  is_rujukan, rujukan_dari, kelas_perawatan, kamar, lama_rawat_hari,
  jumlah_tindakan, biaya_konsultasi, biaya_tindakan, biaya_obat, biaya_kamar, biaya_lain, diskon, pajak,
  load_batch_id
)
SELECT
  waktu_key, pasien_key, dokter_key, poli_key, pembayaran_key, diagnosa_key, tindakan_key,
  'KJ-20260211-0001', 'A-15', 'HIS',
  'Rawat Jalan', TIMESTAMP '2026-02-11 09:10:00', TIMESTAMP '2026-02-11 09:45:00', 'SELESAI',
  TRUE, 'Puskesmas A', NULL, NULL, 0,
  1, 0, 150000, 20000, 0, 0, 0, 0,
  'BATCH-20260211'
FROM k
ON CONFLICT (kunjungan_id, sumber_sistem) DO NOTHING;

-- =========================================================
-- CONTOH QUERY LAPORAN (biar langsung kepakai)
-- =========================================================

-- 1) Total kunjungan & total biaya per poli per bulan
SELECT
  w.tahun,
  w.bulan,
  p.nama_poli,
  COUNT(*) AS jumlah_kunjungan,
  SUM(f.total_biaya) AS total_biaya
FROM dw_rs.fact_kunjungan f
JOIN dw_rs.dim_waktu w ON w.waktu_key = f.waktu_key
JOIN dw_rs.dim_poli  p ON p.poli_key  = f.poli_key
GROUP BY w.tahun, w.bulan, p.nama_poli
ORDER BY w.tahun, w.bulan, total_biaya DESC;

-- 2) Top diagnosa terbanyak
SELECT
  d.diagnosa_nama,
  COUNT(*) AS jumlah_kasus
FROM dw_rs.fact_kunjungan f
JOIN dw_rs.dim_diagnosa d ON d.diagnosa_key = f.diagnosa_key
GROUP BY d.diagnosa_nama
ORDER BY jumlah_kasus DESC
LIMIT 10;

-- 3) Kunjungan per dokter + total biaya
SELECT
  dr.nama_dokter,
  dr.spesialisasi,
  COUNT(*) AS jumlah_kunjungan,
  SUM(f.total_biaya) AS total_biaya
FROM dw_rs.fact_kunjungan f
JOIN dw_rs.dim_dokter dr ON dr.dokter_key = f.dokter_key
GROUP BY dr.nama_dokter, dr.spesialisasi
ORDER BY total_biaya DESC;
