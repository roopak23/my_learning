package com.acn.dm.order.service.impl;

import com.acn.dm.order.domains.ProcedureStatusResult;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;
import com.acn.dm.order.rest.input.OrderSyncRequest;
import com.acn.dm.order.rest.output.OrderSyncResponse;
import com.acn.dm.order.service.OrdersService;
import com.acn.dm.order.sync.OrderSyncActionChain;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.retry.support.RetrySynchronizationManager;
import org.springframework.stereotype.Service;


import static com.acn.dm.order.lov.ProcedureStatus.OK;
import static com.acn.dm.order.lov.ProcedureStatus.TIMEOUT;
import static com.acn.dm.order.lov.ProcedureStatus.WAITMESSAGE;
import static com.acn.dm.order.lov.ProcedureStatus.WAITMO;
import static com.acn.dm.order.lov.ProcedureStatus.WAITMOLD;

/**
 * @author Shivani Chaudhary
 */
@Service
@Slf4j
public class OrdersServiceImpl implements OrdersService {

    private final OrderSyncActionChain orderSyncActionChain;
    private final TransactionHandler transactionHandler;
    private final ExecutorConfig executorConfig;
    private final QueueService queueService;


    public OrdersServiceImpl(OrderSyncActionChain orderSyncActionChain, TransactionHandler transactionHandler, ExecutorConfig executorConfig, QueueService queueService) {
        this.orderSyncActionChain = orderSyncActionChain;
        this.transactionHandler = transactionHandler;
        this.executorConfig = executorConfig;
        this.queueService = queueService;
    }

    public List<OrderSyncResponse> process(OrderSyncRequest request) throws Exception {
        List<OrderSyncResponse> orderSyncResponses = null;
        try {
            orderSyncResponses = transactionHandler.runInTransactionWithRetry(() -> validList(request));
        } catch (Exception e) {
            e.printStackTrace();
            queueService.updateLinesErrorStatus(request.getLine(), "VALID -> " + e.getMessage());
            throw e;
        }
        ExecutorService executorService = executorConfig.getExecutor();
        executorService.submit(() -> syncList(request));
        return orderSyncResponses;
    }

    @Override
    public List<OrderSyncResponse> validList(OrderSyncRequest request) throws Exception {
        List<OrderSyncResponse> result = new ArrayList<>();
        for (MarketOrderLineDetailsRequest item : request.getLine()) {
            result.add(transactionHandler.runInException(() -> valid(item)));
        }
        return result;
    }

    @Override
    public OrderSyncResponse valid(MarketOrderLineDetailsRequest request) throws Exception {
        if (RetrySynchronizationManager.getContext().getRetryCount() > 0) {
            log.warn(String.format("operation -> %s, mold ID - > %s, ", "VALID", request.getMoldId()) + RetrySynchronizationManager.getContext().toString());
        }
        Set<String> actions = orderSyncActionChain.validProcess(request);
        return OrderSyncResponse.builder().moldId(request.getMoldId()).managedBy(actions).build();
    }

    @Override
    public void syncList(OrderSyncRequest request) {
        for (MarketOrderLineDetailsRequest line : request.getLine()) {
            try {
                executeSync(line);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private void executeSync(MarketOrderLineDetailsRequest line) throws Exception {
        try {
            ProcedureStatusResult actualStatusToPrecess
                    = queueService.getActualStatusToPrecess(line.getMarketOrderId(), line.getMoldId(), line.getQueueId());
            switch (actualStatusToPrecess.getProcedureStatus()) {
                case OK:
                    log.info("Procedure message Seq - {}, status - {}, moldId - {}, marketOrderId - {}", line.getQueueId(), OK, line.getMoldId(), line.getMarketOrderId());
                    transactionHandler.runInNewTransactionWithRetry(this::sync, line);
                    break;
                case TIMEOUT:
                    log.info("Procedure message Seq - {}, status - {}, waitTime - {}, moldId - {}, marketOrderId - {}",
                            line.getQueueId(), TIMEOUT, actualStatusToPrecess.getWaitTime(), line.getMoldId(), line.getMarketOrderId());
                    throw new Exception(String.format("Procedure Timeout, moldId - %s", line.getMoldId()));
                case WAITMESSAGE:
                    log.info("Procedure message Seq - {}, status - {}, waitTime - {}, moldId - {}, marketOrderId - {}",
                            line.getQueueId(), WAITMESSAGE, actualStatusToPrecess.getWaitTime(), line.getMoldId(), line.getMarketOrderId());
                    Thread.sleep(actualStatusToPrecess.getWaitTime());
                    executeSync(line);
                    break;
                case WAITMO:
                    log.info("Procedure message Seq - {}, status - {}, waitTime - {}, moldId - {}, marketOrderId - {}",
                            line.getQueueId(), WAITMO, actualStatusToPrecess.getWaitTime(), line.getMoldId(), line.getMarketOrderId());
                    Thread.sleep(actualStatusToPrecess.getWaitTime());
                    executeSync(line);
                    break;
                case WAITMOLD:
                    log.info("Procedure message Seq - {}, status - {}, waitTime - {}, moldId - {}, marketOrderId - {}",
                            line.getQueueId(), WAITMOLD, actualStatusToPrecess.getWaitTime(), line.getMoldId(), line.getMarketOrderId());
                    Thread.sleep(actualStatusToPrecess.getWaitTime());
                    executeSync(line);
                    break;
                case BATCH_RUNNING:
                    queueService.updateBatchStatus(line);
                    break;
                default:
                    log.info("Procedure, not match the data, message Seq - {}, moldId - {}, marketOrderId - {}", line.getQueueId(), line.getMoldId(), line.getMarketOrderId());
                    throw new Exception("Procedure, data does not match the operation");
            }
        } catch (Exception e) {
            queueService.updateErrorStatus(line, "SYNC -> " + e.getMessage());
            throw e;
        }
    }

    @Override
    public void sync(MarketOrderLineDetailsRequest request) throws Exception {
        if (RetrySynchronizationManager.getContext().getRetryCount() > 0) {
            log.warn(String.format("operation -> %s, mold ID - > %s, ", "SYNC", request.getMoldId()) + RetrySynchronizationManager.getContext().toString());
        }
        orderSyncActionChain.process(request);
    }


}
