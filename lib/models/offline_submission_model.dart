enum SubmissionStatus {
  notSubmitted,
  pendingSync,
  submitted,
}

class OfflineSubmission {
  final int assignmentId;
  final String filePath;
  final String onlineText;
  final int? contextId;
  final DateTime createdAt;

  OfflineSubmission({
    required this.assignmentId,
    required this.filePath,
    required this.onlineText,
    this.contextId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Check if submission has online text content
  bool get hasOnlineText => onlineText.trim().isNotEmpty;

  // Check if submission has file content
  bool get hasFile => filePath.isNotEmpty;

  // Check if submission has any content
  bool get hasContent => hasOnlineText || hasFile;

  // Get submission type description
  String get submissionType {
    if (hasOnlineText && hasFile) return 'Text and File';
    if (hasOnlineText) return 'Text Only';
    if (hasFile) return 'File Only';
    return 'Empty';
  }

  // Method to convert instance to JSON for storing
  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'filePath': filePath,
      'onlineText': onlineText,
      'contextId': contextId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Factory constructor to create instance from JSON
  factory OfflineSubmission.fromJson(Map<String, dynamic> json) {
    return OfflineSubmission(
      assignmentId: json['assignmentId'] as int,
      filePath: json['filePath'] as String? ?? '',
      onlineText: json['onlineText'] as String? ?? '',
      contextId: json['contextId'] as int?,
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
    );
  }

  // Create a copy with modified fields
  OfflineSubmission copyWith({
    int? assignmentId,
    String? filePath,
    String? onlineText,
    int? contextId,
    DateTime? createdAt,
  }) {
    return OfflineSubmission(
      assignmentId: assignmentId ?? this.assignmentId,
      filePath: filePath ?? this.filePath,
      onlineText: onlineText ?? this.onlineText,
      contextId: contextId ?? this.contextId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'OfflineSubmission(assignmentId: $assignmentId, '
           'type: $submissionType, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineSubmission && 
           other.assignmentId == assignmentId;
  }

  @override
  int get hashCode => assignmentId.hashCode;
}