-- Apply once to a project that already ran an earlier version of schema.sql.
-- Fresh projects should run schema.sql instead.

drop policy if exists "Insert own assigned submission" on public.submissions;
drop policy if exists "Read own audit or staff reads all" on public.audit_logs;
drop policy if exists "Staff read audit history" on public.audit_logs;
create policy "Staff read audit history" on public.audit_logs
for select to authenticated using ((select public.is_staff()));

create or replace function public.save_scholarship_program(
 p_program_id uuid,p_name text,p_max_gwa numeric,p_min_units integer,
 p_max_failed integer,p_max_incomplete integer,p_max_dropped integer,p_deadline timestamptz
) returns uuid language plpgsql security definer set search_path = ''
as $$
declare saved_id uuid;
begin
 perform public.require_staff();
 if length(trim(coalesce(p_name,'')))=0 then raise exception 'Program name is required'; end if;
 if p_program_id is null then
  insert into public.scholarship_programs(name,max_gwa,min_units,max_failed,max_incomplete,max_dropped,deadline)
  values(trim(p_name),p_max_gwa,p_min_units,p_max_failed,p_max_incomplete,p_max_dropped,p_deadline)
  returning id into saved_id;
 else
  update public.scholarship_programs set name=trim(p_name),max_gwa=p_max_gwa,min_units=p_min_units,
   max_failed=p_max_failed,max_incomplete=p_max_incomplete,max_dropped=p_max_dropped,deadline=p_deadline
  where id=p_program_id returning id into saved_id;
  if not found then raise exception 'Program not found'; end if;
 end if;
 return saved_id;
end;
$$;

create or replace function public.update_scholar_profile(p_scholar_id uuid,p_full_name text,p_student_id text)
returns void language plpgsql security definer set search_path = ''
as $$
begin
 perform public.require_staff();
 if length(trim(coalesce(p_full_name,'')))=0 or length(trim(coalesce(p_student_id,'')))=0 then
  raise exception 'Name and student ID are required';
 end if;
 update public.profiles set full_name=trim(p_full_name),student_id=trim(p_student_id)
 where id=p_scholar_id and role='scholar';
 if not found then raise exception 'Scholar profile not found'; end if;
end;
$$;

revoke all on function public.save_scholarship_program(uuid,text,numeric,integer,integer,integer,integer,timestamptz) from public;
revoke all on function public.update_scholar_profile(uuid,text,text) from public;
grant execute on function public.save_scholarship_program(uuid,text,numeric,integer,integer,integer,integer,timestamptz) to authenticated;
grant execute on function public.update_scholar_profile(uuid,text,text) to authenticated;
