// lib/constants.dart
// ignore_for_file: constant_identifier_names


enum StepType { species, cisterns, summary }

const List<StepType> STEPS = [
  StepType.species,
  StepType.cisterns,
  StepType.summary,
];

const List<String> RSW_TANKS = [
  'Port 1', 'Cent 1', 'Stb 1',
  'Port 2', 'Cent 2', 'Stb 2',
  'Port 3', 'Cent 3', 'Stb 3',
];

const List<String> SPECIES_OPTIONS = [
  'Sardine',
  'Mackerel',
  'Sardinella',
  'Horse Mackerel',
];

/// Mapping espèce → tailles possibles
const Map<String, List<String>> SPECIES_SIZE_OPTIONS = {
  'Sardine': [
    'Sardine 6-8',
    'Sardine 8-10',
    'Sardine 10-12',
    'Sardine 12-14',
    'Sardine 14-16',
    'Sardine 16++++',
  ],
  'Mackerel': [
    'Mackerel XL',
    'Mackerel L',
    'Mackerel M',
    'Mackerel S',
    'Mackerel SS',
    'Mackerel SSS',
    'Mackerel SSSS',
  ],
  'Sardinella': [
    'Sardinella 0-1',
    'Sardinella 1-3',
    'Sardinella 3-5',
    'Sardinella 5-8',
    'Sardinella <8',
  ],
  'Horse Mackerel': [
    'Horse Mackerel XL',
    'Horse Mackerel L',
    'Horse Mackerel M',
    'Horse Mackerel S',
    'Horse Mackerel SS',
    'Horse Mackerel SSS',
    'Horse Mackerel SSSS',
  ],
};

const List<String> BUYERS = [
  'SJOVIK MOROCCO',
  'DIPROMER',
  'AFROPISCA',
];
