CREATE TABLE IF NOT EXISTS `ML_InvForecastingModelKPI` (
    `date` DATE,
    `sku` STRING,
    `model_name` STRING,
    `error_message` STRING,
    `hyperparameters` STRING,
    `kpi` STRING,
    `kpi_value` DOUBLE
) PARTITIONED BY (partition_date INT) STORED AS ORC LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/ML_InvForecastingModelKPI' TBLPROPERTIES("transactional" = "true");
msck repair table `ML_InvForecastingModelKPI`;