# SSH from your phone (while the laptop is running)

Goal: reach the laptop from your phone to run `ollama`, check the stack, or open
the web UI — without exposing anything to the public internet.

Two situations:
- **Same Wi-Fi** (you're home): plain LAN SSH. Most private, nothing leaves the
  network.
- **Anywhere** (you're out): use **Tailscale** (a private WireGuard mesh). Do
  **not** port-forward SSH to the internet — that's the tracking/attack surface
  you're trying to avoid.

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

**On your phone**, in your SSH app (see Part 4), generate an ed25519 key and
copy its **public** key.

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
# (and add Tailscale's 100.64.0.0/10 if you use it, see Part 5).
Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" `
  -RemoteAddress 192.168.1.0/24,100.64.0.0/10
```

---

## Part 4 — Connect from the phone (same Wi-Fi)

Good SSH apps:
- **iPhone:** Termius or Blink Shell.
- **Android:** Termius or JuiceSSH; or Termux (`pkg install openssh`).

Connect:

```
ssh <your-windows-username>@192.168.1.42
```

You're in. `ollama list`, `ollama run personal-ai`, `docker compose ps`, etc.

## Part 5 — Reach the Open WebUI from your phone (the private way)

The web UI is bound to `127.0.0.1:3000` on purpose — it's **not** reachable over
the LAN, and you should keep it that way (the Ollama API behind it has no auth).
To use it from the phone, tunnel it through your SSH connection so it stays
loopback-only:

```
ssh -L 3000:localhost:3000 <your-windows-username>@192.168.1.42
```

Then open **`http://localhost:3000` in the phone's browser** while that SSH
session is up. The traffic rides the encrypted SSH tunnel; nothing is exposed.
Termius and Blink both have a "port forwarding" field so you don't have to type
the flag each time.

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
