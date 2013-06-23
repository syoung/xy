select p.project_name, f.location, 
(select x.status from status x where x.status_id = f.status_id) as fc_status,
 s.sample_barcode, fs.lane, fc.total_yield, fc.pass_yield  
from project p, flowcell_lane_static fc , flowcell_samplesheet fs, sample s, flowcell f  
where fc.flowcell_id = fs.flowcell_id 
and fc.lane = fs.lane 
and s.sample_id = fs.sample_id 
and f.flowcell_id = fc.flowcell_id 
and p.project_id = s.project_id
order by s.sample_barcode
