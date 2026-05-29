import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardGuruController extends GetxController {
  final supabase = Supabase.instance.client;

  var isLoading = true.obs;
  var userProfile = {}.obs;
  var selectedDate = DateTime.now().obs;
  
  // List of maps for schedules and journals
  var schedules = [].obs;
  var groupedSchedules = <List<Map<String, dynamic>>>[].obs;
  var journals = [].obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    isLoading.value = true;
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Fetch profile and date data in parallel
        final results = await Future.wait([
          supabase
              .from('profiles')
              .select('id, nama_lengkap, foto_url, role')
              .eq('id', user.id)
              .single(),
          _fetchSchedulesAndJournals(user.id, selectedDate.value),
        ]);
        userProfile.value = results[0] as Map<String, dynamic>;
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetches schedules and journals in parallel for a given user and date.
  Future<void> _fetchSchedulesAndJournals(String userId, DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final weekday = date.weekday % 7;

    final results = await Future.wait([
      supabase
          .from('jadwal_mengajar')
          .select('*, master_kelas(nama_kelas), master_mata_pelajaran(nama_mata_pelajaran), master_jam(*), jurnal_harian(id)')
          .eq('guru_id', userId)
          .or('tanggal.eq.$dateStr,and(tanggal.is.null,hari.eq.$weekday)')
          .eq('jurnal_harian.tanggal', dateStr)
          .eq('is_active', true)
          .order('jam_id', ascending: true),
      supabase
          .from('jurnal_harian')
          .select('*, jadwal_mengajar!inner(*, master_kelas(nama_kelas), master_mata_pelajaran(nama_mata_pelajaran), master_jam(*))')
          .eq('jadwal_mengajar.guru_id', userId)
          .eq('tanggal', dateStr),
    ]);

    final scheduleRes = List<Map<String, dynamic>>.from(results[0]);

    // Group consecutive schedules with same kelas_id + mata_pelajaran_id
    List<List<Map<String, dynamic>>> groups = [];
    for (var s in scheduleRes) {
      final sMap = Map<String, dynamic>.from(s);
      if (groups.isNotEmpty) {
        final lastGroup = groups.last;
        final lastItem = lastGroup.last;
        if (lastItem['kelas_id'] == sMap['kelas_id'] &&
            lastItem['mata_pelajaran_id'] == sMap['mata_pelajaran_id']) {
          lastGroup.add(sMap);
          continue;
        }
      }
      groups.add([sMap]);
    }

    // Propagate journal to all items in the group if any item has it
    for (var group in groups) {
      dynamic journal;
      for (var s in group) {
        if ((s['jurnal_harian'] as List).isNotEmpty) {
          journal = s['jurnal_harian'];
          break;
        }
      }
      if (journal != null) {
        for (var s in group) {
          s['jurnal_harian'] = journal;
        }
      }
    }

    schedules.value = scheduleRes;
    groupedSchedules.value = groups;
    journals.value = results[1];
  }

  Future<void> fetchDataByDate(DateTime date) async {
    selectedDate.value = date;
    isLoading.value = true;
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      await _fetchSchedulesAndJournals(user.id, date);
    } catch (e) {
      print('Fetch Data Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void changeDate(DateTime date) {
    fetchDataByDate(date);
  }
}
