-- ====================================================================================
-- SEED DATA UNTUK JURNAL MENGAJAR (DATA REAL & MEREPRESENTASIKAN SEKOLAH ASLI)
-- ====================================================================================

-- 1. Bersihkan Data Lama & Reset Auto-Increment
TRUNCATE 
  public.presensi_siswa, 
  public.jurnal_harian, 
  public.jadwal_mengajar, 
  public.master_siswa, 
  public.master_kelas, 
  public.master_mata_pelajaran, 
  public.master_periode, 
  public.master_jam,
  public.pengaturan_aplikasi,
  public.profiles
RESTART IDENTITY CASCADE;

-- 2. Seed User Auth dan Profil Pengguna menggunakan ID dinamis
CREATE TEMP TABLE temp_seeding_users (
  role_name text PRIMARY KEY,
  id uuid NOT NULL
);

INSERT INTO temp_seeding_users (role_name, id) VALUES
('admin', gen_random_uuid()),
('guru1', gen_random_uuid()),
('guru2', gen_random_uuid());

INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, 
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, 
  confirmation_token, email_change, email_change_token_new, recovery_token
) VALUES 
('00000000-0000-0000-0000-000000000000', (SELECT id FROM temp_seeding_users WHERE role_name = 'admin'), 'authenticated', 'authenticated', 'admin@jurnal.com', crypt('admin123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Super Admin"}', now(), now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', (SELECT id FROM temp_seeding_users WHERE role_name = 'guru1'), 'authenticated', 'authenticated', 'guru1@jurnal.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Budi Santoso"}', now(), now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', (SELECT id FROM temp_seeding_users WHERE role_name = 'guru2'), 'authenticated', 'authenticated', 'guru2@jurnal.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Dewi Lestari"}', now(), now(), '', '', '', '');

-- Update profil yang dibuat secara otomatis oleh trigger handle_new_user
UPDATE public.profiles
SET 
  nama_lengkap = 'Drs. H. Mulyadi, M.Pd.',
  role = 'admin',
  jabatan = 'Kepala Sekolah / Admin',
  alamat = 'Jl. Danau Ranau No. 8, Sawojajar, Malang',
  no_telp = '081234567890',
  email = 'admin@jurnal.com'
WHERE id = (SELECT id FROM temp_seeding_users WHERE role_name = 'admin');

UPDATE public.profiles
SET 
  nama_lengkap = 'Ahmad Subarjo, S.Kom.',
  role = 'guru',
  jabatan = 'Ketua Program Keahlian RPL',
  alamat = 'Jl. Raya Sulfat No. 12, Blimbing, Malang',
  no_telp = '085731112223',
  email = 'guru1@jurnal.com'
WHERE id = (SELECT id FROM temp_seeding_users WHERE role_name = 'guru1');

UPDATE public.profiles
SET 
  nama_lengkap = 'Siti Aminah, S.Pd.',
  role = 'guru',
  jabatan = 'Guru Produktif RPL',
  alamat = 'Jl. Sigura-gura No. 5, Lowokwaru, Malang',
  no_telp = '081999888777',
  email = 'guru2@jurnal.com'
WHERE id = (SELECT id FROM temp_seeding_users WHERE role_name = 'guru2');

-- 3. Seed Master Kelas
INSERT INTO public.master_kelas (id, nama_kelas) VALUES
(1, 'X RPL 1'),
(2, 'X RPL 2'),
(3, 'XI RPL 1'),
(4, 'XI RPL 2'),
(5, 'XII RPL 1'),
(6, 'XII RPL 2');

-- Reset sequence untuk master_kelas
SELECT setval(pg_get_serial_sequence('public.master_kelas', 'id'), COALESCE((SELECT MAX(id)+1 FROM public.master_kelas), 1), false);

-- 4. Seed Master Mata Pelajaran
INSERT INTO public.master_mata_pelajaran (id, nama_mata_pelajaran) VALUES
(1, 'Pemrograman Web dan Perangkat Bergerak'),
(2, 'Basis Data'),
(3, 'Pemrograman Berbasis Objek'),
(4, 'Matematika'),
(5, 'Bahasa Indonesia'),
(6, 'Bahasa Inggris'),
(7, 'Pendidikan Agama Islam dan Budi Pekerti'),
(8, 'Pendidikan Pancasila dan Kewarganegaraan'),
(9, 'Sejarah Indonesia'),
(10, 'Pendidikan Jasmani, Olahraga, dan Kesehatan'),
(11, 'Produk Kreatif dan Kewirausahaan (PKK)'),
(12, 'Desain Grafis Percetakan');

-- Reset sequence untuk master_mata_pelajaran
SELECT setval(pg_get_serial_sequence('public.master_mata_pelajaran', 'id'), COALESCE((SELECT MAX(id)+1 FROM public.master_mata_pelajaran), 1), false);

-- 5. Seed Master Periode
INSERT INTO public.master_periode (id, nama_periode, is_active) VALUES
(1, '2025/2026 Ganjil', false),
(2, '2025/2026 Genap', true);

-- Reset sequence untuk master_periode
SELECT setval(pg_get_serial_sequence('public.master_periode', 'id'), COALESCE((SELECT MAX(id)+1 FROM public.master_periode), 1), false);

-- 6. Seed Master Jam Pelajaran
INSERT INTO public.master_jam (id, jam_ke, waktu_reguler, waktu_puasa) VALUES
(1, 1, '07.00-07.45', '07.30-08.05'),
(2, 2, '07.45-08.30', '08.05-08.40'),
(3, 3, '08.30-09.15', '08.45-09.20'),
(4, 4, '09.15-10.00', '09.20-09.55'),
(5, 5, '10.15-11.00', '10.00-10.35'),
(6, 6, '11.00-11.45', '10.35-11.10'),
(7, 7, '12.30-13.15', '11.10-11.45'),
(8, 8, '13.15-14.00', '13.00-13.35'),
(9, 9, '14.00-14.45', '13.35-14.10'),
(10, 10, '14.45-15.30', '14.10-14.45');

-- Reset sequence untuk master_jam
SELECT setval(pg_get_serial_sequence('public.master_jam', 'id'), COALESCE((SELECT MAX(id)+1 FROM public.master_jam), 1), false);

-- 7. Seed Master Siswa (15 Siswa per Kelas, Total 90 Siswa)
INSERT INTO public.master_siswa (id, nama_siswa, nisn, kelas_id, no_hp_ortu) VALUES
-- X RPL 1 (kelas_id = 1)
(1, 'Aditya Pratama Putra', '0092837401', 1, '081234560001'),
(2, 'Budi Santoso Wibowo', '0092837402', 1, '081234560002'),
(3, 'Citra Lestari Rahayu', '0092837403', 1, '081234560003'),
(4, 'Dwi Cahyono Hadi', '0092837404', 1, '081234560004'),
(5, 'Eka Saputra Wijaya', '0092837405', 1, '081234560005'),
(6, 'Farhan Hidayatullah', '0092837406', 1, '081234560006'),
(7, 'Gita Permatasari', '0092837407', 1, '081234560007'),
(8, 'Hendra Wijaya Kusumah', '0092837408', 1, '081234560008'),
(9, 'Indah Sari Safitri', '0092837409', 1, '081234560009'),
(10, 'Joko Susilo Bambang', '0092837410', 1, '081234560010'),
(11, 'Kartika Putri Utami', '0092837411', 1, '081234560011'),
(12, 'Lukman Hakim Al-Anshori', '0092837412', 1, '081234560012'),
(13, 'Mega Utami Handayani', '0092837413', 1, '081234560013'),
(14, 'Naufal Rizqi Ramadhan', '0092837414', 1, '081234560014'),
(15, 'Olivia Sabina Pertiwi', '0092837415', 1, '081234560015'),

-- X RPL 2 (kelas_id = 2)
(16, 'Pratama Putra Dewa', '0092837416', 2, '081234560016'),
(17, 'Qori Aina Salsabila', '0092837417', 2, '081234560017'),
(18, 'Rian Hidayat Syah', '0092837418', 2, '081234560018'),
(19, 'Siti Aminah Azzahra', '0092837419', 2, '081234560019'),
(20, 'Tri Wahyuni Lestari', '0092837420', 2, '081234560020'),
(21, 'Utomo Budi Prasetyo', '0092837421', 2, '081234560021'),
(22, 'Vina Panduwinata Agustin', '0092837422', 2, '081234560022'),
(23, 'Wahyu Setiawan Nugroho', '0092837423', 2, '081234560023'),
(24, 'Xena Putri Maharani', '0092837424', 2, '081234560024'),
(25, 'Yusuf Mansur Al-Hafidz', '0092837425', 2, '081234560025'),
(26, 'Zaki Alfarizi Rahman', '0092837426', 2, '081234560026'),
(27, 'Amanda Manopo Wulan', '0092837427', 2, '081234560027'),
(28, 'Bagas Pramudya Wardana', '0092837428', 2, '081234560028'),
(29, 'Candra Kirana Dewi', '0092837429', 2, '081234560029'),
(30, 'Doni Tata Pradana', '0092837430', 2, '081234560030'),

-- XI RPL 1 (kelas_id = 3)
(31, 'Elina Joerg Syafina', '0082837401', 3, '081234560031'),
(32, 'Faza Syahdan Al-Fatih', '0082837402', 3, '081234560032'),
(33, 'Galih Ginola Abimanyu', '0082837403', 3, '081234560033'),
(34, 'Hani Syafiah Nurul', '0082837404', 3, '081234560034'),
(35, 'Irfan Bachdim Mulya', '0082837405', 3, '081234560035'),
(36, 'Jessica Mila Kartika', '0082837406', 3, '081234560036'),
(37, 'Kevin Sanjaya Sukamuljo', '0082837407', 3, '081234560037'),
(38, 'Lesti Kejora Andryani', '0082837408', 3, '081234560038'),
(39, 'Maudy Ayunda Faza', '0082837409', 3, '081234560039'),
(40, 'Nadiem Makarim Anwar', '0082837410', 3, '081234560040'),
(41, 'Olla Ramlan Taufik', '0082837411', 3, '081234560041'),
(42, 'Prilly Latuconsina Aurelia', '0082837412', 3, '081234560042'),
(43, 'Raffi Ahmad Malik', '0082837413', 3, '081234560043'),
(44, 'Syifa Hadju Savira', '0082837414', 3, '081234560044'),
(45, 'Tulus Prasetyo Utomo', '0082837415', 3, '081234560045'),

-- XI RPL 2 (kelas_id = 4)
(46, 'Uus Wijaya Kusuma', '0082837416', 4, '081234560046'),
(47, 'Vidi Aldiano Pratama', '0082837417', 4, '081234560047'),
(48, 'Wulan Guritno Sari', '0082837418', 4, '081234560048'),
(49, 'Yahya Waloni Akbar', '0082837419', 4, '081234560049'),
(50, 'Zaskia Adya Mecca', '0082837420', 4, '081234560050'),
(51, 'Ariel Noah Nazril', '0082837421', 4, '081234560051'),
(52, 'Baim Wong Setiawan', '0082837422', 4, '081234560052'),
(53, 'Chelsea Olivia Wijaya', '0082837423', 4, '081234560053'),
(54, 'Deddy Corbuzier Cahyo', '0082837424', 4, '081234560054'),
(55, 'Ernest Prakasa Wijaya', '0082837425', 4, '081234560055'),
(56, 'Fiersa Besari Sandi', '0082837426', 4, '081234560056'),
(57, 'Gading Marten Roy', '0082837427', 4, '081234560057'),
(58, 'Hesti Purwadinata Ayu', '0082837428', 4, '081234560058'),
(59, 'Isyana Sarasvati Lestari', '0082837429', 4, '081234560059'),
(60, 'Jefri Nichol Pratama', '0082837430', 4, '081234560060'),

-- XII RPL 1 (kelas_id = 5)
(61, 'Keanu Angelo Saputra', '0072837401', 5, '081234560061'),
(62, 'Luna Maya Sugeng', '0072837402', 5, '081234560062'),
(63, 'Melly Goeslaw Anto', '0072837403', 5, '081234560063'),
(64, 'Najwa Shihab Quraish', '0072837404', 5, '081234560064'),
(65, 'Onadio Leonardo Rian', '0072837405', 5, '081234560065'),
(66, 'Pevita Pearce Cleo', '0072837406', 5, '081234560066'),
(67, 'Raditya Dika Angkasa', '0072837407', 5, '081234560067'),
(68, 'Sherina Munaf Tri', '0072837408', 5, '081234560068'),
(69, 'Tora Sudiro Pradana', '0072837409', 5, '081234560069'),
(70, 'Uus Kartika Sari', '0072837410', 5, '081234560070'),
(71, 'Vino G. Bastian Halim', '0072837411', 5, '081234560071'),
(72, 'Wandra Restusiyan P', '0072837412', 5, '081234560072'),
(73, 'Yura Yunita Rachma', '0072837413', 5, '081234560073'),
(74, 'Ziva Magnolya Sinaga', '0072837414', 5, '081234560074'),
(75, 'Angga Yunanda Aldi', '0072837415', 5, '081234560075'),

-- XII RPL 2 (kelas_id = 6)
(76, 'Bryan Domani Elmi', '0072837416', 6, '081234560076'),
(77, 'Cinta Laura Kiehl', '0072837417', 6, '081234560077'),
(78, 'Desta Mahendra Prakoso', '0072837418', 6, '081234560078'),
(79, 'Enzy Storia Leovarisa', '0072837419', 6, '081234560079'),
(80, 'Febby Rastanty Wulandari', '0072837420', 6, '081234560080'),
(81, 'Giorgino Abraham R', '0072837421', 6, '081234560081'),
(82, 'Harris Vriza Alamsyah', '0072837422', 6, '081234560082'),
(83, 'Iqbaal Ramadhan Diafakhri', '0072837423', 6, '081234560083'),
(84, 'Jodilee Warwick Lestari', '0072837424', 6, '081234560084'),
(85, 'Kiky Saputri Wardani', '0072837425', 6, '081234560085'),
(86, 'Lyodra Ginting Margaretha', '0072837426', 6, '081234560086'),
(87, 'Mawar de Jongh Eva', '0072837427', 6, '081234560087'),
(88, 'Nikita Willy Febrina', '0072837428', 6, '081234560088'),
(89, 'Omar Daniel Assegaf', '0072837429', 6, '081234560089'),
(90, 'Pevita Rose Amelia', '0072837430', 6, '081234560090');

-- Reset sequence untuk master_siswa
SELECT setval(pg_get_serial_sequence('public.master_siswa', 'id'), COALESCE((SELECT MAX(id)+1 FROM public.master_siswa), 1), false);

-- 8. Seed Jadwal Mengajar (Schedules) - Periode Genap (id = 2)
INSERT INTO public.jadwal_mengajar (id, guru_id, periode_id, kelas_id, mata_pelajaran_id, jam_ids, hari, tanggal, is_active) VALUES
-- Senin (hari = 1)
(1, (SELECT id FROM temp_seeding_users WHERE role_name = 'guru2'), 2, 1, 12, ARRAY[1, 2]::bigint[], 1, NULL, true), -- Siti: X RPL 1 - Desain Grafis Jam 1 & 2
(2, (SELECT id FROM temp_seeding_users WHERE role_name = 'guru1'), 2, 3, 1, ARRAY[3, 4]::bigint[], 1, NULL, true),  -- Ahmad: XI RPL 1 - Pemrograman Web Jam 3 & 4

-- Selasa (hari = 2)
(3, (SELECT id FROM temp_seeding_users WHERE role_name = 'guru2'), 2, 2, 12, ARRAY[1, 2]::bigint[], 2, NULL, true), -- Siti: X RPL 2 - Desain Grafis Jam 1 & 2
(4, (SELECT id FROM temp_seeding_users WHERE role_name = 'guru2'), 2, 4, 2, ARRAY[3, 4]::bigint[], 2, NULL, true),  -- Siti: XI RPL 2 - Basis Data Jam 3 & 4
(5, (SELECT id FROM temp_seeding_users WHERE role_name = 'guru1'), 2, 6, 3, ARRAY[5, 6]::bigint[], 2, NULL, true),  -- Ahmad: XII RPL 2 - PBO Jam 5 & 6

-- Rabu (hari = 3)
(6, (SELECT id FROM temp_seeding_users WHERE role_name = 'guru1'), 2, 1, 4, ARRAY[1, 2]::bigint[], 3, NULL, true),  -- Ahmad: X RPL 1 - Matematika Jam 1 & 2
(7, (SELECT id FROM temp_seeding_users WHERE role_name = 'guru2'), 2, 3, 2, ARRAY[3, 4]::bigint[], 3, NULL, true),  -- Siti: XI RPL 1 - Basis Data Jam 3 & 4
(8, (SELECT id FROM temp_seeding_users WHERE role_name = 'guru1'), 2, 5, 11, ARRAY[5, 6]::bigint[], 3, NULL, true); -- Ahmad: XII RPL 1 - PKK Jam 5 & 6

-- Reset sequence untuk jadwal_mengajar
SELECT setval(pg_get_serial_sequence('public.jadwal_mengajar', 'id'), COALESCE((SELECT MAX(id)+1 FROM public.jadwal_mengajar), 1), false);

-- 9. Seed Pengaturan Aplikasi
INSERT INTO public.pengaturan_aplikasi (id, nobox_token, nobox_account_ids, batas_input_jurnal) VALUES
(1, 'nobox_token_prod_jurnal_mengajar_8819', 'account_id_9921', 3);


-- 10. Seed Jurnal Harian & Presensi Siswa (Data Historis Past 1-2 Weeks)

-- Jurnal 1: Senin, 25 Mei 2026 (XI RPL 1 - Pemrograman Web Jam 3 & 4) - Guru: Ahmad Subarjo (id_jadwal = 2)
INSERT INTO public.jurnal_harian (id, jadwal_id, tanggal, materi, catatan, foto_lampiran_url, status, catatan_admin, validated_by, validated_at, is_telat, jadwal_ids) VALUES
(1, 2, '2026-05-25', 'Pengenalan dan Instalasi Node.js serta NPM', 'Siswa berhasil menginstal Node.js di komputer masing-masing. Praktikum berjalan lancar.', NULL, 'approved', 'Bagus, teruskan progres praktikum', (SELECT id FROM temp_seeding_users WHERE role_name = 'admin'), '2026-05-25 15:00:00+00', false, ARRAY[2]::bigint[]);

-- Presensi untuk Jurnal 1 (Siswa XI RPL 1: id 31 s/d 45)
INSERT INTO public.presensi_siswa (jurnal_id, siswa_id, kelas_id, status) VALUES
(1, 31, 3, 'Hadir'), (1, 32, 3, 'Hadir'), (1, 33, 3, 'Hadir'), (1, 34, 3, 'Hadir'), (1, 35, 3, 'Sakit'),
(1, 36, 3, 'Hadir'), (1, 37, 3, 'Hadir'), (1, 38, 3, 'Hadir'), (1, 39, 3, 'Hadir'), (1, 40, 3, 'Hadir'),
(1, 41, 3, 'Izin'),  (1, 42, 3, 'Hadir'), (1, 43, 3, 'Hadir'), (1, 44, 3, 'Hadir'), (1, 45, 3, 'Hadir');


-- Jurnal 2: Senin, 25 Mei 2026 (X RPL 1 - Desain Grafis Jam 1 & 2) - Guru: Siti Aminah (id_jadwal = 1)
INSERT INTO public.jurnal_harian (id, jadwal_id, tanggal, materi, catatan, foto_lampiran_url, status, catatan_admin, validated_by, validated_at, is_telat, jadwal_ids) VALUES
(2, 1, '2026-05-25', 'Konsep Desain Vektor dan Bitmap', 'Menjelaskan perbedaan vektor dan bitmap beserta aplikasinya.', NULL, 'approved', 'Dokumentasi lengkap', (SELECT id FROM temp_seeding_users WHERE role_name = 'admin'), '2026-05-25 15:10:00+00', false, ARRAY[1]::bigint[]);

-- Presensi untuk Jurnal 2 (Siswa X RPL 1: id 1 s/d 15)
INSERT INTO public.presensi_siswa (jurnal_id, siswa_id, kelas_id, status) VALUES
(2, 1, 1, 'Hadir'), (2, 2, 1, 'Hadir'), (2, 3, 1, 'Hadir'), (2, 4, 1, 'Hadir'), (2, 5, 1, 'Hadir'),
(2, 6, 1, 'Hadir'), (2, 7, 1, 'Hadir'), (2, 8, 1, 'Hadir'), (2, 9, 1, 'Hadir'), (2, 10, 1, 'Hadir'),
(2, 11, 1, 'Hadir'), (2, 12, 1, 'Hadir'), (2, 13, 1, 'Hadir'), (2, 14, 1, 'Alpha'), (2, 15, 1, 'Hadir');


-- Jurnal 3: Selasa, 26 Mei 2026 (XI RPL 2 - Basis Data Jam 3 & 4) - Guru: Siti Aminah (id_jadwal = 4)
INSERT INTO public.jurnal_harian (id, jadwal_id, tanggal, materi, catatan, foto_lampiran_url, status, catatan_admin, validated_by, validated_at, is_telat, jadwal_ids) VALUES
(3, 4, '2026-05-26', 'Perancangan Entity Relationship Diagram (ERD)', 'Siswa membuat ERD untuk sistem perpustakaan sekolah.', NULL, 'approved', 'ERD sudah sesuai standar', (SELECT id FROM temp_seeding_users WHERE role_name = 'admin'), '2026-05-26 16:00:00+00', false, ARRAY[4]::bigint[]);

-- Presensi untuk Jurnal 3 (Siswa XI RPL 2: id 46 s/d 60)
INSERT INTO public.presensi_siswa (jurnal_id, siswa_id, kelas_id, status) VALUES
(3, 46, 4, 'Hadir'), (3, 47, 4, 'Hadir'), (3, 48, 4, 'Hadir'), (3, 49, 4, 'Hadir'), (3, 50, 4, 'Hadir'),
(3, 51, 4, 'Hadir'), (3, 52, 4, 'Hadir'), (3, 53, 4, 'Hadir'), (3, 54, 4, 'Hadir'), (3, 55, 4, 'Sakit'),
(3, 56, 4, 'Hadir'), (3, 57, 4, 'Hadir'), (3, 58, 4, 'Hadir'), (3, 59, 4, 'Hadir'), (3, 60, 4, 'Hadir');


-- Jurnal 4: Rabu, 27 Mei 2026 (XI RPL 1 - Basis Data Jam 3 & 4) - Guru: Siti Aminah (id_jadwal = 7)
INSERT INTO public.jurnal_harian (id, jadwal_id, tanggal, materi, catatan, foto_lampiran_url, status, catatan_admin, validated_by, validated_at, is_telat, jadwal_ids) VALUES
(4, 7, '2026-05-27', 'Implementasi DDL (Data Definition Language) SQL', 'Praktik membuat database, table, dan primary key di phpMyAdmin.', NULL, 'approved', 'Sangat baik', (SELECT id FROM temp_seeding_users WHERE role_name = 'admin'), '2026-05-27 15:30:00+00', false, ARRAY[7]::bigint[]);

-- Presensi untuk Jurnal 4 (Siswa XI RPL 1: id 31 s/d 45)
INSERT INTO public.presensi_siswa (jurnal_id, siswa_id, kelas_id, status) VALUES
(4, 31, 3, 'Hadir'), (4, 32, 3, 'Hadir'), (4, 33, 3, 'Hadir'), (4, 34, 3, 'Hadir'), (4, 35, 3, 'Hadir'),
(4, 36, 3, 'Hadir'), (4, 37, 3, 'Hadir'), (4, 38, 3, 'Hadir'), (4, 39, 3, 'Hadir'), (4, 40, 3, 'Hadir'),
(4, 41, 3, 'Hadir'), (4, 42, 3, 'Hadir'), (4, 43, 3, 'Hadir'), (4, 44, 3, 'Hadir'), (4, 45, 3, 'Hadir');


-- Jurnal 5: Senin, 1 Juni 2026 (XI RPL 1 - Pemrograman Web Jam 3 & 4) - Guru: Ahmad Subarjo (id_jadwal = 2)
INSERT INTO public.jurnal_harian (id, jadwal_id, tanggal, materi, catatan, foto_lampiran_url, status, catatan_admin, validated_by, validated_at, is_telat, jadwal_ids) VALUES
(5, 2, '2026-06-01', 'Membuat Routing dan Controller di ExpressJS', 'Siswa mempelajari HTTP methods (GET, POST, PUT, DELETE) pada router.', NULL, 'approved', 'Kerja bagus', (SELECT id FROM temp_seeding_users WHERE role_name = 'admin'), '2026-06-01 16:00:00+00', false, ARRAY[2]::bigint[]);

-- Presensi untuk Jurnal 5 (Siswa XI RPL 1: id 31 s/d 45)
INSERT INTO public.presensi_siswa (jurnal_id, siswa_id, kelas_id, status) VALUES
(5, 31, 3, 'Hadir'), (5, 32, 3, 'Hadir'), (5, 33, 3, 'Hadir'), (5, 34, 3, 'Hadir'), (5, 35, 3, 'Hadir'),
(5, 36, 3, 'Izin'),  (5, 37, 3, 'Hadir'), (5, 38, 3, 'Hadir'), (5, 39, 3, 'Hadir'), (5, 40, 3, 'Hadir'),
(5, 41, 3, 'Hadir'), (5, 42, 3, 'Hadir'), (5, 43, 3, 'Hadir'), (5, 44, 3, 'Hadir'), (5, 45, 3, 'Hadir');


-- Jurnal 6: Selasa, 2 Juni 2026 (XII RPL 2 - PBO Jam 5 & 6) - Guru: Ahmad Subarjo (id_jadwal = 5)
-- Status masih PENDING, belum divalidasi admin
INSERT INTO public.jurnal_harian (id, jadwal_id, tanggal, materi, catatan, foto_lampiran_url, status, catatan_admin, validated_by, validated_at, is_telat, jadwal_ids) VALUES
(6, 5, '2026-06-02', 'Konsep Pewarisan (Inheritance) dalam PBO', 'Membuat program inheritance menggunakan Java (Superclass dan Subclass).', NULL, 'pending', NULL, NULL, NULL, false, ARRAY[5]::bigint[]);

-- Presensi untuk Jurnal 6 (Siswa XII RPL 2: id 76 s/d 90)
INSERT INTO public.presensi_siswa (jurnal_id, siswa_id, kelas_id, status) VALUES
(6, 76, 6, 'Hadir'), (6, 77, 6, 'Hadir'), (6, 78, 6, 'Hadir'), (6, 79, 6, 'Hadir'), (6, 80, 6, 'Hadir'),
(6, 81, 6, 'Sakit'), (6, 82, 6, 'Hadir'), (6, 83, 6, 'Hadir'), (6, 84, 6, 'Hadir'), (6, 85, 6, 'Hadir'),
(6, 86, 6, 'Hadir'), (6, 87, 6, 'Hadir'), (6, 88, 6, 'Hadir'), (6, 89, 6, 'Hadir'), (6, 90, 6, 'Hadir');

-- Reset sequence untuk jurnal_harian dan presensi_siswa
SELECT setval(pg_get_serial_sequence('public.jurnal_harian', 'id'), COALESCE((SELECT MAX(id)+1 FROM public.jurnal_harian), 1), false);
SELECT setval(pg_get_serial_sequence('public.presensi_siswa', 'id'), COALESCE((SELECT MAX(id)+1 FROM public.presensi_siswa), 1), false);

-- ====================================================================================
-- SEED DATA SELESAI
-- ====================================================================================
