# Bird names for the Dart/Flutter on-device LLM agent framework

Checked 2026-10-12. pub.dev via https://pub.dev/api/packages/<name> (404 = free).
GitHub via `gh repo view Crdzbird/<name>` and `gh search repos`. Brand checks are
a quick web search only, not legal advice. Run a proper trademark search (USPTO,
EUIPO) before committing.

Crdzbird/<name> is free on GitHub for every candidate below.

## Ranked table

| # | name | bird reference / meaning | pub.dev free? (root / _core / _flutter) | GitHub conflicts | brand / trademark collisions | verdict |
|---|------|--------------------------|------------------------------------------|------------------|------------------------------|---------|
| 1 | corax | Latin species name of the common raven (Corvus corax). Ravens solve problems and plan ahead | yes / yes / yes (_openai, _llama, _agents, _ffi, _dart also free) | No Dart repos. Feysh-Group/corax-community (255 stars, Java static analyzer), corax-keyboard (144). No AI framework | None found in AI. Corax is also a figure from Greek rhetoric | TOP PICK |
| 2 | kea | NZ alpine parrot, among the smartest birds, known for solving puzzles and using tools | yes / yes / yes (all suffixes free) | keajs/kea (2k stars, React state lib). Only tiny AI repos (KeAgent 6 stars) | ISC Kea DHCP server (networking, other field). No AI product found | TOP PICK |
| 3 | jackdaw | Small corvid, social, famous for collecting and remembering objects (memory) | yes / yes / yes (all suffixes free) | No Dart repos. skelsec/jackdaw (587, AD security tool), jbuehler23/jackdaw (559, Bevy editor) | Only an obscure HF model fine-tune. No AI product | TOP PICK (longer) |
| 4 | corvus | Genus of crows and ravens | yes / yes / yes (all suffixes free) | Small Dart repos only | Rust crate `corvus` is an AI assistant/agent infra (direct overlap); Corvic AI similar sound | OK, but small AI overlap |
| 5 | kakapo | Flightless NZ parrot: "does not fly to the cloud", fits on-device | yes / yes / yes (all suffixes free) | devlucky/Kakapo (758, Swift mock lib) | No AI product. Looks like `kakao_*` (Kakao SDK) in pub.dev search | OK, cute metaphor, spelling risk |
| 6 | aerie | Eagle nest high on a cliff: home, memory | yes / yes / yes (all suffixes free) | Nothing notable | Aerie is an American Eagle apparel brand; Aeries Technology sells agentic AI (AxAI) | Weak, brand noise |
| 7 | nestling | Young bird in the nest | yes / yes / yes | Tiny repos only | None found | Free but weak and long |
| 8 | murmur | From murmuration (starling flock), multi-agent swarm | yes / yes / yes (murmuration root taken) | murmurhash in Dart (7), spaolacci/murmur3 (1k) | MurmurHash, Mumble server "murmur" | Medium, name overloaded |
| 9 | shrike | Butcher-bird, sharp and precise | yes / yes / yes | mehdi1514/Shrike (5 Dart), vicharak-in/shrike (521) | Shrike AI (robotics/ML company), US Army Project Shrike (AI drones) | Avoid |
| 10 | tern | Arctic tern, longest migration (endurance) | yes / yes / yes | ternjs/tern (4.2k, JS code-analysis engine) | Name close to "ternary LLM" research | Avoid, ternjs is a dev tool |
| 11 | halcyon | Mythical kingfisher, calm | yes / yes / yes | jhangyu/halcyon (8 Dart) | Halcyon (anti-ransomware AI, USD 1B valuation); Halcyon energy AI startup | Avoid |
| 12 | owlet | Young owl, wisdom | yes / yes / yes | owlet-toast, owlet-router (Dart, small) | Owlet is a well-known baby-monitor brand | Avoid |
| 13 | peregrine | Fastest bird (speed) | yes / yes / yes | ThatNerdSquared/peregrine (23 Dart), Peregrine lang (1.4k) | Many companies named Peregrine | Avoid, long and crowded |
| 14 | rook | Corvid, also chess piece | yes / yes / yes | rook/rook (13.6k, CNCF storage) | Rook is a CNCF graduated project | Avoid |
| 15 | osprey | Fish hawk, precision diver | yes / yes / yes | CircleRadon/Osprey (843, multimodal LLM), roostorg/osprey (490), tophant-ai/osprey (579) | Osprey MLLM (CVPR 2024) | Avoid, AI collision |
| 16 | roost | Where birds rest (state, memory) | yes / yes / yes | microsoft/roosterjs, roostorg | ROOST, open-source AI safety tools org | Avoid, AI collision |
| 17 | avian | Generic "of birds" | yes / yes / yes | Small repos | Avian (avian.io) is an LLM inference API | Avoid, direct AI collision |
| 18 | kestrel | Hovering falcon (focus) | yes / yes / yes | twitter-archive/kestrel (2.7k) | Microsoft ASP.NET Core Kestrel server; PyPI "kestrel" local-first AI agent runtime | Avoid |
| 19 | wren | Small clever songbird | yes / yes / yes | Canner/WrenAI (17.8k, AI text-to-SQL), wren-lang (8.1k), wren-dart | WrenAI | Avoid, direct AI collision |
| 20 | starling | Flock bird, murmurations | yes / yes / yes | Gamua/Starling-Framework (3.1k) | Starling-7B LLM (UC Berkeley); Starling Bank | Avoid, direct LLM collision |
| 21 | corvid / raven / magpie / merlin / flock / jay / plume / finch / kite / owl / quill / swift / heron / loon / petrel / lyrebird / oriole / kiwi / murmuration | various | NO, root taken on pub.dev (swift_flutter also taken) | n/a | raven, merlin, swift, kite, quill also heavy brands | Rejected |

Other free roots on pub.dev, not vetted further (weaker fit or crowded brands):
condor (HTCondor), sparrow (mail app, Sparrow repos), puffin (Puffin browser),
falco (CNCF Falco), garuda (Garuda Linux), ibis (Ibis dataframe), egret, myna,
plover, avocet, grackle, nuthatch, kookaburra, caracara, auk, corvo, griffin
(Google Griffin model architecture). `robin` root is free but `robin_flutter` is taken.
`pigeon` skipped as requested.

## Top 3

1. corax: the raven itself in Latin, fully free on pub.dev and GitHub with no AI collision, 5 letters, reads well as corax_core, corax_flutter, corax_openai.
2. kea: shortest option, named for the most famously clever, tool-using parrot, fully free; only collisions (keajs, ISC Kea DHCP) are outside AI.
3. jackdaw: corvid known for collecting and remembering, a clean fit for agent memory, fully free with no AI product of that name; longer to type.

Runner-up: kakapo (flightless, so "stays on device") if a playful story matters
more than search clarity next to Kakao packages.
