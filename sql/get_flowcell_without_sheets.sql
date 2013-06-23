select f.flowcell_barcode, f.location,f.update_timestamp, f.status_id 
from flowcell f left join flowcell_samplesheet s on f.flowcell_id = s.flowcell_id 
where f.status_id in (1,2) and f.run_length like  '101%' 
and s.flowcell_id is null


