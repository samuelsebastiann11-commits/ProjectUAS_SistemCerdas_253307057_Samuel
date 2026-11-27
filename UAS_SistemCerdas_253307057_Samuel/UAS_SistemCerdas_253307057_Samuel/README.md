# SmartKuliner Madiun (RAG Mini)

Proyek Akhir Individu, Sistem Cerdas (TI24317), Politeknik Negeri Madiun.
Samuel Aldrik Sebastian, NIM 253307057, Kelas 3B D3 Teknologi Informasi.

## Masalah yang diselesaikan

Wisatawan yang mencari kuliner Madiun (oleh-oleh yang tahan dibawa pulang, warung pecel yang buka pagi, jajanan pedas) biasanya harus membuka banyak artikel. Chatbot kata kunci gagal bila kata pengguna berbeda dari kata di data, sedangkan LLM murni bisa mengarang nama tempat, alamat, atau harga.

Aplikasi ini menjawab pertanyaan kuliner Madiun memakai **RAG mini**: LLM hanya boleh menjawab dari baris dataset yang berhasil diambil. Jika datanya tidak ada, aplikasi mengaku tidak tahu. Di sebelah jawaban RAG ditampilkan **chatbot kata kunci tanpa LLM** sebagai pembanding (Modul 13, Kegiatan 1 dan 4).

## Dataset

Sumber: kompilasi mandiri dari artikel yang dapat dibaca publik. Alamat sumber tiap baris ada di kolom `sumber_url` (liputan6.com, detik.com/jatim, daihatsu.co.id, mojok.co).
Lisensi: artikel sumber tidak mencantumkan lisensi dataset terbuka. Isi CSV dirangkum dengan kalimat sendiri, bukan salinan teks artikel; ini **belum membuktikan dataset memenuhi syarat lisensi terbuka pada rubrik UAS**. Jangan menyebutnya open data. Sebelum pengumpulan, minta persetujuan dosen atau ganti/tambah dataset dengan sumber yang lisensinya secara eksplisit mengizinkan penggunaan ulang.
Jumlah data: 31 baris (16 hidangan dan 15 tempat: 5 warung makan, 10 toko oleh-oleh), 13 kolom.
Berkas: `data/kuliner_madiun.csv`. Uji kasus: `data/uji_kasus.csv` (30 kasus).

Catatan kualitas: harga dan jam buka mengikuti artikel saat dikumpulkan (artikel warung pecel bertanggal 22 Mei 2024) dan bisa sudah berubah. Kolom yang tidak disebut sumber dibiarkan kosong, tidak ditebak. Kolom `kata_kunci` adalah kata bantu pencarian yang ditulis manual dari isi sumber.

Ingin memakai dataset lain? Ganti CSV-nya. Syarat minimal: kolom `nama` dan `deskripsi`; kolom lain (`id`, `jenis`, `kategori`, `lokasi`, dan seterusnya) bersifat opsional.

## Metode

RAG mini dengan tiga tahap, semuanya di `smartkuliner/rag.py`:

1. **Retrieval**: tiap baris dataset dijadikan satu dokumen teks. Dokumen dan pertanyaan diubah menjadi vektor TF-IDF (bobot kata dikali kelangkaannya), lalu dicari K baris dengan cosine similarity tertinggi. Pertanyaan diperluas dengan sinonim kecil (mis. "dibawa pulang" menjadi "oleh-oleh", "cemilan" menjadi "camilan").
2. **Pagar anti-halusinasi**: jika skor tertinggi di bawah ambang 0,18, pertanyaan dianggap di luar cakupan dan LLM tidak dipanggil.
3. **Generate**: K baris disisipkan ke prompt lima komponen (peran, konteks, tugas, batasan, format; Modul 13 A.3) lalu dikirim ke Gemini lewat REST. Tanpa API key, atau bila API gagal, aplikasi memakai jawaban ekstraktif yang disusun langsung dari baris dataset.

Pembanding: pencocokan kata kunci (jumlah kata yang sama), mengambil satu baris terbaik, seperti `chatbot_kunci` di Modul 13.

Pemanggilan Gemini memakai `urllib` (tanpa pustaka tambahan). Bila model yang dipilih ditolak (404), aplikasi menanyakan daftar model yang tersedia untuk key tersebut dan memakai model Flash yang cocok. Kunci API dapat dimasukkan di pengaturan pada halaman tanya untuk satu permintaan atau dibaca dari variabel lingkungan `GEMINI_API_KEY`; key tidak disimpan ke sesi atau source code.

## Hasil & evaluasi

Evaluasi memakai tabel uji kasus (30 kasus: 25 dalam cakupan, 5 di luar cakupan) pada tahap retrieval, tanpa LLM, sehingga hasilnya bisa diulang. Parameter: K = 3, ambang = 0,18. Jalankan `python -m smartkuliner.rag` atau buka halaman **Evaluasi**.

| Metrik | RAG (TF-IDF) | Kata kunci |
|---|---|---|
| Hit@3 (jawaban benar ada di 3 teratas) | 96% (24/25) | - |
| MRR | 0,92 | - |
| Top-1 benar | 88% (22/25) | 96% (24/25) |
| Penolakan benar untuk pertanyaan di luar cakupan | 80% (4/5) | 60% (3/5) |

Cara membaca:

- Pada set uji ini pembanding kata kunci **tidak kalah** di Top-1. Banyak kasus memakai kata yang sama dengan isi dataset, dan dataset kecil (31 baris), jadi pencocokan kata sederhana sudah cukup.
- Keunggulan RAG terlihat pada dua hal: pagar penolakan (pembanding menjawab "Sego Jotos" untuk pertanyaan tiket kereta) dan jawaban yang disusun LLM dari beberapa konteks.
- Kegagalan RAG yang tercatat: T06 ("seharga tiga ribu rupiah": angka dalam kata tidak cocok dengan "3000"), T26 ("buah tangan" bukan sinonim yang saya daftarkan), T27 ("sebelum subuh" tidak cocok dengan jam 05.00), dan T20 (toko oleh-oleh di Surabaya: pencarian kata tidak tahu bahwa kota itu tidak ada di data).
- Kasus uji dan dataset ditulis oleh orang yang sama, sehingga angka di atas cenderung optimistis. Ambang 0,18 ditetapkan sebelum evaluasi dijalankan dan tidak disetel ulang setelah melihat hasil.
- Mutu jawaban LLM (kalimat akhir) belum punya metrik otomatis; itu diperiksa manual lewat tab "Tanya asisten" dengan melihat prompt yang dikirim.

## Cara menjalankan

```
py -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

Alternatif Windows: setelah dependensi terpasang, jalankan `run_django.bat`. Aplikasi tersedia di `http://127.0.0.1:8000/`. Database SQLite Django dibuat saat perintah migrasi dijalankan.

API key Gemini bersifat opsional. Masukkan key pada panel pengaturan saat mengirim pertanyaan, atau set variabel lingkungan `GEMINI_API_KEY`. Key dari panel hanya dipakai untuk satu permintaan dan tidak disimpan. Untuk deployment, atur `DJANGO_SECRET_KEY`, `DJANGO_DEBUG=0`, `DJANGO_ALLOWED_HOSTS`, dan `GEMINI_API_KEY` melalui environment.

Jalur evaluasi tanpa jaringan: `python -m smartkuliner.rag` mencetak tabel evaluasi retrieval.

## Refleksi singkat

Yang berhasil: alur input, proses, output utuh; tanpa key aplikasi tetap menjawab (ekstraktif); pertanyaan di luar cakupan ditolak alih-alih dikarang; evaluasi bisa diulang dan semua kegagalan tercatat apa adanya.

Keterbatasan: dataset kecil dan bersumber artikel web, bukan data terbuka berlisensi, serta harga dan jam buka bisa kedaluwarsa. Retrieval berbasis kata tidak memahami makna di luar sinonim yang didaftarkan (T06, T26, T27) dan tidak bisa mengenali lokasi yang tidak ada di data (T20). Kualitas kalimat LLM belum diukur otomatis. Hasil pembanding di Top-1 yang setara menunjukkan set uji ini belum cukup keras untuk membedakan kedua metode.

Rencana perbaikan: ganti atau lengkapi dataset dengan sumber berlisensi terbuka setelah lisensinya diverifikasi; ganti TF-IDF dengan embedding agar "buah tangan" dan "sebelum subuh" ikut terjawab; tambah uji kasus yang ditulis orang lain; tambah kolom normalisasi jam buka dan harga agar bisa difilter.

## Kesesuaian dengan rubrik demo UAS

| Aspek | Bukti di proyek | Catatan demo |
|---|---|---|
| Fungsionalitas | Aplikasi Django menerima pertanyaan, mencari konteks, lalu menampilkan jawaban dan sumber | Jalankan tanpa API key lebih dulu; alur ekstraktif tetap bekerja |
| Data dan metode | TF-IDF, cosine similarity, ambang penolakan, dan prompt RAG dijelaskan di bawah | Lisensi dataset saat ini belum memenuhi syarat open data; jelaskan jujur atau ganti dataset setelah verifikasi |
| Evaluasi | 30 kasus uji, metrik Hit@K/MRR/Top-1, dan hasil tiap kasus tersedia di halaman evaluasi | Terangkan ini mengukur retrieval, bukan kualitas generasi LLM |
| Pemahaman kode | Peta simbol dan penjelasan alur ada di README dan `smartkuliner/rag.py` | Siapkan penjelasan tokenisasi, IDF, cosine, ambang, fallback, dan sumber konteks |
| Berkas | `manage.py`, proyek `core`, app `dashboard`, mesin RAG `smartkuliner`, folder `data`, `static`, `templates`, dan README | Jangan sertakan API key ke ZIP |

## Peta kode (untuk tanya jawab)

| Bagian | Tempat | Fungsi |
|---|---|---|
| Tokenisasi, stopword, stemming ringan | `smartkuliner/rag.py: tokenisasi` | Mengubah teks menjadi kata dasar tanpa kata umum |
| TF-IDF dan cosine | `smartkuliner/rag.py: Indeks` | Mengukur kemiripan pertanyaan dengan tiap baris data |
| Ekspansi sinonim | `smartkuliner/rag.py: SINONIM` | Menyambung kata pengguna ke kata di data |
| Ambang penolakan | `smartkuliner/rag.py: AMBANG_DEFAULT` | Pagar anti-halusinasi, LLM tidak dipanggil bila skor rendah |
| Prompt 5 komponen | `smartkuliner/rag.py: susun_prompt` | Peran, konteks, tugas, batasan, format |
| Panggilan Gemini | `smartkuliner/rag.py: jawab_gemini` | Kirim prompt, terima teks, dengan cadangan model dan galat yang ramah |
| Pembanding | `smartkuliner/rag.py: cari_kata_kunci` | Chatbot kata kunci ala Modul 13 |
| Evaluasi | `smartkuliner/rag.py: evaluasi` | Hit@K, MRR, Top-1, penolakan benar |
| Antarmuka | `dashboard/views.py` dan `templates/dashboard/home.html` | Halaman tanya, dataset, dan evaluasi |

## Struktur folder

```
manage.py                    entry point perintah Django
core/                        konfigurasi, URL, WSGI, dan ASGI Django
dashboard/                   app Django: form, URL, dan view
smartkuliner/rag.py           mesin RAG, pembanding, dan evaluasi
data/                        dataset kuliner dan kasus uji CSV
static/css/dashboard.css     desain responsif dashboard
templates/dashboard/         template halaman Django
db.sqlite3                   database lokal, dibuat oleh migrate (diabaikan Git)
run_django.bat               migrasi dan server lokal Windows
requirements.txt             dependensi Django dan pandas
```
