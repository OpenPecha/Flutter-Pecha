import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PlanDetails extends StatefulWidget {
  const PlanDetails({super.key});

  @override
  State<PlanDetails> createState() => _PlanDetailsState();
}

class _PlanDetailsState extends State<PlanDetails> {
  int selectedDay = 3; // Day 3 is selected by default
  int selectedActivity = -1; // No activity selected initially

  final List<String> activities = [
    'Read verse of the day',
    'Guided Scripture',
    'Meditate on the verse',
    'Pray',
    'Habit',
  ];

  final List<Map<String, dynamic>> days = [
    {'day': 1, 'date': 'Mar 04', 'completed': true},
    {'day': 2, 'date': 'Mar 05', 'completed': true},
    {'day': 3, 'date': 'Mar 06', 'completed': true},
    {'day': 4, 'date': 'Mar 07', 'completed': false},
    {'day': 5, 'date': 'Mar 08', 'completed': false},
    {'day': 6, 'date': 'Mar 09', 'completed': false},
    {'day': 7, 'date': 'Mar 10', 'completed': false},
    {'day': 8, 'date': 'Mar 11', 'completed': false},
    {'day': 9, 'date': 'Mar 12', 'completed': false},
    {'day': 10, 'date': 'Mar 13', 'completed': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Train your Mind',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Yellow banner with silhouette and text
          Container(
            width: double.infinity,
            height: 150,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Hero(
              tag: 'plan_image',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/bg.jpg',
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Daily progress carousel
          Container(
            height: 80,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: CarouselSlider.builder(
              options: CarouselOptions(
                height: 80,
                viewportFraction: 0.2,
                enableInfiniteScroll: false,
                scrollPhysics: const BouncingScrollPhysics(),
                autoPlayCurve: Curves.easeInOut,
                autoPlayAnimationDuration: const Duration(milliseconds: 300),
                padEnds: true,
              ),
              itemCount: days.length,
              itemBuilder: (context, index, realIndex) {
                final day = days[index];
                final isSelected = selectedDay == day['day'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDay = day['day'];
                    });
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF1E3A8A)
                                : Theme.of(context).cardColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day['day']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day['date'],
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Activities list
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s Activities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: index,
                                groupValue: selectedActivity,
                                onChanged: (value) {
                                  setState(() {
                                    selectedActivity = value!;
                                  });
                                },
                                activeColor: const Color(0xFF1E3A8A),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  activities[index],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Start Practice button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
            child: ElevatedButton(
              onPressed:
                  selectedActivity >= 0
                      ? () {
                        // Handle start practice
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Starting: ${activities[selectedActivity]}',
                            ),
                          ),
                        );
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Start Practice',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the silhouette
class SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF1E3A8A)
          ..style = PaintingStyle.fill;

    // Draw head (circle)
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.25),
      size.width * 0.2,
      paint,
    );

    // Draw body (rectangle)
    final bodyRect = Rect.fromLTWH(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.4,
      size.height * 0.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(8)),
      paint,
    );

    // Draw horizontal lines pattern
    final linePaint =
        Paint()
          ..color = const Color(0xFF1E3A8A)
          ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      final y = size.height * 0.45 + (i * 4);
      canvas.drawLine(
        Offset(size.width * 0.2, y),
        Offset(size.width * 0.8, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
