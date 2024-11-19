package com.acn.dm.order.service.impl;

@FunctionalInterface
public interface ThrowingSupplier<T> {
    T get() throws Exception;
}