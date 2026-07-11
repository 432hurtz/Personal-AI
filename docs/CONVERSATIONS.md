# Conversations: memory, organization, and deletion

Open WebUI (Joe's chat face) already handles all of this — and it's all **local**.
Every chat, setting, and memory lives in `./open-webui/` on your disk; nothing
is stored in any cloud.

## Keeping conversations separate

- Each chat is its own thread in the left sidebar. **New Chat** starts a fresh
  one. Joe only sees the **current** chat's history, so conversations stay
  isolated from each other — unless you deliberately enable Memory (below).
- Organize them:
  - **Folders** — create folders and drag chats into them.
  - **Tags** — tag a chat, then filter by tag.
  - **Pin** — keep important chats at the top.
  - **Search** — the search box finds text across all your chats.

## Deleting conversations

- **Delete one:** hover the chat in the sidebar → trash icon (or right-click →
  Delete).
- **Archive vs delete:** Archive hides a chat from the list without removing it;
  Delete removes it. Archived chats live under Settings → Chats.
- **Delete all:** Settings → Chats → you can archive, export, or delete every
  chat at once.

## Temporary (unsaved) chats

- Toggle **Temporary Chat** (top of a chat) for a session that is **never
  written to the database**. When you close it, it's gone — nothing to delete
  because nothing was saved. Good for a one-off sensitive question.

## Cross-conversation memory (optional — you control it)

- **Settings → Personalization → Memory.**
- **OFF by default**, which means every conversation is fully isolated: Joe
  remembers nothing between chats.
- Turn it **ON** and Joe can carry facts you've told it across chats. You can
  **view, edit, and delete** individual memories, or clear them all.
- For maximum separation, leave Memory OFF and use **Temporary Chat** for
  anything sensitive.

> Note: Joe's model context is also capped at `num_ctx` (4096 by default on your
> CPU). Very long chats get truncated to the most recent messages — another
> reason each topic works best as its own chat.

## Where it's stored, and truly purging it

Everything is in the local Open WebUI data volume:

- `./open-webui/webui.db` — a SQLite database holding your chats, settings, and
  memories.
- `./open-webui/` also holds uploaded files and RAG vector data.

Two things to know for real privacy:

1. **Deleting a chat removes its rows, but SQLite doesn't immediately zero the
   freed space.** To actually reclaim and purge deleted content, compact the
   database:

   ```powershell
   docker exec -it open-webui python3 -c "import sqlite3; c=sqlite3.connect('/app/backend/data/webui.db'); c.execute('VACUUM'); c.close()"
   ```

2. **Clean slate:** `docker compose down -v` deletes the entire Open WebUI
   volume — every chat, memory, and setting — and you start fresh next time.

**At rest:** because it's a plain database file on disk, enable **BitLocker**
(Windows 10 Pro) so a lost or stolen laptop doesn't expose your history. See
`docs/PRIVACY.md`.

## Quick reference

| I want to...                    | Do this                                         |
|---------------------------------|-------------------------------------------------|
| Start a separate conversation   | **New Chat**                                    |
| Group related chats             | Make a **Folder**, drag chats in                |
| Find an old chat                | **Search** box in the sidebar                   |
| Delete one conversation         | Hover chat → **trash** icon                      |
| Delete everything               | Settings → Chats → delete all                   |
| Ask something with no trace     | **Temporary Chat**                              |
| Remember facts across chats     | Settings → Personalization → **Memory** (on)    |
| Truly purge deleted data        | `VACUUM` the DB, or `docker compose down -v`    |
