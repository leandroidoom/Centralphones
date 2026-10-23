export function currencyCents(value) {
  if (!Number.isFinite(value) || value < 0) throw new RangeError('Invalid amount');
  return Math.round((value + Number.EPSILON) * 100);
}
export function cartTotal(items) {
  return items.reduce((sum, item) => {
    if (!Number.isInteger(item.qty) || item.qty < 1) throw new RangeError('Invalid quantity');
    return sum + currencyCents(item.price) * item.qty;
  }, 0);
}
export function canSell(cart, products) {
  return cart.every(item => Number.isInteger(item.qty) && item.qty > 0 && products.some(product => product.id === item.id && Number.isInteger(product.quantidade) && product.quantidade >= item.qty));
}
export function cashBalance(sales, movements) {
  const income = sales.reduce((n, s) => n + currencyCents(s.total), 0);
  return movements.reduce((n, m) => n + (m.kind === 'Saída' ? -1 : 1) * currencyCents(m.amount), income);
}
