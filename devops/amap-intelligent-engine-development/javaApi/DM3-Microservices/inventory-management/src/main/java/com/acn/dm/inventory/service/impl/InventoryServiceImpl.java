package com.acn.dm.inventory.service.impl;

import com.acn.dm.common.lov.Constants;
import com.acn.dm.common.lov.InventoryCheckStatus;
import com.acn.dm.inventory.projection.CheckProjectionDTO;
import com.acn.dm.inventory.projection.InquirityProjectionDTO;
import com.acn.dm.inventory.repository.ApiEventRepository;
import com.acn.dm.inventory.repository.ApiInventoryCheckRepository;
import com.acn.dm.inventory.repository.ApiMoldDataRepository;
import com.acn.dm.inventory.repository.StgAdserverAudienceFactoringRepository;
import com.acn.dm.inventory.rest.input.InventoryInquirityRequest;
import com.acn.dm.inventory.rest.input.MarketOrderLineDetails;
import com.acn.dm.inventory.rest.output.InventoryCheckResponse;
import com.acn.dm.inventory.rest.output.InventoryInquirityResponse;
import com.acn.dm.inventory.service.InventoryService;
import com.acn.dm.inventory.utils.InventoryInquirityFilterBuilder;
import com.acn.dm.inventory.utils.Utils;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;


import static com.acn.dm.common.utils.component.NormalizeCalc.normalizeQuantityInv;
import static com.acn.dm.inventory.utils.InventoryCheckFilterBuilder.buildAndExecCheckQuery;


/**
 * @author Shivani Chaudhary
 */
@Slf4j
@Service
public class InventoryServiceImpl implements InventoryService {

    @PersistenceContext
    private EntityManager em;
    @Autowired
    private ApiInventoryCheckRepository apiInventoryCheckRepository;
    private ApiEventRepository apiEventRepository;

    private StgAdserverAudienceFactoringRepository audienceFactoringRepository;
    private ApiMoldDataRepository apiMoldDataRepository;
    @Value("${application.normalization.qty.value:null}")
    private Integer normalizationQtyValue;

    public InventoryServiceImpl(ApiInventoryCheckRepository apiInventoryCheckRepository
            , ApiEventRepository apiEventRepository, ApiMoldDataRepository apiMoldDataRepository) {
        this.apiInventoryCheckRepository = apiInventoryCheckRepository;
        this.apiEventRepository = apiEventRepository;
        this.apiMoldDataRepository= apiMoldDataRepository;
    }


    @Override
    public InventoryCheckResponse check(@NotNull(message = "Invalid request") @Valid MarketOrderLineDetails request) {
        InventoryCheckResponse body;
        List<CheckProjectionDTO> result = buildAndExecCheckQuery(request, apiInventoryCheckRepository, apiEventRepository);

        if (Utils.isEmptyOrNull(result)) {
            body = InventoryCheckResponse.builder()
                    .moldId(request.getMoldId())
                    .metric(request.getMetric())
                    .quantityAvailable(Constants.ZERO.getType()).quantityReserved(Constants.ZERO.getType())
                    .quantityBooked(Constants.ZERO.getType())
                    .capacity(Constants.NA.getType())
                    .check(InventoryCheckStatus.KO.toString())
                    .message(InventoryCheckStatus.NOT_FOUND.getStatus()).build();
        } else {
            log.info("Retrieved available before normalization: {}", result.get(0).getAvailable());
            CheckProjectionDTO checkProjectionDTO = result.get(0);
            int capacity = normalizeQuantityInv(Math.toIntExact(checkProjectionDTO.getCapacity()), request.getVideoDuration(), normalizationQtyValue);
            int reserved = normalizeQuantityInv(Math.toIntExact(checkProjectionDTO.getReserved()), request.getVideoDuration(), normalizationQtyValue);
            int booked = normalizeQuantityInv(Math.toIntExact(checkProjectionDTO.getBooked()), request.getVideoDuration(), normalizationQtyValue);
            int available = normalizeQuantityInv(Math.toIntExact(checkProjectionDTO.getAvailable()), request.getVideoDuration(), normalizationQtyValue);
            log.info("Retrieved available after normalization: {}", available);

            body = InventoryCheckResponse.builder()
                    .moldId(request.getMoldId())
                    .metric(request.getMetric())
                    .quantityAvailable(String.valueOf(Math.max(0, available)))
                    .quantityReserved(String.valueOf(Math.max(0, reserved)))
                    .quantityBooked(String.valueOf(Math.max(0, booked)))
                    .capacity(String.valueOf(Math.max(0, capacity)))
                    .check(available >= request.getQuantity() ? InventoryCheckStatus.OK.getStatus()
                            : InventoryCheckStatus.KO.getStatus())
                    .message(generateCheckMessage(request.getQuantity(), result.get(0), available)).build();
        }
        return body;
    }

    private String generateCheckMessage(int normalizeQty, CheckProjectionDTO result, int available) {
        if(available >= normalizeQty) {
            return Objects.isNull(result.getClash()) ? InventoryCheckStatus.AVAILABLE.getStatus()
                    : InventoryCheckStatus.AVAILABLE.getStatus() + InventoryCheckStatus.CLASH.getStatus();
        } else {
            return Objects.isNull(result.getClash()) ? InventoryCheckStatus.UNAVAILABLE.getStatus()
                    : InventoryCheckStatus.UNAVAILABLE.getStatus() + InventoryCheckStatus.CLASH.getStatus();
        }
    }

    @Override
    public List<InventoryInquirityResponse> inquirity(@NotNull(message = "Invalid request") @Valid InventoryInquirityRequest request) {

        List<InventoryInquirityResponse> response = new ArrayList<>();
        List<String> metric = request.getMetric();
        List<InquirityProjectionDTO> queryResult = InventoryInquirityFilterBuilder.buildAndExecInquirityQuery(request, apiInventoryCheckRepository, apiEventRepository);
        if (queryResult.isEmpty()) {
            response.addAll(metric.stream().map(this::buildInquirityNA).toList());
            return response;
        }
        return metric.stream().map(m -> buildInquiryResponse(m, queryResult)).toList();

    }

    private InventoryInquirityResponse buildInquiryResponse(String metric, List<InquirityProjectionDTO> projections) {
        return projections.stream()
                .filter(a -> metric.equalsIgnoreCase(a.getMetric()))
                .findFirst()
                .map(inquirityProjection -> buildInquiryFoundResponse(metric, inquirityProjection))
                .orElseGet(() -> buildInquirityNA(metric));
    }

    private InventoryInquirityResponse buildInquirityNA(String metric) {
        return new InventoryInquirityResponse(metric,
                Constants.NA.getType(),
                Constants.ZERO.getType(),
                Constants.ZERO.getType(),
                Constants.ZERO.getType(),
                Constants.NA.getType(),
                Constants.NA.getType());
    }

    private InventoryInquirityResponse buildInquiryFoundResponse(String metric, InquirityProjectionDTO result) {
        return new InventoryInquirityResponse(metric,
                String.valueOf(Math.max(0, result.getCapacity())),
                String.valueOf(Math.max(0, result.getAvailable())),
                String.valueOf(Math.max(0, result.getReserved())),
                String.valueOf(Math.max(0, result.getBooked())),
                Constants.NA.getType(),
                Constants.NA.getType());
    }

}
