class Assignment {
  final int id;
  final int cmid;
  final int course;
  final String name;
  final String? intro;
  final String? activity;
  final int? allowsubmissionsfromdate;
  final int? duedate;
  final int? cutoffdate;
  final List<AssignmentConfig> configs;
  final List<IntroAttachment> introattachments;

  Assignment({
    required this.id,
    required this.cmid,
    required this.course,
    required this.name,
    this.intro,
    this.activity,
    this.allowsubmissionsfromdate,
    this.duedate,
    this.cutoffdate,
    required this.configs,
    required this.introattachments,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] ?? 0,
      cmid: json['cmid'] ?? 0,
      course: json['course'] ?? 0,
      name: json['name'] ?? '',
      intro: json['intro'],
      activity: json['activity'],
      allowsubmissionsfromdate: json['allowsubmissionsfromdate'],
      duedate: json['duedate'],
      cutoffdate: json['cutoffdate'],
      configs: (json['configs'] as List<dynamic>?)
          ?.map((config) => AssignmentConfig.fromJson(config))
          .toList() ?? [],
      introattachments: (json['introattachments'] as List<dynamic>?)
          ?.map((attachment) => IntroAttachment.fromJson(attachment))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cmid': cmid,
      'course': course,
      'name': name,
      'intro': intro,
      'activity': activity,
      'allowsubmissionsfromdate': allowsubmissionsfromdate,
      'duedate': duedate,
      'cutoffdate': cutoffdate,
      'configs': configs.map((config) => config.toJson()).toList(),
      'introattachments': introattachments.map((attachment) => attachment.toJson()).toList(),
    };
  }

  String getSubmissionType() {
    bool hasOnlineText = false;
    bool hasFile = false;
    
    for (var config in configs) {
      if (config.plugin == 'onlinetext' && 
          config.subtype == 'assignsubmission' && 
          config.name == 'enabled' && 
          config.value == '1') {
        hasOnlineText = true;
      }
      if (config.plugin == 'file' && 
          config.subtype == 'assignsubmission' && 
          config.name == 'enabled' && 
          config.value == '1') {
        hasFile = true;
      }
    }
    
    if (hasOnlineText && hasFile) return 'both';
    if (hasOnlineText) return 'online';
    if (hasFile) return 'upload';
    return 'both'; // Default fallback
  }

  List<String> getAllowedFileTypes() {
    for (var config in configs) {
      if (config.plugin == 'file' && 
          config.subtype == 'assignsubmission' && 
          config.name == 'filetypeslist' &&
          config.value != null) {
        return config.value!.split(',')
            .map((type) => type.trim())
            .where((type) => type.isNotEmpty)
            .toList();
      }
    }
    return []; // Allow all file types if not specified
  }

  DateTime? get dueDateAsDateTime {
    if (duedate == null || duedate == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(duedate! * 1000);
  }

  DateTime? get allowSubmissionsFromAsDateTime {
    if (allowsubmissionsfromdate == null || allowsubmissionsfromdate == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(allowsubmissionsfromdate! * 1000);
  }

  DateTime? get cutoffDateAsDateTime {
    if (cutoffdate == null || cutoffdate == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(cutoffdate! * 1000);
  }

  bool get isSubmissionAllowed {
    final now = DateTime.now();
    final allowFrom = allowSubmissionsFromAsDateTime;
    final cutoff = cutoffDateAsDateTime;
    
    if (allowFrom != null && now.isBefore(allowFrom)) return false;
    if (cutoff != null && now.isAfter(cutoff)) return false;
    
    return true;
  }

  bool get isOverdue {
    final now = DateTime.now();
    final due = dueDateAsDateTime;
    
    if (due == null) return false;
    return now.isAfter(due);
  }

  String get submissionStatusText {
    if (!isSubmissionAllowed) {
      final allowFrom = allowSubmissionsFromAsDateTime;
      if (allowFrom != null && DateTime.now().isBefore(allowFrom)) {
        return 'Submission not yet available';
      }
      return 'Submission closed';
    }
    
    if (isOverdue) {
      return 'Overdue';
    }
    
    return 'Open for submission';
  }
}

class AssignmentConfig {
  final String plugin;
  final String subtype;
  final String name;
  final String? value;

  AssignmentConfig({
    required this.plugin,
    required this.subtype,
    required this.name,
    this.value,
  });

  factory AssignmentConfig.fromJson(Map<String, dynamic> json) {
    return AssignmentConfig(
      plugin: json['plugin'] ?? '',
      subtype: json['subtype'] ?? '',
      name: json['name'] ?? '',
      value: json['value']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plugin': plugin,
      'subtype': subtype,
      'name': name,
      'value': value,
    };
  }
}

class IntroAttachment {
  final String filename;
  final String filepath;
  final int filesize;
  final String fileurl;
  final int timemodified;
  final String? mimetype;
  final bool isexternalfile;
  final String? repositorytype;

  IntroAttachment({
    required this.filename,
    required this.filepath,
    required this.filesize,
    required this.fileurl,
    required this.timemodified,
    this.mimetype,
    required this.isexternalfile,
    this.repositorytype,
  });

  factory IntroAttachment.fromJson(Map<String, dynamic> json) {
    return IntroAttachment(
      filename: json['filename'] ?? '',
      filepath: json['filepath'] ?? '',
      filesize: json['filesize'] ?? 0,
      fileurl: json['fileurl'] ?? '',
      timemodified: json['timemodified'] ?? 0,
      mimetype: json['mimetype'],
      isexternalfile: json['isexternalfile'] ?? false,
      repositorytype: json['repositorytype'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'filepath': filepath,
      'filesize': filesize,
      'fileurl': fileurl,
      'timemodified': timemodified,
      'mimetype': mimetype,
      'isexternalfile': isexternalfile,
      'repositorytype': repositorytype,
    };
  }

  String get formattedFileSize {
    if (filesize == 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    int i = (filesize / k).floor();
    i = i > 3 ? 3 : i;
    return '${(filesize / (k * i)).toStringAsFixed(2)} ${sizes[i]}';
  }

  String get fileExtension {
    return filename.split('.').last.toLowerCase();
  }

  String get fileIcon {
    switch (fileExtension) {
      case 'pdf': return '📄';
      case 'doc':
      case 'docx': return '📝';
      case 'xls':
      case 'xlsx': return '📊';
      case 'ppt':
      case 'pptx': return '📊';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif': return '🖼️';
      case 'mp4':
      case 'avi':
      case 'mov': return '🎥';
      case 'mp3':
      case 'wav': return '🎵';
      default: return '📎';
    }
  }

  DateTime get modifiedDateTime {
    return DateTime.fromMillisecondsSinceEpoch(timemodified * 1000);
  }
}

class SubmissionStatus {
  final bool hasSubmission;
  final bool isSubmitted;
  final bool isGraded;
  final DateTime? submissionDate;
  final String? grade;
  final String? feedback;
  final List<SubmissionFile> files;
  final String? onlineText;

  SubmissionStatus({
    required this.hasSubmission,
    required this.isSubmitted,
    required this.isGraded,
    this.submissionDate,
    this.grade,
    this.feedback,
    required this.files,
    this.onlineText,
  });

  factory SubmissionStatus.fromJson(Map<String, dynamic> json) {
    final lastattempt = json['lastattempt'];
    final submission = lastattempt?['submission'];
    
    return SubmissionStatus(
      hasSubmission: submission != null,
      isSubmitted: submission?['status'] == 'submitted',
      isGraded: json['feedback']?['grade'] != null,
      submissionDate: submission?['timemodified'] != null 
          ? DateTime.fromMillisecondsSinceEpoch((submission['timemodified'] as int) * 1000)
          : null,
      grade: json['feedback']?['grade']?['grade'],
      feedback: json['feedback']?['feedbackcomments']?['comments'],
      files: (submission?['plugins'] as List<dynamic>?)
          ?.where((plugin) => plugin['type'] == 'file')
          .expand((plugin) => (plugin['fileareas'] as List<dynamic>? ?? []))
          .expand((filearea) => (filearea['files'] as List<dynamic>? ?? []))
          .map((file) => SubmissionFile.fromJson(file))
          .toList() ?? [],
      onlineText: (submission?['plugins'] as List<dynamic>?)
          ?.where((plugin) => plugin['type'] == 'onlinetext')
          .map((plugin) => plugin['editorfields']?[0]?['text'])
          .where((text) => text != null)
          .cast<String>()
          .join('\n'),
    );
  }
}

class SubmissionFile {
  final String filename;
  final String filepath;
  final int filesize;
  final String fileurl;
  final String? mimetype;

  SubmissionFile({
    required this.filename,
    required this.filepath,
    required this.filesize,
    required this.fileurl,
    this.mimetype,
  });

  factory SubmissionFile.fromJson(Map<String, dynamic> json) {
    return SubmissionFile(
      filename: json['filename'] ?? '',
      filepath: json['filepath'] ?? '',
      filesize: json['filesize'] ?? 0,
      fileurl: json['fileurl'] ?? '',
      mimetype: json['mimetype'],
    );
  }
}