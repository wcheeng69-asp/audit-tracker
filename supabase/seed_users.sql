-- Seed users (already applied). Creates priya (admin), dan and marcus (auditors)
-- with initial password "password". Users are prompted to change it at first sign-in.
do $$
declare u record; nid uuid;
begin
  for u in select * from (values ('priya','Priya','admin'),('dan','Dan','auditor'),('marcus','Marcus','auditor')) v(username,full_name,role) loop
    nid := gen_random_uuid();
    insert into auth.users (instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at,confirmation_token,email_change,email_change_token_new,recovery_token)
    values ('00000000-0000-0000-0000-000000000000',nid,'authenticated','authenticated',u.username||'@audit-tracker.local',
            extensions.crypt('password', extensions.gen_salt('bf')),now(),
            '{"provider":"email","providers":["email"]}'::jsonb,
            jsonb_build_object('username',u.username,'full_name',u.full_name),now(),now(),'','','','');
    insert into auth.identities (id,user_id,provider_id,identity_data,provider,last_sign_in_at,created_at,updated_at)
    values (gen_random_uuid(),nid,nid::text,jsonb_build_object('sub',nid::text,'email',u.username||'@audit-tracker.local','email_verified',true),'email',now(),now(),now());
    update public.profiles set role=u.role where id=nid;
  end loop;
end $$;
