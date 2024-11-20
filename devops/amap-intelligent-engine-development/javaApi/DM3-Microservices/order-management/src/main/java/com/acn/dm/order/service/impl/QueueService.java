package com.acn.dm.order.service.impl;

import com.acn.dm.order.domains.ApiOrderMessageQueue;
import com.acn.dm.order.domains.ApiOrderProcessState;
import com.acn.dm.order.domains.ProcedureStatusResult;
import com.acn.dm.order.domains.pk.ApiOrderProcessStatePK;
import com.acn.dm.order.lov.OrderSyncActions;
import com.acn.dm.order.lov.ProcedureStatus;
import com.acn.dm.order.lov.QueueStatus;
import com.acn.dm.order.repository.ApiOrderMessageQueueRepository;
import com.acn.dm.order.repository.ApiOrderProcessStateRepository;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import jakarta.persistence.EntityManager;
import jakarta.persistence.ParameterMode;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.StoredProcedureQuery;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
public class QueueService {

    @PersistenceContext
    private EntityManager entityManager;

    private ApiOrderMessageQueueRepository apiOrderMessageQueueRepository;
    private ApiOrderProcessStateRepository apiOrderProcessStateRepository;

    public QueueService(ApiOrderMessageQueueRepository apiOrderMessageQueueRepository, ApiOrderProcessStateRepository apiOrderProcessStateRepository) {
        this.apiOrderMessageQueueRepository = apiOrderMessageQueueRepository;
        this.apiOrderProcessStateRepository = apiOrderProcessStateRepository;
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void selectAndSaveOrUpdateMessageQueue(MarketOrderLineDetailsRequest request, String json, QueueStatus queueStatus, OrderSyncActions action, String error) {
        if (Objects.nonNull(request.getQueueId())) {
            apiOrderMessageQueueRepository.findById(request.getQueueId())
                    .ifPresentOrElse(result -> apiOrderMessageQueueRepository.save(updateMessageQueue(result, queueStatus, error))
                            , () -> {
                                ApiOrderMessageQueue order = apiOrderMessageQueueRepository.save(createNewMessageQueue(request, json, queueStatus, action, error));
                                request.setQueueId(order.getId());
                            });
        } else {
            ApiOrderMessageQueue order = apiOrderMessageQueueRepository.save(createNewMessageQueue(request, json, queueStatus, action, error));
            request.setQueueId(order.getId());
        }
    }

    @Transactional
    public ApiOrderMessageQueue selectAndSaveOrUpdateValidationError(String payload, String error, String marketOrderId, String moldId, String currentMoldStatus) {
        ApiOrderMessageQueue build = ApiOrderMessageQueue.builder()
                .message(payload)
                .errorMessage(error)
                .action(OrderSyncActions.NONE.toString())
                .attemptCount(0)
                .maxAttempts(5)
                .status(QueueStatus.VERROR)
                .marketOrderId(marketOrderId)
                .marketOrderDetailId(moldId)
                .marketOrderDetailStatus(currentMoldStatus)
                .build();

        return apiOrderMessageQueueRepository.save(build);
    }

    private ApiOrderMessageQueue updateMessageQueue(ApiOrderMessageQueue apiOrderMessageQueue, QueueStatus queueStatus, String error) {
        apiOrderMessageQueue.setStatus(queueStatus);
        apiOrderMessageQueue.setErrorMessage(error);
        return apiOrderMessageQueue;
    }

    private ApiOrderMessageQueue createNewMessageQueue(MarketOrderLineDetailsRequest request, String json, QueueStatus queueStatus, OrderSyncActions action, String error) {
        return ApiOrderMessageQueue.builder()
                .message(json)
                .action(Objects.isNull(action) ? "NONE" : action.toString())
                .attemptCount(0)
                .maxAttempts(5)
                .status(queueStatus)
                .marketOrderId(request.getMarketOrderId())
                .marketOrderDetailId(request.getMoldId())
                .marketOrderDetailStatus(request.getCurrentMoldStatus())
                .errorMessage(error)
                .build();
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void selectAndSaveOrUpdateProcessState(MarketOrderLineDetailsRequest request, QueueStatus queueStatus) {
        apiOrderProcessStateRepository.findById(new ApiOrderProcessStatePK(request.getMarketOrderId(), request.getMoldId()))
                .ifPresentOrElse(result -> apiOrderProcessStateRepository.save(updateProcessState(result, queueStatus))
                        , () -> apiOrderProcessStateRepository.save(createNewProcessState(request, queueStatus)));
    }

    private ApiOrderProcessState updateProcessState(ApiOrderProcessState apiOrderProcessState, QueueStatus queueStatus) {
        apiOrderProcessState.setStatus(queueStatus);
        return apiOrderProcessState;
    }

    private ApiOrderProcessState createNewProcessState(MarketOrderLineDetailsRequest request, QueueStatus queueStatus) {
        return ApiOrderProcessState.builder()
                .status(queueStatus)
                .apiOrderProcessStatePK(new ApiOrderProcessStatePK(request.getMarketOrderId(), request.getMoldId()))
                .build();
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW, isolation = Isolation.READ_COMMITTED)
    public void updateErrorStatus(MarketOrderLineDetailsRequest line, String error) {
        selectAndSaveOrUpdateProcessState(line, QueueStatus.ERROR);
        selectAndSaveOrUpdateMessageQueue(line, mapToJson(line), QueueStatus.ERROR, OrderSyncActions.NONE, error);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW, isolation = Isolation.READ_COMMITTED)
    public void updateBatchStatus(MarketOrderLineDetailsRequest request) {
        selectAndUpdateProcessState(request, QueueStatus.BATCH_RUNNING);
        selectAndUpdateMessageQueue(request, QueueStatus.BATCH_RUNNING);
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void selectAndUpdateProcessState(MarketOrderLineDetailsRequest request, QueueStatus queueStatus) {
        apiOrderProcessStateRepository.findById(new ApiOrderProcessStatePK(request.getMarketOrderId(), request.getMoldId()))
                .ifPresent(result -> apiOrderProcessStateRepository.save(updateProcessState(result, queueStatus)));
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void selectAndUpdateMessageQueue(MarketOrderLineDetailsRequest request, QueueStatus queueStatus) {
        apiOrderMessageQueueRepository.findById(request.getQueueId())
                .ifPresent(result -> apiOrderMessageQueueRepository.save(updateMessageQueueStatus(result, queueStatus)));
    }

    private ApiOrderMessageQueue updateMessageQueueStatus(ApiOrderMessageQueue apiOrderMessageQueue, QueueStatus queueStatus) {
        apiOrderMessageQueue.setStatus(queueStatus);
        return apiOrderMessageQueue;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW, isolation = Isolation.READ_COMMITTED)
    public void updateLinesErrorStatus(List<MarketOrderLineDetailsRequest> lines, String error) {
        for (MarketOrderLineDetailsRequest line : lines) {
            selectAndSaveOrUpdateProcessState(line, QueueStatus.ERROR);
            selectAndSaveOrUpdateMessageQueue(line, mapToJson(line), QueueStatus.ERROR, OrderSyncActions.NONE, error);
        }
    }

    private String mapToJson(Object object) {
        try {
            ObjectMapper mapper = new ObjectMapper();
            mapper.registerModule(new JavaTimeModule());
            mapper.findAndRegisterModules();
            return mapper.writeValueAsString(object);
        } catch (Exception e) {
            log.error("Error mapping to json", e);
            return object.toString();
        }
    }

    public ProcedureStatusResult getActualStatusToPrecess(String marketOrderId, String marketOrderDetailId, Long messageSeq) {
        StoredProcedureQuery query = entityManager.createStoredProcedureQuery("CheckOrderLineProcess");

        query.registerStoredProcedureParameter("in_market_order_id", String.class, ParameterMode.IN);
        query.registerStoredProcedureParameter("in_marker_order_line_details_id", String.class, ParameterMode.IN);
        query.registerStoredProcedureParameter("in_message_seq_no", Long.class, ParameterMode.IN);

        query.registerStoredProcedureParameter("out_status", String.class, ParameterMode.OUT);
        query.registerStoredProcedureParameter("out_wait_time", Integer.class, ParameterMode.OUT);

        query.setParameter("in_market_order_id", marketOrderId);
        query.setParameter("in_marker_order_line_details_id", marketOrderDetailId);
        query.setParameter("in_message_seq_no", messageSeq);

        query.execute();

        ProcedureStatus status = ProcedureStatus.valueOf((String) query.getOutputParameterValue("out_status"));
        Integer waitTime = (Integer) query.getOutputParameterValue("out_wait_time");

        log.info("In Procedure call [message Seq - {}, status - {}, waitTime - {}]", messageSeq, status, waitTime);

        return new ProcedureStatusResult(status, waitTime);
    }

    public Optional<String> findPreviousMoldStatus(String moldId, String marketOrderId) {
        return apiOrderMessageQueueRepository.findPreviousStatus(moldId, marketOrderId);
    }


}
