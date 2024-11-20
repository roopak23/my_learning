package com.acn.dm.inventory.domains;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.Immutable;

@Data
@Entity
@Immutable
@NoArgsConstructor
@AllArgsConstructor
@Table(name = ApiInventoryCheck.TABLE_NAME)
public class AudienceFactoring {

    public static final String TABLE_NAME = "stg_adserver_audiencefactoring";

    @Id
    private Long id;

    @Column(name = "platform_name")
    private String platformName;

    @Column(name = "dimension_level")
    private String dimensionLevel;

    @Column(name = "dimension")
    private String state;

    @Column(name = "audience_name")
    private String audienceName;

    @Column(name = "% audience")
    private Double audiencePercent;

}
