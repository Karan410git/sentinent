# Sacheta — Database Schema

## Architecture

```
auth.users  (Supabase-managed)
    │
    └── profiles            1-to-1 with auth.users
          │
          ├── diary_pages        user's private writing
          │
          ├── conversations      Sacheta conversation threads
          │     └── messages     individual messages
          │
          └── memories           Sacheta's persistent long-term memory
```

All user-owned tables reference `auth.users(id)` with `ON DELETE CASCADE`.
When a user is deleted from Supabase Auth, all their data is automatically removed.

## Tables

### profiles
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | References auth.users(id) |
| display_name | text | Nullable |
| language_style | text | Default 'balanced' |
| created_at | timestamptz | Auto |
| updated_at | timestamptz | Auto-triggered |

Auto-created on signup via database trigger.

### diary_pages
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | Auto-generated |
| user_id | UUID FK | References auth.users(id) |
| title | text | Nullable |
| content | text | Default '' |
| page_date | date | Default CURRENT_DATE |
| mode | text | 'my_pages' or 'sacheta' |
| created_at | timestamptz | Auto |
| updated_at | timestamptz | Auto-triggered |

My Pages entries (mode='my_pages') remain private to the user.
Sacheta AI does not automatically read My Pages content.

### conversations
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | Auto-generated |
| user_id | UUID FK | References auth.users(id) |
| title | text | Nullable |
| created_at | timestamptz | Auto |
| updated_at | timestamptz | Auto-triggered |

### messages
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | Auto-generated |
| conversation_id | UUID FK | References conversations(id) |
| user_id | UUID FK | References auth.users(id) |
| role | text | 'user' or 'sacheta' |
| content | text | Message body |
| created_at | timestamptz | Auto |

user_id is retained for direct ownership enforcement in RLS.

### memories
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | Auto-generated |
| user_id | UUID FK | References auth.users(id), UNIQUE |
| content | jsonb | Full memory object |
| created_at | timestamptz | Auto |
| updated_at | timestamptz | Auto-triggered |

One row per user. Content structure:
```json
{
  "facts": ["User's name is Alex", "..."],
  "themes": ["anxiety about career", "..."],
  "style": { "tone": "reflective", "length": "medium" },
  "lastUpdated": "2025-01-01T00:00:00Z"
}
```

## Ownership Model

Every user-owned row stores `user_id` (or `id` for profiles) referencing `auth.users(id)`.
This is enforced at **three levels**:

1. **Application layer** — Flutter/Backend set user_id from the authenticated Supabase session
2. **RLS policies** — Database rejects any query where `auth.uid() ≠ user_id`
3. **Foreign keys** — Cascade delete ensures no orphaned rows

## RLS Rules Summary

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| profiles | own only | own only | own only | — |
| diary_pages | own only | own only | own only | own only |
| conversations | own only | own only | own only | own only |
| messages | own only + conversation check | own only + conversation check | own only + conversation check | own only + conversation check |
| memories | own only | own only | own only | own only |

Messages have an additional check: the parent conversation must also belong to `auth.uid()`.

Unauthenticated requests see **zero rows** on all tables.

## Indexes

- `diary_pages(user_id)` — fast lookup by owner
- `diary_pages(user_id, page_date)` — date-range queries within a user
- `conversations(user_id)` — fast lookup by owner
- `messages(conversation_id)` — load messages for a conversation
- `messages(user_id)` — direct user message queries
- `memories(user_id)` — fast lookup by owner

## Triggers

- **set_updated_at()** — auto-updates `updated_at` on any UPDATE to profiles, diary_pages, conversations, or memories
- **handle_new_user()** — SECURITY DEFINER trigger on auth.users INSERT → auto-creates a profiles row with defaults

## What Phase 3 Will Connect

- Install `supabase_flutter` in the Flutter project
- Replace `SessionService` local auth with Supabase Auth
- Replace `DiaryRepository` (JSON file) with Supabase `diary_pages` table
- Replace `ConversationRepository` (JSON file) with Supabase `conversations` + `messages` tables
- Replace backend `lib/memory.js` (JSON file) with Supabase `memories` table
- Backend API calls will verify Supabase JWTs

## Secrets Intentionally NOT in This File

- Supabase URL
- Supabase anon key
- Supabase service_role key
- Database password

These live in `.env` (gitignored) and Supabase Dashboard only.
