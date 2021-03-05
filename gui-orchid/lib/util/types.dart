
T tryCast<T>(dynamic x, {T orElse}){
  try {
    return (x as T);
  } on TypeError catch(_) {
    return orElse;
  }
}