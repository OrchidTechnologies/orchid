
T tryCast<T>(dynamic x, {required T orElse}){
  try {
    return (x as T);
  } on TypeError catch(_) {
    return orElse;
  }
}