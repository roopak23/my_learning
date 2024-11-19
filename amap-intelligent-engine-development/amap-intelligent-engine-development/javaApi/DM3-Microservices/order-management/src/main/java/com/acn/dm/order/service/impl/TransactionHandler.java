package com.acn.dm.order.service.impl;

import jakarta.persistence.OptimisticLockException;
import jakarta.persistence.PersistenceException;
import jakarta.persistence.PessimisticLockException;
import java.io.IOException;
import java.sql.SQLException;
import org.hibernate.exception.JDBCConnectionException;
import org.springframework.dao.CannotAcquireLockException;
import org.springframework.dao.DeadlockLoserDataAccessException;
import org.springframework.dao.PessimisticLockingFailureException;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Retryable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TransactionHandler {

    @Retryable(retryFor = {OptimisticLockException.class, PessimisticLockException.class
            , DeadlockLoserDataAccessException.class, CannotAcquireLockException.class
            , PessimisticLockingFailureException.class, PersistenceException.class, JDBCConnectionException.class}
            , maxAttempts = 11
            , backoff = @Backoff(delay = 100))
    @Transactional(propagation = Propagation.REQUIRED, rollbackFor = {SQLException.class, IOException.class}, isolation = Isolation.READ_COMMITTED)
    public <T> T runInTransactionWithRetry(ThrowingSupplier<T> supplier) throws Exception {
        return supplier.get();
    }

    @Transactional(propagation = Propagation.REQUIRED, isolation = Isolation.READ_COMMITTED)
    public <T> T runInTransaction(ThrowingSupplier<T> supplier) throws Exception {
        return supplier.get();
    }

    @Retryable(retryFor = {OptimisticLockException.class, PessimisticLockException.class
            , DeadlockLoserDataAccessException.class, CannotAcquireLockException.class
            , PessimisticLockingFailureException.class, PersistenceException.class, JDBCConnectionException.class}
            , maxAttempts = 12
            , backoff = @Backoff(delay = 3000))
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = {SQLException.class, IOException.class}, isolation = Isolation.READ_COMMITTED)
    public <T> void runInNewTransactionWithRetry(ThrowingConsumer<T> consumer, T t) throws Exception {
        consumer.accept(t);
    }

    public <T> T runInException(ThrowingSupplier<T> supplier) throws Exception {
        return supplier.get();
    }
}
