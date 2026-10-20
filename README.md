# ITPC111 Student Scholarship Monitoring and Academic Compliance System

A browser-based MVP built with HTML, CSS, JavaScript, Supabase Auth, PostgreSQL, RLS, and database RPC functions.

## Included
- Scholar signup/sign-in and profile creation trigger
- Staff-managed scholar account creation and program assignment through a Supabase Edge Function
- Staff editing for scholar profiles and persisted scholarship policies
- Scholar submission form with validation and unique semester constraint
- Staff verification / return workflow
- Program-configurable compliance evaluation
- Controlled renewal decisions and audit events
- Dashboard metrics, search, and filters
- Staff-only audit history; scholars can access only their own scholarship and submissions
- Responsive interface

## Important security notes
- `config.js` may contain the Supabase project URL and publishable/anon key only.
- Never place a Supabase `service_role` key in frontend code.
- The first signup always creates a `scholar` role. To create the first staff user, create an account normally, then promote that profile to `staff` from the Supabase SQL Editor after verifying the account:
  ```sql
  update public.profiles set role = 'staff'
  where id = (select id from auth.users where email = 'staff@example.com');
  ```
  Use a synthetic test account and do not share staff credentials.
- Staff scholar creation is handled by `supabase/functions/staff-create-scholar`. Deploy it with the Supabase URL, anon key, and service-role key configured as Edge Function secrets; the service-role key must never be placed in `config.js` or browser code. It verifies the caller as staff, creates a scholar account, and assigns the selected saved program.
- RLS is enabled. Privileged workflow transitions and staff profile/policy edits have no direct client write policy and use staff-checked SQL functions. Direct submission inserts are disabled; all submissions use the audited `submit_grades` function.
- Audit history is staff-only in both RLS and the interface.
- Before deployment, review every SQL function and policy with your instructor/security reviewer.

## Setup
1. Create a Supabase project.
2. In SQL Editor, run `supabase/schema.sql` on a fresh project. If upgrading a database created from an earlier version, run `supabase/upgrade.sql` instead.
3. Copy the project URL and publishable (or anon) key from Supabase Project Settings > API.
4. Paste both into `config.js`.
5. Serve the folder from a local web server. For example, in the project folder:
   ```bash
   python -m http.server 8000
   ```
   Open `http://localhost:8000`. Avoid opening `index.html` as a `file://` URL.
6. Create a scholar account using the Create scholar account tab.
7. Create a second synthetic account, then promote it to staff using the SQL shown above.
8. In Supabase SQL Editor, assign the test scholar to a program using the SQL below, substituting the actual UUID values:
   ```sql
   insert into public.scholar_assignments (scholar_id, program_id, assigned_by)
   select
     (select id from public.profiles where student_id = 'TEST-001'),
     (select id from public.scholarship_programs where name = 'Merit Scholar'),
     (select id from public.profiles where role = 'staff' limit 1);
   ```
9. Sign in as scholar and submit a semester record. Sign in as staff to verify, evaluate, and record a renewal decision.
10. Install the Supabase CLI, link the project, set Edge Function secrets, and deploy the staff registration function:
  ```bash
  supabase secrets set SUPABASE_URL=https://YOUR_PROJECT.supabase.co SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
  supabase functions deploy staff-create-scholar
  ```
  Run these commands in a trusted terminal. Never add the service-role key to project files or frontend configuration.

## Operational notes
- Returned submissions can be corrected and resubmitted; the database resets verification, evaluation, and renewal state and records an audit event.
- The submissions view searches by student ID or name and filters by semester, program, verification, and compliance. Dashboard statistics respond to the semester selector.
- For the examination's exact deadline test, seed controlled test data in a test environment. The database timestamp defaults to submission time, so the one-minute-late case needs a controlled test fixture or a timestamp-safe test-only seed.
- Audit history records submission, verification, evaluation, and renewal events. Profile and program administration changes are staff-only but are not currently written to the submission audit log.

## Policy thresholds seeded
- Merit Scholar: maximum GWA 1.75, minimum units 18, zero failed/incomplete/dropped subjects.
- Community Scholar: maximum GWA 2.25, minimum units 15, zero failed/incomplete subjects, at most one dropped subject.
- Deadline: 2026-10-30 17:00 Asia/Manila.

## Examination test checklist
Run TC01–TC10 from the PDF and record actual results, screenshots, and defects. Do not mark a test passed until you execute it.
