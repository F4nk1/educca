import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../models/course_session.dart';
import '../providers/courses_provider.dart';
import 'qr_scanner_screen.dart';
import 'widgets/state_views.dart';

/// Pantalla que detalla el cronograma de sesiones de una capacitación seleccionada.
class SessionDetailScreen extends StatefulWidget {
  final Course course;

  const SessionDetailScreen({super.key, required this.course});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoursesProvider>().fetchSessions(widget.course.id);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _openScannerForSession(CourseSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => QrScannerScreen(targetSession: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoursesProvider>();
    final sessions = provider.getSessions(widget.course.id);
    final isLoading = provider.isLoadingSessions(widget.course.id);
    final error = provider.getSessionError(widget.course.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronograma de Sesiones'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.course.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Color(0xFF1565C0)),
                    const SizedBox(width: 6),
                    Text(
                      'Instructor: ${widget.course.instructorName}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                    ),
                  ],
                ),
                if (widget.course.description != null &&
                    widget.course.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.course.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (isLoading) {
                  return const LoadingView(message: 'Cargando sesiones programadas...');
                }

                if (error != null) {
                  return ErrorStateView(
                    message: error,
                    onRetry: () => provider.fetchSessions(widget.course.id),
                  );
                }

                if (sessions.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.event_busy_outlined,
                    title: 'Sin sesiones programadas',
                    description: 'El docente aún no ha registrado sesiones para este curso.',
                    onRefresh: () => provider.fetchSessions(widget.course.id),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchSessions(widget.course.id),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return _SessionCard(
                        session: session,
                        formattedDate: _formatDate(session.scheduledDate),
                        onScanTap: () => _openScannerForSession(session),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final CourseSession session;
  final String formattedDate;
  final VoidCallback onScanTap;

  const _SessionCard({
    required this.session,
    required this.formattedDate,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String badgeText;

    switch (session.attendanceStatus) {
      case SessionAttendanceStatus.open:
        badgeColor = const Color(0xFF00897B);
        badgeText = 'Asistencia Abierta';
        break;
      case SessionAttendanceStatus.closed:
        badgeColor = Colors.grey;
        badgeText = 'Concluida';
        break;
      case SessionAttendanceStatus.scheduled:
        badgeColor = const Color(0xFF1565C0);
        badgeText = 'Programada';
        break;
    }

    return Card(
      elevation: session.isAttendanceOpen ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: session.isAttendanceOpen
            ? const BorderSide(color: Color(0xFF00897B), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '$formattedDate (${session.startTime} - ${session.endTime})',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    session.location,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            if (session.isAttendanceOpen) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onScanTap,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Marcar Asistencia Ahora'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
