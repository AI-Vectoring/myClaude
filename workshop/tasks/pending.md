# Pending Tasks

- Implement memory
- Finalize the status line
Implement Agent Modes like in roo and kilo? (using /commands?)
Add a collection of prompts via commands make prompts/commands composable
we need to choose if we ovewrite or keep the permissions added by claude.

phase 3: gain full control of the context (or close to it) by eliminting it each time and sending a new one?
if that does not work, try with roo/kilo/clain or even aider?
the idea that you only need what the user said to keep a full record of what was said.
the idea of a table and a tree to navigate everything that is needed.
a writer that builds that table, especially in AIV mode.
revisit task or function based access patterns like the ones mentioned in the cc docs?
consider neverAsk one last time before "discarding it"
Are we using do not ask for red/forbidden or what are we using?
alert when billing goes crazy, have a termometer showing you spent tokens in the last tick.
webfetch and websearch are different things??? perms for each? etc...
Add a git rule and define safe vs  dangerous bash commands to give better fine-grained modes.
more permissions to consider: toolcall,shell commands, file writes, web requests, and similar actions. modes with plan instead of default?
create, write, edit, how to use don't ask to benefit from smart choosing? (is this a thing really?) 
, what is considered " irreversible effects" and how do we create a mode specific to this?






https://code.claude.com/docs/en/permissions

Assuming default is the base:

1. Exact Evaluation Order (Per Action)
Every tool call passes through this deterministic chain. First match wins.

    Hardcoded Safety → Intercepts rm -rf, sudo, curl | sh, credential paths, force git. Overrides all config. Forces prompt or block.
    Merged deny → Scanned across all config scopes. First match = immediate block (Red).
    Merged ask → If you explicitly define ask rules, they force a prompt regardless of allow.
    Merged allow → Scanned across all config scopes. First match = auto-approve (Green).
    default Fallback → If no rule matches, CC prompts (Yellow). This is the implicit behavior of mode: "default".

2. Precedence & Supersession Rules

    deny always supersedes allow. Even if Bash is in allow, deny: ["Bash(git push *)"] blocks it.
    Higher config scopes supersede lower scopes only for conflicting directives, but arrays are concatenated, not replaced. allow rules accumulate across files. deny rules accumulate across files.
    Hardcoded safety supersedes everything. Cannot be overridden by any config file.
    default mode does not change the pipeline. It only defines the fallback action for unmatched tools.

3. How Arrays Merge Across Scopes
From official settings docs:

    "Array-valued settings (like permissions.allow or permissions.deny) are merged across scopes. Entries are concatenated and deduplicated." [[code.claude.com/docs/en/settings]]

This means:

    ~/.claude/settings.json allow: ["Read"]
    .claude/settings.json allow: ["Edit"]
    Effective result: allow: ["Read", "Edit"] (both auto-approved)
    Add .claude/settings.local.json deny: ["Edit(/.env*)"]
    Effective result: Edit is green globally, but Edit(/.env*) is red everywhere.

4. Statusline Mapping (Real-Time)

    Green: Tool/command matches an allow rule. Auto-executes.
    Yellow: No allow match, no deny match, passes safety checks. Falls back to default prompt behavior.
    Red: Matches deny rule or hardcoded safety override. Blocked immediately.

5. How to Verify Effective Rules

    Inside CC: /permissions → Lists every active rule, its state (allow/deny/ask), and the exact config file it came from. [[code.claude.com/docs/en/permissions]]
    Inside CC: /status → Shows which config scopes are loaded and their file paths. [[code.claude.com/docs/en/settings]]
    CLI: cat .claude/settings.json .claude/settings.local.json ~/.claude/settings.json → Manually inspect merged sources.

Bottom Line
default + allow is a pure allowlist model. Everything in allow goes green. Everything else goes yellow (prompt). deny turns specific matches red. Hardcoded safety blocks known destructive patterns. Arrays merge additively across scopes. deny wins conflicts. You verify the merged state live via /permissions. No hidden state. No session caching. Fully deterministic.




///////////////////////////////////////////////////////////////////////////////////////




How to keep greater control  off and manipulate the context?

Verified Search Results: Claude Code Hooks & Context
UserPromptSubmit Hook (Official)

    Fires when you submit a prompt, before Claude processes it 
    code.claude.com
    Receives prompt field containing the submitted text via stdin 
    code.claude.com
    Can inject context using additionalContext in JSON output, not plain stdout 
    code.claude.com
    Cannot access the full messages[] array, system prompt, or token state 
    code.claude.com
    Cannot block or rewrite the original prompt; can only append context or return {"decision": "block"} 
    code.claude.com

CLAUDE.md Loading Behavior (Official)

    Loaded at the start of every conversation, treated as context not enforced configuration 
    code.claude.com
    Two memory systems: project-level and user-level CLAUDE.md files 
    code.claude.com
    Mid-session edits do not take effect until a new session starts 
    code.claude.com
    InstructionsLoaded hook fires when these files are parsed into context 
    code.claude.com

Context Compaction (Official)

    Handled automatically by the system with minimal integration work 
    platform.claude.com
    Extends effective context length for long-running conversations 
    platform.claude.com
    No public API exposes compaction thresholds or retention logic 
    platform.claude.com
    PreCompact and PostCompact hooks fire before/after but do not receive payload content 
    code.claude.com

Debug Mode (Official)

    Enable with CLAUDE_DEBUG=1 or --debug flag 
    code.claude.com
    Outputs structured timing info and hook stdout/stderr to stderr 
    www.mintlify.com
    Includes category filtering (e.g., api, hooks) for targeted logging 
    code.claude.com
    Not designed for real-time programmatic injection; append-only diagnostic stream 
    code.claude.com

additionalContext Injection (Official)

    Use additionalContext field in hook JSON output to inject text into Claude's context 
    code.claude.com
    Plain stdout from hooks is visible in transcript; additionalContext is more discrete 
    code.claude.com
    Supported in UserPromptSubmit, SessionStart, PostToolUse hooks 
    GitHub
    Not supported in PreToolUse hooks as of current documentation 
    GitHub

Hard Boundaries (Verified)

    Hooks receive event-scoped payloads only; no access to full context window 
    code.claude.com
    CLAUDE.md is not reloaded on every turn; loaded once at session initialization 
    code.claude.com
    Compaction detection must be inferred from external observation; no explicit event payload 
    platform.claude.com
    All injected context enters the messages array and is subject to token limits and compaction 
    code.claude.com

Direct Answer to Your Pipeline Question
The three-stream pipeline (debug capture + state ledger + hook injection) is a valid custom implementation built on top of these documented primitives. The official docs provide:

    The hook execution points and payload schemas 
    code.claude.com
    The additionalContext injection mechanism 
    code.claude.com
    The debug output format and CLI flags 
    code.claude.com
    The memory loading behavior 
    code.claude.com

Everything else—ledger sync, compaction inference, tag-based routing, background watchers—must be implemented externally. No search result shows native support for full-context observation or silent per-turn injection.
If you need the exact JSON schema for UserPromptSubmit input/output or a minimal starter hook script, I can extract that from the official docs next.




///////////////////////////////////////////////////////////////////////////////////////


At their absolute core, they boil down to a four-step automated loop:

    Inject context (files, errors, instructions) into an LLM
    Receive a tool call (edit file, run command, check test)
    Execute it in your environment
    Feed the output back to the LLM and repeat

They turn a stateless text generator into a stateful edit-test-fix cycle. Everything else—context compression, rule files, approval gates, memory—is just scaffolding to keep that loop running longer, safer, and with fewer human interruptions.


All four allow continuous, per-turn context manipulation by intercepting the message assembly step before the LLM call. The difference is how much loop infrastructure you inherit:

    gptme and smolagents provide a working harness with exposed context pipelines but retain tool execution and turn management.
    llm removes the agent loop entirely, leaving only API routing and basic prompt handling.
    Raw litellm removes all scaffolding, leaving only a standardized completion call.







    ///////////////////////////////////////////////////////////////////////////////////////

https://gptme.ai/

https://github.com/gptme/gptme

https://www.youtube.com/watch?v=_ZFcpsg6IMI
https://www.youtube.com/watch?v=ERrBWvJ2t9Y

gptme documentation

Welcome to the documentation for gptme!

gptme is a personal AI assistant and agent platform that runs in your terminal and browser, equipped with powerful tools to execute code, edit files, browse the web, and more - acting as an intelligent copilot for your computer. The core components include:

    gptme CLI: The main command-line interface for terminal-based interactions

    gptme-server: A server component for running gptme as a service

    gptme-webui: A web interface for browser-based interactions

    gptme-agent-template: A template for creating custom AI agents

The system can execute python and bash, edit local files, search and browse the web, and much more through its rich set of built-in tools and extensible tool system. You can see what’s possible in the Examples and Demos, from creating web apps and games to analyzing data and automating workflows.

Getting Started: To begin using gptme, follow the Getting Started guide, set up your preferred LLM provider, and customize your configuration as needed.

The system is designed to be easy to use and extend, and can be used as a library, standalone application, or web service. For detailed usage patterns and features, see the Usage guide.

Core Architecture

    Built as a terminal-native conversational agent. The runtime centers on a Chat object that stores messages, a Model abstraction for provider routing, and a deterministic loop: read input → build context → call LLM → parse response → execute tools → append result → repeat.
    No autonomous planning, no hidden state machines, no vector search. Context is constructed from system instructions, conversation history, explicitly attached files, and recent tool outputs.

Context Assembly & Per-Turn Hook

    Messages are held in a linear list. Before each LLM call, the framework runs a formatting step that merges system prompt, history, and tool context into the final payload.
    The injection point is the message preparation stage. You can intercept or replace the message list right before the model call by:
        Overriding the prompt builder function that formats the system + history block
        Clearing or mutating the Chat.messages list between turns
        Injecting arbitrary text, file contents, or error logs into the message array prior to the LLM call
    The loop is synchronous and step-bound. You can drive it programmatically by calling the internal turn function once, injecting your context, then repeating.

Built-in Opinions

    Assumes interactive terminal use by default. Headless/scripted usage requires bypassing the REPL layer and calling the core loop directly.
    Includes a tool execution registry and response parser. If you only want raw context injection without tool routing, you’d stub out the tool dispatcher or disable execution after parsing.
    Git integration is optional and not enforced, unlike aider. File context is added explicitly rather than auto-scanned.

Modification Surface

    Python codebase with flat structure. The context pipeline, message storage, and loop are separated into distinct modules. You can fork the core loop or wrap it with a controller that swaps the message list exactly once per turn.



https://www.youtube.com/watch?v=Cb8lEF8lC7E

https://github.com/huggingface/smolagents
https://huggingface.co/docs/smolagents/index

What is smolagents?

smolagents is an open-source Python library designed to make it extremely easy to build and run agents using just a few lines of code.

Key features of smolagents include:

✨ Simplicity: The logic for agents fits in ~thousand lines of code. We kept abstractions to their minimal shape above raw code!

🧑‍💻 First-class support for Code Agents: CodeAgent writes its actions in code (as opposed to “agents being used to write code”) to invoke tools or perform computations, enabling natural composability (function nesting, loops, conditionals). To make it secure, we support executing in sandboxed environment via Modal, Blaxel, E2B, or Docker.

📡 Common Tool-Calling Agent Support: In addition to CodeAgents, ToolCallingAgent supports usual JSON/text-based tool-calling for scenarios where that paradigm is preferred.

🤗 Hub integrations: Seamlessly share and load agents and tools to/from the Hub as Gradio Spaces.

🌐 Model-agnostic: Easily integrate any large language model (LLM), whether it’s hosted on the Hub via Inference providers, accessed via APIs such as OpenAI, Anthropic, or many others via LiteLLM integration, or run locally using Transformers or Ollama. Powering an agent with your preferred LLM is straightforward and flexible.

👁️ Modality-agnostic: Beyond text, agents can handle vision, video, and audio inputs, broadening the range of possible applications. Check out this tutorial for vision.

🛠️ Tool-agnostic: You can use tools from any MCP server, from LangChain, you can even use a Hub Space as a tool.

💻 CLI Tools: Comes with command-line utilities (smolagent, webagent) for quickly running agents without writing boilerplate code.



Core Architecture

    Designed by Hugging Face as a transparent, single-file agent framework. No hidden planning layers, no opaque memory compression. The agent runs on a step() method that processes exactly one turn.
    Memory is a first-class object (agent.memory) holding a list of structured Message objects. The system prompt, tool definitions, and model client are explicitly passed during initialization.

Context Assembly & Per-Turn Hook

    Context is assembled inside agent.step(). It reads from agent.memory.messages, applies the system prompt, formats tool schemas, and sends the payload to the LLM.
    Direct per-turn control is exposed through the memory API:
        agent.memory.messages can be cleared, replaced, or appended before calling .step()
        System prompt can be swapped or augmented between turns
        You can inject arbitrary context (files, logs, instructions) as Message objects with explicit roles (system, user, assistant)
    The framework expects you to drive the loop if needed. Calling .step() once processes exactly one turn and returns the result, making continuous external control straightforward.

Built-in Opinions

    Assumes you will use tools. The default agent routes LLM outputs to a tool parser and executes them. If you only want context injection, you can run the agent with an empty tool list or override the execution step to return raw text.
    Includes code execution and markdown parsing utilities. These can be bypassed by subclassing the agent and returning early from the tool router.
    Memory is not auto-pruned or summarized. You retain full control over token window management, but you must implement your own truncation or sliding-window logic if context grows.

Modification Surface

    Highly readable, intentionally minimal. The step() method, memory object, and prompt formatter are public. You can override setup_step() or prepare_model_inputs() to run a custom context pipeline exactly once per iteration without touching execution logic.




Structural Comparison for Your Requirement
Aspect
	
gptme
	
smolagents
Turn granularity
	
Loop-driven; context built before each model call
	
Step-driven; .step() processes exactly one turn
Context storage
	
Linear message list inside Chat
	
Explicit Memory object holding Message list
Per-turn injection
	
Intercept message builder or mutate Chat.messages before LLM call
	
Clear/replace agent.memory.messages before .step()
Tool routing
	
Built-in dispatcher; can be stubbed or disabled
	
Default parser/executor; can be bypassed with empty tools or early return
State management
	
No auto-compression; history grows until manually cleared
	
No auto-compression; you manage window limits
External control
	
Requires wrapping CLI/core loop or forking turn function
	
Designed for programmatic .step() driving; no REPL dependency
License
	
MIT
	
Apache 2.0
Both expose the exact message array that feeds the LLM before each call. The difference lies in loop control: gptme wraps the turn in a REPL-oriented cycle that you’d script or subclass, while smolagents exposes a single-step method (step()) that naturally aligns with external turn-by-turn driving. Neither auto-injects hidden context, summarizes history, or enforces project scanning. Both require you to handle token windowing and tool routing if you keep those layers active.







Structural reality: Tools that expose per-turn context without hidden planning or auto-context injection are rare. Most either lock you into a fixed workflow (aider, Roo, Cline) or give you a blank API wrapper (llm). gptme and smolagents sit in the middle: visible loops, explicit message arrays, and no forced context injection. The choice between them reduces to whether you want a terminal application you can intercept (gptme) or a library you can drive programmatically (smolagents). Both allow you to replace or mutate the context exactly once per turn before the LLM call.


