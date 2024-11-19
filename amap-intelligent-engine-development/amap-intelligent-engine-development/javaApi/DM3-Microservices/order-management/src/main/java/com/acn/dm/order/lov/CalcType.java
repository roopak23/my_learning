package com.acn.dm.order.lov;

public enum CalcType {
  LINEAR ("Linear"),
  WEIGHT( "Weight"),
  CLASH ("Clash");


  CalcType(String text) {
    value = text;
  }
  private final String value;

  public String getValue() {
    return value;
  }
}
