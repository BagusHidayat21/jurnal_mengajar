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

  /// Fetches schedules and journals using views, maps journals locally, and sorts schedules.
  Future<void> _fetchSchedulesAndJournals(String userId, DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final weekday = date.weekday % 7;

    final results = await Future.wait([
      supabase
          .from('v_jadwal_mengajar')
          .select('*')
          .eq('guru_id', userId)
          .or('tanggal.eq.$dateStr,and(tanggal.is.null,hari.eq.$weekday)')
          .eq('is_active', true),
      supabase
          .from('v_jurnal_harian')
          .select('*')
          .eq('guru_id', userId)
          .eq('tanggal', dateStr),
    ]);

    final scheduleRes = List<Map<String, dynamic>>.from(results[0]);
    final journalRes = List<Map<String, dynamic>>.from(results[1]);

    // Map journals to schedules
    for (var s in scheduleRes) {
      Map<String, dynamic>? matchingJournal;
      for (var j in journalRes) {
        if (j['jadwal_id'] == s['id'] || (j['jadwal_ids'] as List?)?.contains(s['id']) == true) {
          matchingJournal = j;
          break;
        }
      }
      s['jurnal_harian'] = matchingJournal != null ? [matchingJournal] : [];
    }

    // Sort schedules by the earliest jam_ke
    scheduleRes.sort((a, b) {
      final aJams = a['master_jam'] as List? ?? [];
      final bJams = b['master_jam'] as List? ?? [];
      if (aJams.isEmpty) return 1;
      if (bJams.isEmpty) return -1;
      final aFirst = aJams[0]['jam_ke'] as int? ?? 0;
      final bFirst = bJams[0]['jam_ke'] as int? ?? 0;
      return aFirst.compareTo(bFirst);
    });

    final List<List<Map<String, dynamic>>> groups = scheduleRes.map((s) => [s]).toList();

    schedules.value = scheduleRes;
    groupedSchedules.value = groups;
    journals.value = journalRes;
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
