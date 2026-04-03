import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ErrorBannerOverlay extends StatefulWidget {
  final Widget child;
  const ErrorBannerOverlay({super.key, required this.child});

  @override
  State<ErrorBannerOverlay> createState() => _ErrorBannerOverlayState();
}

class _ErrorBannerOverlayState extends State<ErrorBannerOverlay> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;
  bool _showRestored = false;

  @override
  void initState() {
    super.initState();
    _checkInitial();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    _updateStatus(results);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    bool isCurrentlyOffline = results.contains(ConnectivityResult.none) || results.isEmpty;
    
    if (results.length > 1 && results.contains(ConnectivityResult.none)) {
       isCurrentlyOffline = false; 
    }

    if (_isOffline && !isCurrentlyOffline) {
      if (mounted) {
        setState(() {
          _isOffline = false;
          _showRestored = true;
        });
      }
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showRestored = false;
          });
        }
      });
    } else if (!_isOffline && isCurrentlyOffline) {
      if (mounted) {
        setState(() {
          _isOffline = true;
          _showRestored = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: (_isOffline || _showRestored) ? 40 : 0,
          color: _isOffline ? Colors.amber.shade800 : Colors.green.shade600,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(
               height: 40,
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(_isOffline ? Icons.wifi_off : Icons.wifi, color: Colors.white, size: 16),
                   const SizedBox(width: 8),
                   Text(
                     _isOffline ? 'You are offline' : 'Back online',
                     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                   )
                 ],
               ),
            )
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
