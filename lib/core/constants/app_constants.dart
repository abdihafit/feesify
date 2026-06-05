class AppConstants {
  static const String appName = 'School Finance System';
  static const List<String> adminEmails = <String>[
    'abdihafitofficial@gmail.com',
  ];

  static const List<String> userRoles = <String>[
    'admin',
    'principal',
    'bursar',
  ];

  static const List<String> userStatuses = <String>[
    'pending approval',
    'active',
    'suspended',
  ];

  static const List<String> schoolStatuses = <String>[
    'pending approval',
    'approved',
    'inactive',
    'rejected',
  ];

  static const List<String> paymentStatuses = <String>[
    'pending',
    'partial',
    'paid',
    'overdue',
  ];

  static const List<String> schoolClassLevels = <String>[
    'Form One',
    'Form Two',
    'Form Three',
    'Form Four',
    'Grade 10',
    'Grade 11',
  ];
}
