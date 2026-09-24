-- FitPact initial schema
-- Tables: profiles, workout_sessions, rep_records, challenges, challenge_members, proofs

create extension if not exists "pgcrypto";

create type exercise_type as enum ('pushUp', 'squat', 'plank', 'burpee');
create type sync_status as enum ('pending', 'syncing', 'synced', 'failed', 'conflict');
create type challenge_status as enum ('active', 'completed', 'cancelled');

-- User profile, 1:1 with auth.users
create table profiles (
 id uuid primary key references auth.users (id) on delete cascade,
 display_name text not null check (char_length(display_name) between 1 and 40),
 created_at timestamptz not null default now(),
 analytics_consent boolean not null default false,
 personalization_consent boolean not null default false
);

-- A recorded workout session
create table workout_sessions (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references profiles (id) on delete cascade,
 exercise_type exercise_type not null,
 start_time timestamptz not null,
 end_time timestamptz,
 rep_count integer not null default 0 check (rep_count >= 0),
 form_average double precision not null default 0
 check (form_average between 0 and 1),
 status sync_status not null default 'pending'
);

create index idx_sessions_user_start on workout_sessions (user_id, start_time desc);

-- A single counted rep
create table rep_records (
 id uuid primary key default gen_random_uuid(),
 session_id uuid not null references workout_sessions (id) on delete cascade,
 timestamp timestamptz not null,
 phase_durations jsonb not null default '{}'::jsonb,
 form_score double precision not null default 0
 check (form_score between 0 and 1),
 feedback_message text,
 landmarks_json jsonb
);

create index idx_reps_session_ts on rep_records (session_id, timestamp);

-- A challenge
create table challenges (
 id uuid primary key default gen_random_uuid(),
 title text not null check (char_length(title) between 1 and 80),
 exercise_type exercise_type not null,
 goal_reps integer not null check (goal_reps > 0),
 duration_days integer not null check (duration_days between 1 and 90),
 invite_code text not null unique check (char_length(invite_code) = 6),
 status challenge_status not null default 'active',
 created_by uuid not null references profiles (id) on delete cascade,
 created_at timestamptz not null default now()
);

create index idx_challenges_status on challenges (status);

-- Challenge membership (max 10 members enforced by trigger)
create table challenge_members (
 id uuid primary key default gen_random_uuid(),
 challenge_id uuid not null references challenges (id) on delete cascade,
 profile_id uuid not null references profiles (id) on delete cascade,
 joined_at timestamptz not null default now(),
 total_reps integer not null default 0 check (total_reps >= 0),
 lives_remaining integer not null default 3 check (lives_remaining between 0 and 3),
 unique (challenge_id, profile_id)
);

create index idx_members_challenge on challenge_members (challenge_id, total_reps desc);

create or replace function enforce_max_members() returns trigger as $$
begin
 if (select count(*) from challenge_members
 where challenge_id = new.challenge_id) >= 10 then
 raise exception 'challenge full: max 10 members';
 end if;
 return new;
end;
$$ language plpgsql;

create trigger trg_max_members
 before insert on challenge_members
 for each row execute function enforce_max_members();

-- Signed proof of work
create table proofs (
 id uuid primary key default gen_random_uuid(),
 session_id uuid not null references workout_sessions (id) on delete cascade,
 frames jsonb not null,
 hmac_signature text not null,
 created_at timestamptz not null default now()
);

create index idx_proofs_session on proofs (session_id);