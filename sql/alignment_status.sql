
select p.project_name, h.status, count(*) from alignment_queue q, alignment_queue_sample x, status h, project p 
where x.alignment_queue_id = q.alignment_queue_id
and h.status_id = q.status_id 
and p.project_id = q.project_id
group by p.project_name, h.status
