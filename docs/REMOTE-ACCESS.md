# SSH from your phone (while the laptop is running)

Goal: reach the laptop from your phone to run `ollama`, check the stack, or open
the web UI — without exposing anything to the public internet.

## Start here — which option do I want?

| Situation | Use | What to read |
|---|---|---|
| I'm on the **same Wi-Fi** as the laptop | Plain LAN SSH | Parts 1–5 |
| I want to reach it **from anywhere** (mobile data, other Wi-Fi) | Tailscale | Parts 1–3, then Part 6 |

Either way you do the **one-time setup in Parts 1–3 first** (turn on SSH, add
your phone's key, lock it down). After that, connecting is a single command.

**The 30-second version**, once setup is done:
```
# shell in (home Wi-Fi):            ssh you@192.168.1.42
# shell in (anywhere, Tailscale):   ssh you@100.x.y.z
# get the web UI on your phone too:  add  -L 3000:localhost:3000  then open http://localhost:3000
```
Throughout this doc, replace **`you`** with your Windows username and the **IP**
with your laptop's actual address (Part 1 shows how to find it).

---

## Part 1 — Turn on the SSH server in Windows (one time)

Open **PowerShell as Administrator**:

```powershell
# Install and start the built-in OpenSSH server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# (optional) make PowerShell the default shell you land in
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell `
  -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -PropertyType String -Force
```

Find the laptop's LAN IP (you'll SSH to this from the phone):

```powershell
ipconfig | Select-String IPv4      # e.g. 192.168.1.42
```

## Part 2 — Lock it down: keys only, no passwords

Password SSH is guessable and a tracking/attack surface. Use a key.

**On your phone first**, make a key and grab its *public* half. Concretely, in
**Termius** (free, iPhone + Android):

1. Install Termius → tab **Keychain** → **+** → **Generate Key**.
2. Type **ED25519**, give it a name, **Generate**.
3. Open that key → **Copy Public Key**. That's the string (starts with
   `ssh-ed25519 AAAA...`) you paste on the laptop below.

(JuiceSSH/Blink/Termux are similar; in Termux it's `ssh-keygen -t ed25519` then
`cat ~/.ssh/id_ed25519.pub`.)

**On the laptop**, because your Windows account is almost certainly an admin,
the key must go in the *administrators* file with tight permissions (this trips
everyone up):

```powershell
# Paste your phone's PUBLIC key into this file
notepad C:\ProgramData\ssh\administrators_authorized_keys

# Fix permissions (required, or key auth is silently ignored)
icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r
icacls C:\ProgramData\ssh\administrators_authorized_keys /grant "Administrators:F" "SYSTEM:F"
```

> If your account is a *standard* (non-admin) user instead, the key goes in
> `C:\Users\<you>\.ssh\authorized_keys` — not the file above.

Then disable password auth. Edit `C:\ProgramData\ssh\sshd_config` and set:

```
PubkeyAuthentication yes
PasswordAuthentication no
```

Restart the server:

```powershell
Restart-Service sshd
```

## Part 3 — Firewall: keep it to your network only

Windows adds an SSH firewall rule automatically. Tighten it so only your LAN /
Tailscale range can reach port 22 — never the whole internet:

```powershell
# Example: allow only your home subnet. Adjust to your actual subnet
# (and add Tailscale's 100.64.0.0/10 if you use it, see Part 6).
Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" `
  -RemoteAddress 192.168.1.0/24,100.64.0.0/10
```

---

## Part 4 — Connect from the phone (same Wi-Fi)

In **Termius**: tab **Hosts** → **+** → **New Host**:
- **Address:** your laptop's LAN IP (e.g. `192.168.1.42`)
- **Username:** your Windows username
- **Key:** pick the ED25519 key you made in Part 2
- Leave port `22`.

Tap the host to connect. You're in — try `ollama list`,
`ollama run joe`, `docker compose ps`.

Prefer typing it? From a terminal app (Termux, Blink):
```
ssh you@192.168.1.42        # replace "you" and the IP with yours
```

## Part 5 — Get the Open WebUI on your phone (the private way)

The web UI is bound to `127.0.0.1:3000` on purpose — it's **not** reachable over
the LAN, and you should keep it that way (the Ollama API behind it has no auth).
To use it from the phone, **tunnel** it through your SSH connection so it stays
loopback-only.

**In Termius** (easiest — set it once): open your host → **Port Forwarding** →
**+** → type **Local**:
- **Bind/Local port:** `3000`
- **Destination host:** `localhost`   **Destination port:** `3000`

Start that forward, then open **`http://localhost:3000` in your phone's
browser**. That's it — the traffic rides the encrypted SSH tunnel; nothing is
exposed to the network.

**Typing it instead?** The `-L` flag does the same thing:
```
ssh -L 3000:localhost:3000 you@192.168.1.42
```
Keep that session open and browse to `http://localhost:3000` on the phone.

## Part 6 — Access from anywhere (Tailscale)

To reach the laptop when you're *not* on home Wi-Fi, without opening any router
ports:

1. Install **Tailscale** on the laptop and on the phone; sign in to both with
   the same account. They join a private WireGuard network.
2. The laptop gets a stable `100.x.y.z` address. SSH to *that* from the phone,
   anywhere: `ssh <user>@100.x.y.z`, and the same `-L 3000:localhost:3000`
   tunnel works for the web UI.

**Privacy note on Tailscale:** your actual SSH/web traffic is end-to-end
WireGuard-encrypted and goes **device-to-device** — Tailscale's servers relay
connection setup and see metadata (which devices connect, when), not your
content. If you want *zero* third party at all, skip Tailscale and use LAN-only
(Part 4), or self-host **WireGuard** / **Headscale** (the open-source Tailscale
control server). LAN-only is the most private; Tailscale is the most
convenient; pick your trade-off.

**Never** forward port 22 (or 3000) on your router to the internet as a
shortcut — that exposes the machine to constant background scanning and is
exactly the kind of surface you're trying to avoid.

---

## Quick reference

| I want to...                    | Do this                                        |
|---------------------------------|------------------------------------------------|
| Shell in on home Wi-Fi          | `ssh user@<lan-ip>`                            |
| Use the web UI from phone       | `ssh -L 3000:localhost:3000 user@<lan-ip>`, open `localhost:3000` |
| Reach it from anywhere          | Install Tailscale, `ssh user@<tailscale-ip>`  |
| Confirm the server is running   | `Get-Service sshd` (should say Running)        |
