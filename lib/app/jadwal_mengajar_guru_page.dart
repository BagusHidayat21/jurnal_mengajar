import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jurnal_mengajar/app/color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jurnal_mengajar/app/form_jurnal_mengajar_guru_page.dart';

class JadwalMengajarGuruController extends GetxController {
  final supabase = Supabase.instance.client;

  var isLoading = true.obs;
  var selectedDate = DateTime.now().obs;
  var schedules = [].obs;
  var groupedSchedules = <List<Map<String, dynamic>>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDataByDate(selectedDate.value);
  }

  Future<void> fetchDataByDate(DateTime date) async {
    selectedDate.value = date;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    isLoading.value = true;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final weekday = date.weekday % 7;

      final results = await Future.wait([
        supabase
            .from('v_jadwal_mengajar')
            .select('*')
            .eq('guru_id', user.id)
            .or('tanggal.eq.$dateStr,and(tanggal.is.null,hari.eq.$weekday)')
            .eq('is_active', true),
        supabase
            .from('v_jurnal_harian')
            .select('*')
            .eq('guru_id', user.id)
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

      schedules.value = scheduleRes;
      groupedSchedules.value = scheduleRes.map((s) => [s]).toList();
    } catch (e) {
      print('Fetch Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void changeDate(DateTime date) {
    fetchDataByDate(date);
  }
}

class JadwalMengajarGuruPage extends StatelessWidget {
  const JadwalMengajarGuruPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(JadwalMengajarGuruController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Jadwal Mengajar',
          style: TextStyle(
            color: Colors.white,
            fontFamily: GoogleFonts.poppins().fontFamily,
          ),
        ),
        backgroundColor: MainColor.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        return Column(
          children: [
            _buildCalendarHeader(controller),
            Expanded(
              child: controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => controller.fetchDataByDate(
                        controller.selectedDate.value,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount:
                            controller.groupedSchedules.length +
                            (controller.groupedSchedules.isEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (controller.groupedSchedules.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 50.0),
                                child: Text(
                                  'Tidak ada jadwal',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontFamily:
                                        GoogleFonts.poppins().fontFamily,
                                  ),
                                ),
                              ),
                            );
                          }

                          final group = controller.groupedSchedules[index];
                          final firstSchedule = group.first;
                          bool sudahDiisi = group.any(
                            (s) => (s['jurnal_harian'] as List).isNotEmpty,
                          );

                          final jams = List<Map<String, dynamic>>.from(
                            firstSchedule['master_jam'] is List
                                ? firstSchedule['master_jam']
                                : [firstSchedule['master_jam']],
                          );
                          jams.sort((a, b) => (a['jam_ke'] as int).compareTo(b['jam_ke'] as int));

                          String startTime = jams.first['waktu_reguler']?.split('-')[0].trim() ?? '';
                          String endTime = jams.last['waktu_reguler']?.split('-')[1].trim() ?? '';
                          String time = '$startTime - $endTime';
                          String jamKeLabel = jams.map((j) => j['jam_ke'].toString()).join(', ');

                          return _buildJadwalCard(
                            time,
                            '${firstSchedule['master_kelas']['nama_kelas'] ?? ''} (Jam $jamKeLabel)',
                            firstSchedule['master_mata_pelajaran']['nama_mata_pelajaran'] ??
                                '',
                            sudahDiisi: sudahDiisi,
                            onTap: () {
                              _showDetailJadwal(
                                context,
                                firstSchedule,
                                sudahDiisi,
                                groupedSchedules: group,
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }

  void _showDetailJadwal(
    BuildContext context,
    Map schedule,
    bool sudahDiisi, {
    List<Map<String, dynamic>> groupedSchedules = const [],
  }) {
    // Build combined time from schedule hours
    final jams = List<Map<String, dynamic>>.from(
      schedule['master_jam'] is List
          ? schedule['master_jam']
          : [schedule['master_jam']],
    );
    jams.sort((a, b) => (a['jam_ke'] as int).compareTo(b['jam_ke'] as int));

    String firstTime = jams.first['waktu_reguler']?.split('-')[0].trim() ?? '';
    String lastTime = jams.last['waktu_reguler']?.split('-')[1].trim() ?? '';
    String time = '$firstTime - $lastTime';
    String jamKeLabel = 'Jam ke ${jams.map((j) => j['jam_ke'].toString()).join(', ')}';
    String date = DateFormat(
      'dd MMMM yyyy',
    ).format(DateTime.parse(schedule['tanggal']));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: sudahDiisi
                    ? const Color(0xFFEBE0C8)
                    : const Color(0xFFCDD8F0),
                child: Center(
                  child: Text(
                    sudahDiisi
                        ? 'Jurnal dari jadwal ini sudah diisi'
                        : 'Jurnal dari jadwal ini belum diisi',
                    style: TextStyle(
                      color: sudahDiisi
                          ? Colors.green.shade800
                          : MainColor.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                Supabase.instance.client.auth.currentUser?.email ?? 'Guru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                schedule['master_kelas']['nama_kelas'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: MainColor.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                schedule['master_mata_pelajaran']['nama_mata_pelajaran'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                  const SizedBox(width: 24),
                  const Icon(Icons.access_time, size: 16, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    '$time ($jamKeLabel)',
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MainColor.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    DateTime scheduleDate = DateTime.parse(schedule['tanggal']);
                    DateTime now = DateTime.now();
                    DateTime pureDate = DateTime(
                      scheduleDate.year,
                      scheduleDate.month,
                      scheduleDate.day,
                    );
                    DateTime pureNow = DateTime(now.year, now.month, now.day);

                    bool canFill = true;
                    if (pureDate.isAfter(pureNow)) {
                      canFill = false;
                    } else if (pureDate.isAtSameMomentAs(pureNow)) {
                      String startTimeStr = time.split('-')[0].trim();
                      try {
                        List<String> parts = startTimeStr.split('.');
                        int startHour = int.parse(parts[0]);
                        int startMin = int.parse(parts[1]);
                        DateTime startTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          startHour,
                          startMin,
                        );
                        if (now.isBefore(startTime)) {
                          canFill = false;
                        }
                      } catch (e) {}
                    }

                    if (!canFill) {
                      Get.back(); // close modal
                      Get.snackbar(
                        'Peringatan',
                        'Anda belum bisa mengisi jurnal. Waktu pelaksanaan jadwal kelas belum tiba.',
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(20),
                      );
                      return;
                    }

                    Get.back(); // Close modal
                    Get.to(
                      () => FormJurnalMengajarGuruPage(
                        schedule: schedule as Map<String, dynamic>,
                        groupedSchedules: groupedSchedules.isNotEmpty
                            ? groupedSchedules
                            : [schedule],
                        isEdit: sudahDiisi,
                        jurnalId: sudahDiisi
                            ? (groupedSchedules.firstWhere((s) => (s['jurnal_harian'] as List).isNotEmpty)['jurnal_harian'] as List)[0]['id']
                            : null,
                      ),
                    )?.then((value) {
                      if (value == true) {
                        final controller =
                            Get.find<JadwalMengajarGuruController>();
                        controller.fetchDataByDate(
                          controller.selectedDate.value,
                        );
                      }
                    });
                  },
                  child: Text(
                    sudahDiisi ? 'Edit Jurnal' : 'Isi Jurnal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJadwalCard(
    String time,
    String className,
    String subject, {
    required bool sudahDiisi,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: sudahDiisi ? const Color(0xFFCDD8F0) : const Color(0xFF4A8BCE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: sudahDiisi
                              ? MainColor.primaryColor
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        className,
                        style: TextStyle(
                          color: sudahDiisi
                              ? MainColor.primaryColor
                              : const Color(0xFFFDEBCA),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subject,
                    style: TextStyle(
                      color: sudahDiisi
                          ? MainColor.primaryColor.withOpacity(0.8)
                          : Colors.white70,
                      fontSize: 14,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: sudahDiisi ? MainColor.primaryColor : Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader(JadwalMengajarGuruController controller) {
    DateTime currentSelected = controller.selectedDate.value;
    String monthYear = DateFormat('MMMM yyyy').format(currentSelected);

    List<DateTime> dates = [];
    for (int i = -3; i <= 3; i++) {
      dates.add(currentSelected.add(Duration(days: i)));
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  controller.changeDate(
                    currentSelected.subtract(const Duration(days: 7)),
                  );
                },
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: MainColor.primaryColor,
                ),
              ),
              Text(
                monthYear,
                style: TextStyle(
                  fontSize: 20,
                  color: MainColor.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                ),
              ),
              GestureDetector(
                onTap: () {
                  controller.changeDate(
                    currentSelected.add(const Duration(days: 7)),
                  );
                },
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: MainColor.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dates.map((d) {
              bool isSelected =
                  d.year == currentSelected.year &&
                  d.month == currentSelected.month &&
                  d.day == currentSelected.day;
              String dayName = DateFormat('E').format(d);
              String dayNum = DateFormat('d').format(d);

              return GestureDetector(
                onTap: () => controller.changeDate(d),
                child: _buildDayItem(dayName, dayNum, isSelected),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayItem(String day, String date, bool isSelected) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            color: isSelected ? MainColor.primaryColor : Colors.grey,
            fontWeight: FontWeight.w600,
            fontFamily: GoogleFonts.poppins().fontFamily,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? MainColor.primaryColor : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              date,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
