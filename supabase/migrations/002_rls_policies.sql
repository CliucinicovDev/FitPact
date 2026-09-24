-- FitPact Row Level Security policies

-- profiles: each user manages and reads only their own profile
alter table profiles enable row level security;

create policy "profiles_select_own"
  on profiles for select
  using (auth.uid() = id);

create policy "profiles_insert_own"
  on profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on profiles for update
  using (auth.uid() = id);

-- workout_sessions: own full CRUD; squad members can read each other's
alter table workout_sessions enable row level security;

create policy "sessions_select_own_or_squad"
  on workout_sessions for select
  using (
    auth.uid() = user_id
    or exists (
      select 1 from challenge_members me
      join challenge_members other
        on me.challenge_id = other.challenge_id
      where me.profile_id = auth.uid()
        and other.profile_id = workout_sessions.user_id
    )
  );

create policy "sessions_insert_own"
  on workout_sessions for insert
  with check (auth.uid() = user_id);

create policy "sessions_update_own"
  on workout_sessions for update
  using (auth.uid() = user_id);

create policy "sessions_delete_own"
  on workout_sessions for delete
  using (auth.uid() = user_id);

-- rep_records: readable by whoever can read the parent session
alter table rep_records enable row level security;

create policy "reps_select_via_session"
  on rep_records for select
  using (
    exists (
      select 1 from workout_sessions s
      where s.id = rep_records.session_id
        and (
          s.user_id = auth.uid()
          or exists (
            select 1 from challenge_members me
            join challenge_members other
              on me.challenge_id = other.challenge_id
            where me.profile_id = auth.uid()
              and other.profile_id = s.user_id
          )
        )
    )
  );

create policy "reps_insert_own"
  on rep_records for insert
  with check (
    exists (
      select 1 from workout_sessions s
      where s.id = rep_records.session_id
        and s.user_id = auth.uid()
    )
  );

-- challenges: readable by members (and public while active)
alter table challenges enable row level security;

create policy "challenges_select_public_or_member"
  on challenges for select
  using (
    status = 'active'
    or exists (
      select 1 from challenge_members m
      where m.challenge_id = challenges.id
        and m.profile_id = auth.uid()
    )
  );

create policy "challenges_insert_own"
  on challenges for insert
  with check (auth.uid() = created_by);

create policy "challenges_update_creator"
  on challenges for update
  using (auth.uid() = created_by);

-- challenge_members: members visible within a shared challenge;
-- users manage only their own membership row
alter table challenge_members enable row level security;

create policy "members_select_same_challenge"
  on challenge_members for select
  using (
    profile_id = auth.uid()
    or exists (
      select 1 from challenge_members me
      where me.challenge_id = challenge_members.challenge_id
        and me.profile_id = auth.uid()
    )
  );

create policy "members_insert_own"
  on challenge_members for insert
  with check (profile_id = auth.uid());

create policy "members_update_own"
  on challenge_members for update
  using (profile_id = auth.uid());

create policy "members_delete_own"
  on challenge_members for delete
  using (profile_id = auth.uid());

-- proofs: only the session owner (and squad viewers) can read; owner writes
alter table proofs enable row level security;

create policy "proofs_select_via_session"
  on proofs for select
  using (
    exists (
      select 1 from workout_sessions s
      where s.id = proofs.session_id
        and (
          s.user_id = auth.uid()
          or exists (
            select 1 from challenge_members me
            join challenge_members other
              on me.challenge_id = other.challenge_id
            where me.profile_id = auth.uid()
              and other.profile_id = s.user_id
          )
        )
    )
  );

create policy "proofs_insert_own"
  on proofs for insert
  with check (
    exists (
      select 1 from workout_sessions s
      where s.id = proofs.session_id
        and s.user_id = auth.uid()
    )
  );