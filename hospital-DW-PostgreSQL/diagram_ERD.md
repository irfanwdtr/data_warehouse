```
ERDiagram
  FACT_KUNJUNGAN {
    bigint fact_key PK
    int waktu_key FK
    bigint pasien_key FK
    bigint dokter_key FK
    bigint poli_key FK
    bigint pembayaran_key FK
    bigint diagnosa_key FK
    bigint tindakan_key FK

    text kunjungan_id
    text no_antrian
    text sumber_sistem
    text jenis_kunjungan
    timestamp waktu_masuk
    timestamp waktu_keluar
    text status_kunjungan
    boolean is_rujukan
    text rujukan_dari
    text kelas_perawatan
    text kamar
    int lama_rawat_hari

    int jumlah_tindakan
    numeric biaya_konsultasi
    numeric biaya_tindakan
    numeric biaya_obat
    numeric biaya_kamar
    numeric biaya_lain
    numeric diskon
    numeric pajak
    numeric total_biaya
  }

  DIM_WAKTU {
    int waktu_key PK
    date tanggal
    smallint hari
    smallint bulan
    varchar nama_bulan
    smallint kuartal
    smallint tahun
    smallint minggu_ke
    boolean is_weekend
  }

  DIM_PASIEN {
    bigint pasien_key PK
    text pasien_id
    text nama_pasien
    char jenis_kelamin
    date tgl_lahir
    smallint umur_tahun
    text kota
    text provinsi
    text tipe_pasien
  }

  DIM_DOKTER {
    bigint dokter_key PK
    text dokter_id
    text nama_dokter
    text spesialisasi
    text status_dokter
  }

  DIM_POLI {
    bigint poli_key PK
    text poli_id
    text nama_poli
    text tipe_poli
    text lantai
  }

  DIM_PEMBAYARAN {
    bigint pembayaran_key PK
    text pembayaran_id
    text nama_pembayaran
    text kategori
  }

  DIM_DIAGNOSA {
    bigint diagnosa_key PK
    text diagnosa_code
    text diagnosa_nama
    text grup
  }

  DIM_TINDAKAN {
    bigint tindakan_key PK
    text tindakan_code
    text tindakan_nama
    text kategori
  }

  DIM_WAKTU ||--o{ FACT_KUNJUNGAN : waktu_key
  DIM_PASIEN ||--o{ FACT_KUNJUNGAN : pasien_key
  DIM_DOKTER ||--o{ FACT_KUNJUNGAN : dokter_key
  DIM_POLI ||--o{ FACT_KUNJUNGAN : poli_key
  DIM_PEMBAYARAN ||--o{ FACT_KUNJUNGAN : pembayaran_key
  DIM_DIAGNOSA ||--o{ FACT_KUNJUNGAN : diagnosa_key
  DIM_TINDAKAN ||--o{ FACT_KUNJUNGAN : tindakan_key


```
