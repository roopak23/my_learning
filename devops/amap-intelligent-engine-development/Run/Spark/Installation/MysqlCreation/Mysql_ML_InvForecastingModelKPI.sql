CREATE TABLE IF NOT EXISTS `ML_InvForecastingModelKPI` (
`date` DATE,
`sku` varchar(255),
`model_name` varchar(255),
`error_message` varchar(255),
`hyperparameters` varchar(255),
`kpi` varchar(255),
`kpi_value` DOUBLE,
primary key(date,sku));
