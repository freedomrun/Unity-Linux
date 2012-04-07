use BS;

drop table if exists job_status_history;
create table job_status_history (
   id mediumint, 
   job_id mediumint, 
   status varchar(20), 
   TS timestamp default now()
);

drop trigger if exists  new_job_history;
delimiter //
create trigger new_job_history after insert on BS.jobs
for each row
begin
   insert into jobs_history (job_id, stage,tag,note, pass, TS) values (new.job_id, new.stage, new.tag, new.note, new.pass, now());
end; //
delimiter ;

drop trigger if exists  up_job_history;
delimiter //
create trigger up_job_history after update on BS.jobs
for each row
begin
   insert into jobs_history (job_id, stage,tag,note, pass, TS) values (old.job_id, new.stage, new.tag, new.note, new.pass, now());
end; //
delimiter ;

