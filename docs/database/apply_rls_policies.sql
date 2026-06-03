-- ====================================================================================
-- RLS POLICIES FOR JURNAL MENGAJAR
-- ====================================================================================

-- 1. Drop Wildcard "Public Full Access" Policies
DROP POLICY IF EXISTS "Public Full Access" ON public.profiles;
DROP POLICY IF EXISTS "Public Full Access" ON public.master_kelas;
DROP POLICY IF EXISTS "Public Full Access" ON public.master_mata_pelajaran;
DROP POLICY IF EXISTS "Public Full Access" ON public.master_periode;
DROP POLICY IF EXISTS "Public Full Access" ON public.master_jam;
DROP POLICY IF EXISTS "Public Full Access" ON public.master_siswa;
DROP POLICY IF EXISTS "Public Full Access" ON public.jadwal_mengajar;
DROP POLICY IF EXISTS "Public Full Access" ON public.jurnal_harian;
DROP POLICY IF EXISTS "Public Full Access" ON public.presensi_siswa;
DROP POLICY IF EXISTS "Public Full Access" ON public.pengaturan_aplikasi;

-- 2. Buat Helper Functions untuk Pengecekan Role
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_guru()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'guru'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Kebijakan Tabel Master (Hanya Admin yang bisa Insert/Update/Delete, Semua user login bisa Select)

-- master_kelas
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.master_kelas;
DROP POLICY IF EXISTS "Allow write for admin only" ON public.master_kelas;
CREATE POLICY "Allow read for authenticated users" ON public.master_kelas FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow write for admin only" ON public.master_kelas FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- master_mata_pelajaran
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.master_mata_pelajaran;
DROP POLICY IF EXISTS "Allow write for admin only" ON public.master_mata_pelajaran;
CREATE POLICY "Allow read for authenticated users" ON public.master_mata_pelajaran FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow write for admin only" ON public.master_mata_pelajaran FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- master_periode
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.master_periode;
DROP POLICY IF EXISTS "Allow write for admin only" ON public.master_periode;
CREATE POLICY "Allow read for authenticated users" ON public.master_periode FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow write for admin only" ON public.master_periode FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- master_jam
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.master_jam;
DROP POLICY IF EXISTS "Allow write for admin only" ON public.master_jam;
CREATE POLICY "Allow read for authenticated users" ON public.master_jam FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow write for admin only" ON public.master_jam FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- master_siswa
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.master_siswa;
DROP POLICY IF EXISTS "Allow write for admin only" ON public.master_siswa;
CREATE POLICY "Allow read for authenticated users" ON public.master_siswa FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow write for admin only" ON public.master_siswa FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- jadwal_mengajar
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.jadwal_mengajar;
DROP POLICY IF EXISTS "Allow write for admin only" ON public.jadwal_mengajar;
CREATE POLICY "Allow read for authenticated users" ON public.jadwal_mengajar FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow write for admin only" ON public.jadwal_mengajar FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- pengaturan_aplikasi
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.pengaturan_aplikasi;
DROP POLICY IF EXISTS "Allow write for admin only" ON public.pengaturan_aplikasi;
CREATE POLICY "Allow read for authenticated users" ON public.pengaturan_aplikasi FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow write for admin only" ON public.pengaturan_aplikasi FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());


-- 4. Kebijakan Tabel Profiles (Semua user login bisa Select, User sendiri atau Admin bisa Update/Insert)
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Allow insert for user themselves or admin" ON public.profiles;
DROP POLICY IF EXISTS "Allow update for users themselves or admin" ON public.profiles;
DROP POLICY IF EXISTS "Allow delete for admin only" ON public.profiles;

CREATE POLICY "Allow read for authenticated users" ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow insert for user themselves or admin" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id OR public.is_admin());
CREATE POLICY "Allow update for users themselves or admin" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id OR public.is_admin()) WITH CHECK (auth.uid() = id OR public.is_admin());
CREATE POLICY "Allow delete for admin only" ON public.profiles FOR DELETE TO authenticated USING (public.is_admin());


-- 5. Kebijakan Tabel Transaksional (Jurnal Harian & Presensi)

-- jurnal_harian
-- - Read: Semua user login bisa melihat jurnal
-- - Insert: Guru yang bersangkutan (status harus pending) atau Admin
-- - Update: Guru yang bersangkutan (status harus pending) atau Admin
-- - Delete: Guru yang bersangkutan (status harus pending) atau Admin
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.jurnal_harian;
DROP POLICY IF EXISTS "Allow insert for assigned guru or admin" ON public.jurnal_harian;
DROP POLICY IF EXISTS "Allow update for assigned guru or admin" ON public.jurnal_harian;
DROP POLICY IF EXISTS "Allow delete for assigned guru or admin" ON public.jurnal_harian;

CREATE POLICY "Allow read for authenticated users" ON public.jurnal_harian FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow insert for assigned guru or admin" ON public.jurnal_harian FOR INSERT TO authenticated 
  WITH CHECK (
    public.is_admin() OR 
    (EXISTS (SELECT 1 FROM public.jadwal_mengajar WHERE id = jadwal_id AND guru_id = auth.uid()) AND status = 'pending')
  );

CREATE POLICY "Allow update for assigned guru or admin" ON public.jurnal_harian FOR UPDATE TO authenticated 
  USING (
    public.is_admin() OR 
    (EXISTS (SELECT 1 FROM public.jadwal_mengajar WHERE id = jadwal_id AND guru_id = auth.uid()) AND status = 'pending')
  )
  WITH CHECK (
    public.is_admin() OR 
    (EXISTS (SELECT 1 FROM public.jadwal_mengajar WHERE id = jadwal_id AND guru_id = auth.uid()) AND status = 'pending')
  );

CREATE POLICY "Allow delete for assigned guru or admin" ON public.jurnal_harian FOR DELETE TO authenticated 
  USING (
    public.is_admin() OR 
    (EXISTS (SELECT 1 FROM public.jadwal_mengajar WHERE id = jadwal_id AND guru_id = auth.uid()) AND status = 'pending')
  );


-- presensi_siswa
-- - Read: Semua user login bisa melihat presensi
-- - Write (ALL): Guru yang memiliki jurnal terkait atau Admin
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.presensi_siswa;
DROP POLICY IF EXISTS "Allow write for assigned guru or admin" ON public.presensi_siswa;

CREATE POLICY "Allow read for authenticated users" ON public.presensi_siswa FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow write for assigned guru or admin" ON public.presensi_siswa FOR ALL TO authenticated 
  USING (
    public.is_admin() OR 
    EXISTS (
      SELECT 1 FROM public.jurnal_harian jh 
      JOIN public.jadwal_mengajar jm ON jh.jadwal_id = jm.id 
      WHERE jh.id = jurnal_id AND jm.guru_id = auth.uid()
    )
  )
  WITH CHECK (
    public.is_admin() OR 
    EXISTS (
      SELECT 1 FROM public.jurnal_harian jh 
      JOIN public.jadwal_mengajar jm ON jh.jadwal_id = jm.id 
      WHERE jh.id = jurnal_id AND jm.guru_id = auth.uid()
    )
  );
