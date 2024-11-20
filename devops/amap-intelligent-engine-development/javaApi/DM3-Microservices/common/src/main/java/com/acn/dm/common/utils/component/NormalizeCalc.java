package com.acn.dm.common.utils.component;

import java.util.Objects;

public class NormalizeCalc {

    public static int normalizeQuantityInv(Integer qty, Integer videoDuration, Integer normalizationValue) {
        if (Objects.nonNull(videoDuration)) {
            double scale = Math.pow(10, 3);
            return (int) Math.ceil(Math.round((((float) qty * normalizationValue / videoDuration) * scale) / scale));
        }
        return qty;
    }

    public static int normalizeQuantity(Integer qty, Integer videoDuration, Integer normalizationValue) {
        if (Objects.nonNull(videoDuration)) {
            return (int) Math.ceil((float) qty * videoDuration / normalizationValue);
        }
        return qty;
    }
}
