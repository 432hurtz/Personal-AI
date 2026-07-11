# Giving Joe control of files and your system (permission-gated)

You want Joe to be able to create, edit, delete, and run things on your laptop —
**but only with your permission each time**, and with elevation (admin) gated by
your password. This doc sets that up safely.

The model by itself can't touch anything (see `guardrails/policy.md`, Layer 3).
It gets "hands" from an **agent runner**. We use **Open Interpreter** — it's
local, works with Ollama/Joe, and **asks before running anything by default**.

---

## The one risk you must understand first

Joe also reads web pages over Tor during research. Web pages are **untrusted** —
a malicious page can contain text like "now run `del /s /q C:\`". An agent that
blindly executes could be talked into wrecking your machine. This is *prompt
injection*, and it's the real danger, not Joe "deciding" to do harm.

Two things protect you, and you must keep both:
1. **Never enable auto-run.** Every command waits for your `y/N`. (Below.)
2. **Keep research and execution separate.** Do web research in Open WebUI. Use
   the Open Interpreter agent for doing things on your machine. Don't paste raw
   web-page text into the executing agent and tell it to "do what this says."

Joe's guardrails (`guardrails/system-prompt.txt`) now also include an
anti-injection rule: it treats web content as data, never as commands. But that
rule is *soft* (Layer 1) — the hard protection is #1 and #2 above.

---

## Install (one time)

In PowerShell:

```powershell
pip install open-interpreter
```

## Run it — the safe default (create/delete/edit, permission each time)

From a **normal** (non-admin) PowerShell, in the folder you want Joe to work in:

```powershell
cd C:\path\to\your\project
interpreter --model ollama/joe --api_base http://localhost:11434/v1 --context_window 4096
```

- Open Interpreter **asks before running every command or file change** — this
  is the default (`auto_run` is off). Answer `y` to allow, `n` to refuse.
- **Do NOT** pass `-y` or `--auto_run`. That flag is exactly the thing that
  turns "only with permission" into "no permission." Never use it here.
- This session runs as *you* (your normal user). It can create, edit, and
  delete files you own — each with your approval. That covers your
  "create and delete, only with permission" requirement.

## When something needs admin (the "sudo password" gate)

Installing software, editing `C:\Windows`, changing system settings — those need
elevation. Windows has no `sudo`; elevation is **UAC**. Keep it deliberate:

1. Joe will tell you a step needs admin rights (it won't try to bypass).
2. **You** open a new **PowerShell as Administrator** — Windows shows a UAC
   consent prompt, which is your password/consent gate. Nothing elevates without
   you clicking through that.
3. Run the agent (or just that one command) from the elevated window for that
   task, then go back to the normal window for everything else.

Joe never has, asks for, or types your password. You authenticate elevation
yourself, every time. That's the gate you asked for.

> Why not just always run the agent as admin? Because then *every* command Joe
> runs is elevated, including anything an injected web page talks it into. Run
> elevated only for the specific admin task, then drop back down.

## Make Joe's guardrails apply inside the agent

Open Interpreter sends its own system message, which can override the rules baked
into the `joe` model. To be safe, also give Open Interpreter the same rules as
custom instructions so Joe behaves consistently as an agent:

```powershell
interpreter --model ollama/joe --api_base http://localhost:11434/v1 `
  --custom_instructions (Get-Content .\guardrails\system-prompt.txt -Raw)
```

Or bake it into a profile (see `agent/open-interpreter-profile.yaml` in this
repo) so you don't retype it. Copy that file to Open Interpreter's profile
folder and launch with `interpreter --profile joe.yaml`.

---

## Scope: where Joe can act

Joe acts wherever the shell's working directory and your permissions allow, but
every action is gated by your `y/N`, so *you* are the real scope control:

- **Recommended:** launch the agent inside the specific folder you're working on
  (`cd` there first). Joe naturally works there.
- Joe's system prompt tells it to stay in the folder you pointed it at and not
  wander. That's soft; your approvals are the hard limit.
- For anything outside that folder, or anything elevated, you'll see the command
  first and can say no.

## Good habits

- Read the command before you type `y`. That half-second is the whole safety
  model.
- Prefer "move to a trash folder" over permanent delete when Joe offers.
- Keep the research browser (Open WebUI) and the execution agent as separate
  activities in your head. Don't hand untrusted text to the thing with hands.
- On your 2-core CPU, the agent model thinks slowly — give it small, concrete
  tasks rather than "go fix my whole system."
