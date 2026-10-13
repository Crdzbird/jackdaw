/// Text shapes that try to steer a model from inside data, with the name
/// each finding is reported under.
final Map<String, RegExp> injectionPatterns = {
  'instruction override': RegExp(
    r'\b(ignore|disregard|forget|override)\b[^.\n]{0,40}\b(previous|prior|'
    r'above|earlier|all|your)\b[^.\n]{0,20}\b(instructions?|prompts?|rules|'
    r'messages|guidelines)\b',
    caseSensitive: false,
  ),
  'role change': RegExp(
    r'\b(you are now|from now on,? you|act as (an?|the) (unrestricted|'
    'jailbroken)|new (system )?instructions?:|updated instructions?:)',
    caseSensitive: false,
  ),
  'system prompt request': RegExp(
    r'\b(reveal|print|show|repeat|output)\b[^.\n]{0,30}\b(system prompt|'
    r'hidden instructions|developer message)\b',
    caseSensitive: false,
  ),
  'chat template token': RegExp(
    r'<\|(im_start|im_end|system|user|assistant|start_header_id|eot_id|'
    r'endoftext)\|>|\[/?INST\]|<<SYS>>|<start_of_turn>|<end_of_turn>',
  ),
  'role spoofing': RegExp(
    r'^\s*(#+\s*)?(system|assistant|developer)\s*:',
    caseSensitive: false,
    multiLine: true,
  ),
  'secrecy request': RegExp(
    r"\b(do not|don't|never) (tell|inform|mention to|show) the user\b|"
    r'\bwithout (telling|informing) the user\b',
    caseSensitive: false,
  ),
  'exfiltration link': RegExp(
    r'!\[[^\]]*\]\(https?://[^)\s]*\?[^)\s]*=',
    caseSensitive: false,
  ),
};

/// Characters that are invisible when rendered and have been used to hide
/// instructions: Unicode tag characters, zero-width characters and bidi
/// controls.
final RegExp invisibleCharacters = RegExp(
  '[\u200B-\u200F\u202A-\u202E\u2060-\u2064\u2066-\u2069\uFEFF]|'
  '[\u{E0000}-\u{E007F}]',
  unicode: true,
);
