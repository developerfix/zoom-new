

class GlobalSettings {
  String voice;
  String language;
  String model;
  String timeZone; // 👈 ADD THIS

  String prompt;
  List<String> knowledgeBase;

  // 👇 SPEECH SETTINGS
  String backgroundSound;
  double responsiveness;
  double interruptionSensitivity;
  bool backchanneling;
  bool speechNormalization;
  String reminderSeconds;

  // ===== CALL SETTINGS =====
  bool voiceRecognition;
  bool voicemailDetection;
  bool keypadInputDetection;
  bool terminationKey;
  bool digitLimit;
  bool endCallOnSilence;
  double timeoutSeconds;
  double endCallSilenceSeconds;
  double maxCallDurationSeconds;
  double ringCallDurationSeconds;
  // ===== POST-CALL FIELDS =====
  List<Map<String, dynamic>> postCallFields;

  // ===== SECURITY & FALLBACK =====
  bool optInSecureUrls;
  String dataStorageOption;
  Set<String> selectedPii;
  List<Map<String, String>> dynamicVars;

// ===== TRANSCRIPTION =====
  String denoisingMode;
  String transcriptionMode;
  String vocabulary;

// ===== WEBHOOK =====
  String webhookUrl;
  double webhookTimeout;


  GlobalSettings({
    this.voice = 'en-US-Neural2-F',
    this.language = 'en-US',
    this.model = 'gpt-4o',
    this.prompt = '',
    this.knowledgeBase = const [],
    this.backgroundSound = 'None',
    this.responsiveness = 0.5,
    this.interruptionSensitivity = 0.5,
    this.backchanneling = false,
    this.speechNormalization = false,
    this.reminderSeconds = '30',
    this.timeZone = 'UTC', // 👈 default value


    // Call Settings (defaults)
    this.voiceRecognition = false,
    this.voicemailDetection = false,
    this.keypadInputDetection = false,
    this.terminationKey = false,
    this.digitLimit = false,
    this.endCallOnSilence = false,
    this.timeoutSeconds = 8.0,
    this.endCallSilenceSeconds = 30.0,
    this.maxCallDurationSeconds = 60.0,
    this.ringCallDurationSeconds = 60.0,
    // Post-Call Fields (defaults)
    this.postCallFields = const [
      {'name': 'Call Successful', 'type': 'boolean', 'isDeletable': false},
      {'name': 'Call Summary', 'type': 'text', 'isDeletable': false},
    ],

    this.optInSecureUrls = false,
    this.dataStorageOption = 'everything',
    this.selectedPii = const {},
    this.dynamicVars = const [],
    // Transcription
    this.denoisingMode = 'noise',
    this.transcriptionMode = 'speed',
    this.vocabulary = 'general',
    // Webhook
    this.webhookUrl = '',
    this.webhookTimeout = 5.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'voice': voice,
      'language': language,
      'model': model,
      'prompt': prompt,
      'knowledge_base': knowledgeBase,
      'background_sound': backgroundSound,
      'responsiveness': responsiveness,
      'interruption_sensitivity': interruptionSensitivity,
      'backchanneling': backchanneling,
      'speech_normalization': speechNormalization,
      'reminder_seconds': reminderSeconds,
      // Call Settings
      'call_settings': {
        'voice_recognition': voiceRecognition,
        'voicemail_detection': voicemailDetection,
        'keypad_input_detection': keypadInputDetection,
        'termination_key': terminationKey,
        'digit_limit': digitLimit,
        'end_call_on_silence': endCallOnSilence,
        'timeout_seconds': timeoutSeconds,
        'end_call_silence_seconds': endCallSilenceSeconds,
        'max_call_duration_seconds': maxCallDurationSeconds,
        'ring_call_duration_seconds': ringCallDurationSeconds,
      },
      // Post-Call Fields
      'post_call_fields': postCallFields,

      'opt_in_secure_urls': optInSecureUrls,
      'data_storage_option': dataStorageOption,
      'selected_pii': selectedPii.toList(),
      'dynamic_vars': dynamicVars,
      // Transcription
      'denoising_mode': denoisingMode,
      'transcription_mode': transcriptionMode,
      'vocabulary': vocabulary,
      // Webhook
      'webhook_url': webhookUrl,
      'webhook_timeout': webhookTimeout,
    };
  }

  factory GlobalSettings.fromJson(Map<String, dynamic> json) {

    // Call Settings
    final callSettings = json['call_settings'] as Map<String, dynamic>? ?? {};
    final postCallFields = (json['post_call_fields'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [
      {'name': 'Call Successful', 'type': 'boolean', 'isDeletable': false},
      {'name': 'Call Summary', 'type': 'text', 'isDeletable': false},
    ];


    // Security
    final selectedPiiList = (json['selected_pii'] as List?) ?? [];
    final dynamicVarsList = (json['dynamic_vars'] as List?) ?? [];


    return GlobalSettings(
      voice: json['voice'] ?? 'en-US-Neural2-F',
      language: json['language'] ?? 'en-US',
      model: json['model'] ?? 'gpt-4o',
      prompt: json['prompt'] ?? '',
      knowledgeBase: (json['knowledge_base'] as List?)?.map((e) => e as String).toList() ?? [],

      backgroundSound: json['background_sound'] ?? 'None',
      responsiveness: (json['responsiveness'] as num?)?.toDouble() ?? 0.5,
      interruptionSensitivity: (json['interruption_sensitivity'] as num?)?.toDouble() ?? 0.5,
      backchanneling: json['backchanneling'] ?? false,
      speechNormalization: json['speech_normalization'] ?? false,
      reminderSeconds: json['reminder_seconds'] ?? '30',

      voiceRecognition: callSettings['voice_recognition'] ?? false,
      voicemailDetection: callSettings['voicemail_detection'] ?? false,
      keypadInputDetection: callSettings['keypad_input_detection'] ?? false,
      terminationKey: callSettings['termination_key'] ?? false,
      digitLimit: callSettings['digit_limit'] ?? false,
      endCallOnSilence: callSettings['end_call_on_silence'] ?? false,
      timeoutSeconds: (callSettings['timeout_seconds'] as num?)?.toDouble() ?? 8.0,
      endCallSilenceSeconds: (callSettings['end_call_silence_seconds'] as num?)?.toDouble() ?? 30.0,
      maxCallDurationSeconds: (callSettings['max_call_duration_seconds'] as num?)?.toDouble() ?? 60.0,
      ringCallDurationSeconds: (callSettings['ring_call_duration_seconds'] as num?)?.toDouble() ?? 60.0,
      postCallFields: postCallFields,

      // Security
      optInSecureUrls: json['opt_in_secure_urls'] ?? false,
      dataStorageOption: json['data_storage_option'] ?? 'everything',
      selectedPii: Set<String>.from(selectedPiiList.cast<String>()),
      dynamicVars: List<Map<String, String>>.from(dynamicVarsList.cast<Map<String, String>>()),
      // Transcription
      denoisingMode: json['denoising_mode'] ?? 'noise',
      transcriptionMode: json['transcription_mode'] ?? 'speed',
      vocabulary: json['vocabulary'] ?? 'general',
      // Webhook
      webhookUrl: json['webhook_url'] ?? '',
      webhookTimeout: (json['webhook_timeout'] as num?)?.toDouble() ?? 5.0,

    );
  }

  GlobalSettings copy() {
    return GlobalSettings(
      voice: voice,
      language: language,
      model: model,
      prompt: prompt,
      knowledgeBase: List<String>.from(knowledgeBase),

      backgroundSound: backgroundSound,
      responsiveness: responsiveness,
      interruptionSensitivity: interruptionSensitivity,
      backchanneling: backchanneling,
      speechNormalization: speechNormalization,
      reminderSeconds: reminderSeconds,

      voiceRecognition: voiceRecognition,
      voicemailDetection: voicemailDetection,
      keypadInputDetection: keypadInputDetection,
      terminationKey: terminationKey,
      digitLimit: digitLimit,
      endCallOnSilence: endCallOnSilence,
      timeoutSeconds: timeoutSeconds,
      endCallSilenceSeconds: endCallSilenceSeconds,
      maxCallDurationSeconds: maxCallDurationSeconds,
      ringCallDurationSeconds: ringCallDurationSeconds,
      postCallFields: List<Map<String, dynamic>>.from(postCallFields),

      // Security
      optInSecureUrls: optInSecureUrls,
      dataStorageOption: dataStorageOption,
      selectedPii: Set<String>.from(selectedPii),
      dynamicVars: List<Map<String, String>>.from(dynamicVars),
      // Transcription
      denoisingMode: denoisingMode,
      transcriptionMode: transcriptionMode,
      vocabulary: vocabulary,
      // Webhook
      webhookUrl: webhookUrl,
      webhookTimeout: webhookTimeout,

    );
  }
}
