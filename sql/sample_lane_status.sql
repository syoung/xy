select f.flowcell_barcode, 
fs.lane,
(select z.status from status z where z.status_id = f.status_id) as fc_status, 
fs.sample_id , 
p.project_name, 
s.sample_barcode, 
(select z.status from status z where z.status_id = q.status_id) as q_status, 
q.working_dir , 
(select cast(concat(total_yield,'; ',pass_yield ) as char)  
    from flowcell_lane_static st where st.flowcell_id = f.flowcell_id and st.lane = fs.lane) as yield
from flowcell f,
sample s,
project p, 
flowcell_samplesheet fs left join alignment_queue_sample qs 
    on fs.flowcell_samplesheet_id = qs.flowcell_samplesheet_id 
    left join alignment_queue q on qs.alignment_queue_id = q.alignment_queue_id
where f.flowcell_id = fs.flowcell_id
and s.sample_id = fs.sample_id
and f.flowcell_id = fs.flowcell_id
and p.project_id = s.project_id



