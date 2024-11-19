INSERT INTO data_activation.inventory_override_levels_lookup
(level1,level2,level3,level4,level5)
SELECT DISTINCT level1,Level2 ,Level3 ,Level4 ,Level5 
FROM 
STG_SA_Ad_Slot TB WHERE 
CONCAT(COALESCE(TB.level1,''),COALESCE(TB.level2,''),COALESCE(TB.level3,''),COALESCE(TB.level4,''),COALESCE(TB.level5,''))
NOT IN ( SELECT CONCAT(COALESCE(TGT.level1,''),COALESCE(TGT.level2,''),COALESCE(TGT.level3,''),COALESCE(TGT.level4,''),COALESCE(TGT.level5,''))
FROM inventory_override_levels_lookup TGT)