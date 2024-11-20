package com.acn.dm.order.utils;

import com.acn.dm.order.domains.ApiOrderMessageQueue;
import com.acn.dm.order.rest.input.MarketOrderLineDetailsRequest;
import com.acn.dm.order.rest.input.OrderSyncRequest;
import com.acn.dm.order.rest.output.ErrorLogResponse;
import com.acn.dm.order.service.impl.QueueService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import java.util.Objects;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang.StringUtils;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

@ControllerAdvice
@EnableWebMvc
@Order(Ordered.HIGHEST_PRECEDENCE)
@Slf4j
public class ErrorHandler {

    private final QueueService queueService;

    public ErrorHandler(QueueService queueService) {
        this.queueService = queueService;
    }

    @ExceptionHandler({MethodArgumentNotValidException.class, HttpMessageNotReadableException.class})
    public ResponseEntity<ErrorLogResponse> handleAllExceptions(Exception ex, WebRequest webRequest) {
        log.error("Exception: ", ex.getMessage());
        String payload = StringUtils.EMPTY;
        String moldId = StringUtils.EMPTY;
        String marketOrderId = StringUtils.EMPTY;
        String currentMoldStatus = StringUtils.EMPTY;
        if (Objects.nonNull(webRequest)) {
            Object request = webRequest.getAttribute("request", RequestAttributes.SCOPE_REQUEST);
            if (request instanceof OrderSyncRequest order) {
                payload = mapToJson(order.getLine());
                marketOrderId = ((OrderSyncRequest) request).getLine().get(0).getMarketOrderId();
                currentMoldStatus = order.getLine().stream().map(MarketOrderLineDetailsRequest::getCurrentMoldStatus)
                        .collect(Collectors.joining("-"));
                moldId = order.getLine().stream().map(MarketOrderLineDetailsRequest::getMoldId)
                        .collect(Collectors.joining("-"));
            }
        }
        ApiOrderMessageQueue errorLog = queueService.selectAndSaveOrUpdateValidationError(payload
                , ex.getMessage()
                , marketOrderId
                , moldId
                , currentMoldStatus);

        ErrorLogResponse errorLogResponse = new ErrorLogResponse(String.valueOf(errorLog.getId()), ex.getMessage(), errorLog.getUpdateDatetime());

        return new ResponseEntity<ErrorLogResponse>(errorLogResponse, HttpStatus.BAD_REQUEST);
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

}
