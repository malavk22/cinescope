import 'package:flutter/material.dart';

// Scores from IMDb, Rotten Tomatoes and Metacritic, plus awards and other
// facts from the OMDb details response. Anything OMDb reports as "N/A" is hidden.
class RatingsPanel extends StatelessWidget {
  final Map<String, dynamic> movie;
  const RatingsPanel({super.key, required this.movie});

  static const _sources = {
    "Internet Movie Database": ("IMDb", Color(0xFFF5C518)),
    "Rotten Tomatoes": ("Rotten Tomatoes", Color(0xFFFA320A)),
    "Metacritic": ("Metacritic", Color(0xFF66CC33)),
  };

  String? _field(String key) {
    final v = movie[key];
    return (v is String && v.isNotEmpty && v != "N/A") ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    final scores = [
      for (final r in (movie["Ratings"] as List? ?? []))
        if (_sources.containsKey(r["Source"]))
          (
            label: _sources[r["Source"]]!.$1,
            color: _sources[r["Source"]]!.$2,
            value: r["Value"] as String,
          ),
    ];

    final facts = [
      (icon: Icons.emoji_events, label: "Awards", value: _field("Awards")),
      (icon: Icons.attach_money, label: "Box office", value: _field("BoxOffice")),
      (icon: Icons.verified_user, label: "Rated", value: _field("Rated")),
      (icon: Icons.calendar_today, label: "Released", value: _field("Released")),
    ].where((f) => f.value != null).toList();

    final votes = _field("imdbVotes");

    return Column(
      children: [
        if (scores.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final s in scores)
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: s.color.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        s.value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (s.label == "IMDb" && votes != null)
                        Text(
                          "$votes votes",
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                ),
            ],
          ),

        if (facts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final f in facts)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(f.icon, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "${f.label}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: f.value),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
