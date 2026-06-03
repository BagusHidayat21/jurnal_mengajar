-- Database migration script to alter public.jadwal_mengajar to use bigint[] jam_ids and create views v_jadwal_mengajar and v_jurnal_harian.

-- Drop constraint first
ALTER TABLE public.jadwal_mengajar DROP CONSTRAINT IF EXISTS jadwal_mengajar_jam_id_fkey;

-- Drop old scalar jam_id column
ALTER TABLE public.jadwal_mengajar DROP COLUMN IF EXISTS jam_id;

-- Add new jam_ids array column
ALTER TABLE public.jadwal_mengajar ADD COLUMN IF NOT EXISTS jam_ids bigint[] DEFAULT ARRAY[]::bigint[];

-- Create v_jadwal_mengajar view
CREATE OR REPLACE VIEW public.v_jadwal_mengajar
WITH (security_invoker = true) AS
SELECT 
  jm.id,
  jm.guru_id,
  jm.periode_id,
  jm.hari,
  jm.tanggal,
  jm.is_active,
  jm.kelas_id,
  jm.mata_pelajaran_id,
  jm.jam_ids,
  (
    SELECT row_to_json(mk) 
    FROM public.master_kelas mk 
    WHERE mk.id = jm.kelas_id
  ) AS master_kelas,
  (
    SELECT row_to_json(mmp) 
    FROM public.master_mata_pelajaran mmp 
    WHERE mmp.id = jm.mata_pelajaran_id
  ) AS master_mata_pelajaran,
  (
    SELECT json_agg(row_to_json(mj) ORDER BY mj.jam_ke)
    FROM public.master_jam mj
    WHERE mj.id = ANY(jm.jam_ids)
  ) AS master_jam,
  (
    SELECT row_to_json(p) 
    FROM public.profiles p 
    WHERE p.id = jm.guru_id
  ) AS profiles
FROM public.jadwal_mengajar jm;

-- Create v_jurnal_harian view
CREATE OR REPLACE VIEW public.v_jurnal_harian
WITH (security_invoker = true) AS
SELECT 
  jh.id,
  jh.jadwal_id,
  jh.tanggal,
  jh.materi,
  jh.catatan,
  jh.foto_lampiran_url,
  jh.status,
  jh.catatan_admin,
  jh.validated_by,
  jh.validated_at,
  jh.is_telat,
  jh.jadwal_ids,
  jh.presensi_json,
  jh.created_at,
  vjm.guru_id AS guru_id,
  (
    SELECT jsonb_build_object(
      'id', vjm.id,
      'guru_id', vjm.guru_id,
      'periode_id', vjm.periode_id,
      'hari', vjm.hari,
      'tanggal', vjm.tanggal,
      'is_active', vjm.is_active,
      'kelas_id', vjm.kelas_id,
      'mata_pelajaran_id', vjm.mata_pelajaran_id,
      'jam_ids', vjm.jam_ids,
      'master_kelas', vjm.master_kelas,
      'master_mata_pelajaran', vjm.master_mata_pelajaran,
      'master_jam', vjm.master_jam,
      'guru', jsonb_build_object(
        'id', prof_guru.id,
        'nama_lengkap', prof_guru.nama_lengkap,
        'foto_url', prof_guru.foto_url
      ),
      'profiles', jsonb_build_object(
        'nama_lengkap', prof_guru.nama_lengkap,
        'foto_url', prof_guru.foto_url
      )
    )
    FROM public.profiles prof_guru
    WHERE prof_guru.id = vjm.guru_id
  ) AS jadwal,
  (
    SELECT jsonb_build_object(
      'id', vjm.id,
      'guru_id', vjm.guru_id,
      'periode_id', vjm.periode_id,
      'hari', vjm.hari,
      'tanggal', vjm.tanggal,
      'is_active', vjm.is_active,
      'kelas_id', vjm.kelas_id,
      'mata_pelajaran_id', vjm.mata_pelajaran_id,
      'jam_ids', vjm.jam_ids,
      'master_kelas', vjm.master_kelas,
      'master_mata_pelajaran', vjm.master_mata_pelajaran,
      'master_jam', vjm.master_jam,
      'guru', jsonb_build_object(
        'id', prof_guru.id,
        'nama_lengkap', prof_guru.nama_lengkap,
        'foto_url', prof_guru.foto_url
      )
    )
    FROM public.profiles prof_guru
    WHERE prof_guru.id = vjm.guru_id
  ) AS jadwal_mengajar,
  (
    SELECT jsonb_build_object(
      'nama_lengkap', prof_val.nama_lengkap
    )
    FROM public.profiles prof_val
    WHERE prof_val.id = jh.validated_by
  ) AS validated_by_profile,
  (
    SELECT jsonb_build_object(
      'nama_lengkap', prof_val.nama_lengkap
    )
    FROM public.profiles prof_val
    WHERE prof_val.id = jh.validated_by
  ) AS profiles
FROM public.jurnal_harian jh
LEFT JOIN public.v_jadwal_mengajar vjm ON vjm.id = jh.jadwal_id;
