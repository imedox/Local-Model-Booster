# Test Prompts & .BAT Switchers for Every Profile

Double-click any `.bat` file in `C:\tools\` to switch profiles instantly!

---

## 1. Profile: `coding` (Default)
- **Switcher File**: `C:\tools\switch_coding.bat` *(Double-click to activate)*
- **Configuration**: 128K context, `q8_0` KV cache, 16K reasoning tokens, temp 0.8, top_p 0.95.
- **Why this test**: Tests whether the model takes its time to thoroughly plan multithreaded logic and outputs clean, idiomatic code.

### Test Prompt to Paste into Bionic:
```text
Write a modern C++20 thread-safe bounded lock-free or mutex-based queue class template ThreadSafeQueue<T> with push(T item), bool try_pop(T& value), and wait_and_pop(T& value). Include a complete main() demonstrating 4 producer threads and 4 consumer threads running concurrently.
```

---

## 2. Profile: `general_operation`
- **Switcher File**: `C:\tools\switch_general_operation.bat` *(Double-click to activate)*
- **Configuration**: 128K context, `q8_0` KV cache, 8K reasoning tokens, temp 0.7, top_p 0.85.
- **Why this test**: Tests balanced conversational responsiveness and structured advice without excessive reasoning delay.

### Test Prompt to Paste into Bionic:
```text
I am building a web app using Node.js and SQLite. Explain the pros and cons of using WAL mode (Write-Ahead Logging) vs the default rollback journal, and provide a snippet showing how to configure WAL mode safely on startup.
```

---

## 3. Profile: `tool_use`
- **Switcher File**: `C:\tools\switch_tool_use.bat` *(Double-click to activate)*
- **Configuration**: 128K context, `q8_0` KV cache, 4K reasoning budget, low temp 0.3 (deterministic).
- **Why this test**: Tests strict adherence to JSON schemas and tool-calling format with zero hallucinated preamble.

### Test Prompt to Paste into Bionic:
```text
You have access to a tool named `deploy_service(name: string, port: number, env: object, restart_policy: 'always' | 'on-failure')`.
The user wants to deploy a Redis service on port 6379 with an environment variable `REDIS_PASSWORD=secret123` and always restart.
Output ONLY a valid JSON tool call conforming to this schema. No markdown explanations.
```

---

## 4. Profile: `long_tasks`
- **Switcher File**: `C:\tools\switch_long_tasks.bat` *(Double-click to activate)*
- **Configuration**: 128K context, `q4_0` quantized KV cache (maximum VRAM safety for >50K tokens), 12K reasoning tokens, temp 0.6.
- **Why this test**: Tests memory stability and needle-in-a-haystack retrieval across long sessions.

### Test Prompt to Paste into Bionic:
```text
Here is a project briefing with hidden details:
[Project Alpha began in 2024. Team members: Alice, Bob, Charlie. The secret database encryption key is 'KRYPTO-9988-SECURE'. The project deadline is Q4 2027.]
...
Based on the text above, what is the secret database encryption key, who are the team members, and what is the deadline? Answer in a concise bulleted list.
```

---

## 5. Profile: `max_intelligence`
- **Switcher File**: `C:\tools\switch_max_intelligence.bat` *(Double-click to activate)*
- **Configuration**: 128K context, `q8_0` KV cache, massive 24K reasoning budget, temp 1.0, top_p 0.95.
- **Why this test**: Tests deep multi-branch mathematical proofs and complex constraint riddles.

### Test Prompt to Paste into Bionic:
```text
Three gods A, B, and C are called True, False, and Random (in no particular order). True always speaks truly, False always speaks falsely, and Random speaks truly or falsely at completely random. You must determine the identities of A, B, and C by asking three yes-no questions; each question must be put to exactly one god. The gods understand English, but will answer in their own language, in which the words for 'yes' and 'no' are 'da' and 'ja', in some order. You do not know which word means which. 
Provide a complete, step-by-step rigorous logical solution to determine which god is which.
```

---

## 6. Profile: `max_speed`
- **Switcher File**: `C:\tools\switch_max_speed.bat` *(Double-click to activate)*
- **Configuration**: 128K context, `q4_0` KV cache, reasoning budget = 0 (Direct instant generation), temp 0.6.
- **Why this test**: Tests maximum token generation throughput (~68–75 t/s) with zero reasoning delay.

### Test Prompt to Paste into Bionic:
```text
Generate a list of 15 creative, futuristic project ideas for local AI applications running on edge devices. For each, give a catchy title, a 2-sentence description, and the recommended tech stack.
```
