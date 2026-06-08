import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/assistant_provider.dart';

class SigumiAssistantOverlay extends StatelessWidget {
  const SigumiAssistantOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalAssistantProvider>(
      builder: (context, provider, child) {
        // Show overlay only if state is active (ListeningCommand, Processing, Speaking)
        final bool isVisible = provider.state == AssistantState.listeningCommand ||
            provider.state == AssistantState.processing ||
            provider.state == AssistantState.speaking;

        if (!isVisible) return const SizedBox.shrink();

        String statusText = '';
        IconData icon = Icons.mic;
        List<Color> glowColors = [];

        switch (provider.state) {
          case AssistantState.listeningCommand:
            statusText = 'Mendengarkan...';
            icon = Icons.mic;
            glowColors = [Colors.blue, Colors.purple, Colors.cyan];
            break;
          case AssistantState.processing:
            statusText = 'Memproses...';
            icon = Icons.autorenew;
            glowColors = [Colors.purple, Colors.pink, Colors.blue];
            break;
          case AssistantState.speaking:
            statusText = 'Berbicara...';
            icon = Icons.graphic_eq;
            glowColors = [Colors.cyan, Colors.blue, Colors.teal];
            break;
          default:
            break;
        }

        return Positioned.fill(
          child: Stack(
            children: [
              // Backdrop Blur
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ).animate().fadeIn(duration: 300.ms),
              
              // Content
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Text Response / Command
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          provider.state == AssistantState.speaking 
                              ? provider.lastResponse 
                              : provider.lastCommand.isEmpty 
                                  ? statusText 
                                  : provider.lastCommand,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ).animate(key: ValueKey(provider.lastCommand + provider.lastResponse)).fadeIn().moveY(begin: 10, end: 0),
                      
                      const SizedBox(height: 80),

                      // Glowing Orb
                      GestureDetector(
                        onTap: () {
                          provider.cancelAssistant();
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black87,
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 48,
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scaleXY(begin: 1.0, end: 1.15, duration: 1.seconds, curve: Curves.easeInOut),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Cancel instruction
                      const Text(
                        'Ketuk untuk batal',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ).animate().fadeIn(delay: 500.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
