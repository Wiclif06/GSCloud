-- Execute no psql do container PostgreSQL em ACI.
SELECT current_database(), inet_server_addr(), now();
-- Substitua pelos IDs retornados na demonstração; repita após CREATE/READ/UPDATE/DELETE.
SELECT id,name,city,state,total_area,area_unit FROM farms WHERE id=1;
SELECT id,farm_id,name,crop_type,area_size,area_unit FROM crop_areas WHERE id=1;
SELECT id,crop_area_id,name,device_code,sensor_type,status FROM sensors WHERE id=1;
SELECT id,crop_area_id,type,description,quantity,unit FROM field_activities WHERE id=1;
-- Após DELETE o SELECT filtrado deve retornar zero linhas.
