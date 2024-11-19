package com.acn.dm.order.service.impl;

@FunctionalInterface
public interface ThrowingConsumer <T> {
    void accept(T t) throws Exception;
}
