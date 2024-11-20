-- data_activation.adslot_hierarchy definition

CREATE TABLE IF NOT EXISTS  `api_mold_history` (
    `mold_id` varchar(255) NOT NULL,
    `status` varchar(255) NOT NULL,
    `quantity` int(11) Default 0,
    `quantity_reserved` int(11) Default 0,
    `quantity_booked` int(11) Default 0,
    `book_ind` varchar(1) Default 'N',
    PRIMARY KEY (`mold_id`) 
)
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
