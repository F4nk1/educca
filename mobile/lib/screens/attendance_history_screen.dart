import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attendance_models.dart';
import '../providers/attendance_provider.dart';
import 'widgets/state_views.dart';

/// Pantalla que lista el historial de asistencias confirmadas del estudiante.
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().fetchHistory();
    });
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} a las '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    if (provider.isLoadingHistory) {
      return const LoadingView(message: 'Cargando tu historial de asistencia...');
    }

    if (provider.historyError != null) {
      return ErrorStateView(
        message: provider.historyError!,
        onRetry: () => provider.fetchHistory(),
      );
    }

    if (provider.history.isEmpty) {
      return EmptyStateView(
        icon: Icons.history_toggle_off,
        title: 'Sin asistencias registradas',
        description: 'Cuando escanees un código QR en tus clases, tus asistencias aparecerán listadas aquí.',
        onRefresh: () => provider.fetchHistory(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchHistory(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 80),
        itemCount: provider.history.length,
        itemBuilder: (context, index) {
          final record = provider.history[index];
          return _AttendanceCard(
            record: record,
            formattedDate: _formatDateTime(record.markedAt),
          );
        },
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final String formattedDate;

  const _AttendanceCard({
    required this.record,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF00897B),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.courseTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.sessionTitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF00897B)),
              ),
              child: const Text(
                'Presente',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00897B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
