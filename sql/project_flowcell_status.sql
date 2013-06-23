select p.project_name, h.status, count(s.flowcell_samplesheet_id) as clanes
from flowcell_samplesheet s, flowcell f , sample z, project p, status h
where s.flowcell_id = f.flowcell_id
and z.sample_id =  s.sample_id 
and z.project_id = p.project_id
and f.status_id = h.status_id
and h.status != 'skip_align'
group by p.project_name, h.status
