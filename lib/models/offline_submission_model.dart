enum SubmissionStatus {
  notSubmitted,
  pendingSync,
  submitted,
}

class OfflineSubmission {
  final int assignmentId;
  final String filePath;
  final int? contextId; // The context ID of the module, needed for upload

  OfflineSubmission({
    required this.assignmentId,
    required this.filePath,
    this.contextId,
  });

  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'filePath': filePath,
      'contextId': contextId,
    };
  }

  factory OfflineSubmission.fromJson(Map<String, dynamic> json) {
    return OfflineSubmission(
      assignmentId: json['assignmentId'],
      filePath: json['filePath'],
      contextId: json['contextId'],
    );
  }
}
