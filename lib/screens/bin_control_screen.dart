import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';
import '../services/bin_service.dart';

class BinControlScreen extends StatefulWidget {
  final String binId;
  final String sessionId;
  final String apiKey;

  const BinControlScreen({
    super.key,
    required this.binId,
    required this.sessionId,
    required this.apiKey,
  });

  @override
  State<BinControlScreen> createState() => _BinControlScreenState();
}

class _BinControlScreenState extends State<BinControlScreen> {
  final BinService _binService = BinService();
  bool _isDeactivating = false;
  int _sessionDuration = 0;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
  }

  void _startSessionTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isActive) {
        setState(() => _sessionDuration++);
        _startSessionTimer();
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _deactivateBin() async {
    setState(() => _isDeactivating = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('User not authenticated');
        return;
      }

      final result = await _binService.deactivateBin(
        binId: widget.binId,
        userId: user.uid,
        sessionId: widget.sessionId,
        apiKey: widget.apiKey,
      );

      setState(() => _isActive = false);

      _showSuccess('Bin deactivated successfully!');

      // Show session summary
      await _showSessionSummary(result['data']);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isDeactivating = false);
      }
    }
  }

  Future<void> _showSessionSummary(Map<String, dynamic> data) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Session Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow('Duration', '${data['sessionDuration'] ?? 0} seconds'),
            _buildSummaryRow('Points Earned', '${data['totalPoints'] ?? 0} pts'),
            _buildSummaryRow('Items Recycled', '${data['itemsRecycled'] ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showError(String message) {
    Future.microtask(() {
      Flushbar(
        message: message,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        borderRadius: BorderRadius.circular(8),
        margin: const EdgeInsets.all(8),
      ).show(context);
    });
  }

  void _showSuccess(String message) {
    Future.microtask(() {
      Flushbar(
        message: message,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
        borderRadius: BorderRadius.circular(8),
        margin: const EdgeInsets.all(8),
      ).show(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bin Control'),
        backgroundColor: const Color(0xFF34A853),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bin status icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isActive ? Icons.lock_open : Icons.lock,
                size: 60,
                color: _isActive ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Status text
            Text(
              _isActive ? 'Bin Active' : 'Bin Locked',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _isActive ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            // Bin ID
            Text(
              'Bin ID: ${widget.binId}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            
            // Session ID
            Text(
              'Session: ${widget.sessionId}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            
            // Session timer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Session Time',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_sessionDuration),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF34A853),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Auto-timeout in ${300 - _sessionDuration}s',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(height: 8),
                  Text(
                    'The bin is now unlocked and ready for use.\nRecycle your items and tap "Finish" when done.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Deactivate button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isDeactivating ? null : _deactivateBin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isDeactivating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Finish & Lock Bin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
