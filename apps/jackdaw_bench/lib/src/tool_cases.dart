/// One prompt of the tool-calling benchmark: the tool the model should call,
/// or `null` when it should answer directly, and arguments it must get
/// right, compared case-insensitively.
typedef ToolCase = ({String prompt, String? tool, Map<String, Object> args});

/// The benchmark prompts.
const List<ToolCase> toolCases = [
  (
    prompt: 'What is the weather in Lima?',
    tool: 'get_weather',
    args: {'city': 'Lima'},
  ),
  (
    prompt: 'Is it cold in Oslo right now, in fahrenheit?',
    tool: 'get_weather',
    args: {'city': 'Oslo', 'unit': 'fahrenheit'},
  ),
  (
    prompt: 'Weather for Tokyo please.',
    tool: 'get_weather',
    args: {'city': 'Tokyo'},
  ),
  (
    prompt: 'How warm is it in Madrid today?',
    tool: 'get_weather',
    args: {'city': 'Madrid'},
  ),
  (
    prompt: 'Set a timer for 10 minutes.',
    tool: 'set_timer',
    args: {'minutes': 10},
  ),
  (
    prompt: 'Start a 25 minute countdown.',
    tool: 'set_timer',
    args: {'minutes': 25},
  ),
  (
    prompt: 'Remind me in 5 minutes with a timer.',
    tool: 'set_timer',
    args: {'minutes': 5},
  ),
  (prompt: 'Timer, 45 minutes.', tool: 'set_timer', args: {'minutes': 45}),
  (
    prompt: 'Email ana@example.com that the meeting moved to 3pm.',
    tool: 'send_email',
    args: {'to': 'ana@example.com'},
  ),
  (
    prompt: 'Send an email to bo@example.com with subject Hello saying hi.',
    tool: 'send_email',
    args: {'to': 'bo@example.com'},
  ),
  (
    prompt: 'Write to kim@example.com: the report is ready.',
    tool: 'send_email',
    args: {'to': 'kim@example.com'},
  ),
  (
    prompt: 'Please email lee@example.com and thank him for lunch.',
    tool: 'send_email',
    args: {'to': 'lee@example.com'},
  ),
  (
    prompt: 'Find the contact Maria Lopez.',
    tool: 'find_contact',
    args: {'name': 'Maria Lopez'},
  ),
  (
    prompt: "What is John Smith's phone number?",
    tool: 'find_contact',
    args: {'name': 'John Smith'},
  ),
  (
    prompt: 'Look up Priya in my contacts.',
    tool: 'find_contact',
    args: {'name': 'Priya'},
  ),
  (
    prompt: 'Do I have Chen Wei saved as a contact?',
    tool: 'find_contact',
    args: {'name': 'Chen Wei'},
  ),
  (prompt: 'What is the capital of France?', tool: null, args: {}),
  (prompt: 'Translate good morning into Spanish.', tool: null, args: {}),
  (prompt: 'What is 12 times 7?', tool: null, args: {}),
  (prompt: 'Name three primary colors.', tool: null, args: {}),
  (prompt: 'Who wrote Romeo and Juliet?', tool: null, args: {}),
  (prompt: 'Give me a synonym for happy.', tool: null, args: {}),
  (prompt: 'How many days are in a leap year?', tool: null, args: {}),
  (prompt: 'Say hello in German.', tool: null, args: {}),
];
