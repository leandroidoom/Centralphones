import {currencyCents} from './finance.mjs';

export const cashKey = 'centralphones:cash:v1';
export const paymentMethods = ['Dinheiro', 'PIX', 'Cartão de débito', 'Cartão de crédito', 'Transferência'];

export function receivedCents(orderId, movements) {
  return movements.filter(m => m.orderId === orderId && m.kind === 'Entrada')
    .reduce((sum, m) => sum + currencyCents(m.amount), 0);
}

export function appendServicePayment(order, movements, payment) {
  if (!order || order.status === 'Cancelado') throw new Error('Esta ordem não pode receber pagamentos.');
  if (!payment.id || movements.some(m => m.id === payment.id)) throw new Error('Recebimento já registrado.');
  if (!paymentMethods.includes(payment.method)) throw new Error('Selecione uma forma de pagamento válida.');
  const cents = currencyCents(payment.amount);
  if (cents <= 0 || Math.abs(payment.amount * 100 - cents) > 0.000001) throw new Error('Informe um valor positivo com até duas casas decimais.');
  const remaining = currencyCents(order.valor) - receivedCents(order.id, movements);
  if (cents > remaining) throw new Error('O valor excede o saldo pendente desta ordem.');
  return [{id: payment.id, date: payment.date, kind: 'Entrada', orderId: order.id,
    description: `Recebimento ${order.id} — ${order.cliente}`, amount: cents / 100, method: payment.method}, ...movements];
}

export function readCash(storage) {
  const rows = JSON.parse(storage.getItem(cashKey) || '[]');
  if (!Array.isArray(rows)) throw new Error('Não foi possível ler o caixa. Os dados existentes foram preservados.');
  return rows;
}

// Serialize writers across tabs and read the latest ledger inside the lock.
export async function writeCash(transform) {
  if (!navigator.locks) throw new Error('Use um navegador atualizado para registrar recebimentos com segurança.');
  return navigator.locks.request(cashKey, () => {
    const next = transform(readCash(localStorage));
    localStorage.setItem(cashKey, JSON.stringify(next));
    window.dispatchEvent(new Event('centralphones:cash-updated'));
    return next;
  });
}
