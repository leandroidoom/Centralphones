# Centralphones — roteiro de implementação

## Implementado
- Next.js + TypeScript + Tailwind
- Navegação inicial de 22 módulos
- Temas claro/escuro e quatro paletas no painel
- Rascunhos demonstrativos armazenados no navegador
- Tela dedicada de ordens de serviço em /ordens-servico: cadastro, edição, busca, filtros, atualização de status e exportação CSV

- Recebimentos parciais de OS integrados ao caixa local, com saldo pendente, histórico e validação em centavos. Escritas no caixa sincronizadas entre abas via Web Locks. Cancelamento de OS com recebimentos bloqueado até implementar estornos.

## Próximas entregas
1. Extrair layout e tokens de tema em componentes reutilizáveis; aplicar tema à tela de OS.
2. Modelar Supabase: empresas, filiais, usuários, permissões, clientes, aparelhos, OS, itens, estoque, vendas, caixa e lançamentos.
3. Implementar autenticação, isolamento por empresa via RLS e auditoria.
4. Criar CRUD real de clientes e produtos; validações e máscaras.
5. Conectar OS a clientes, peças, técnicos, orçamento, aprovação e garantia.
6. PDV com transações consistentes, estoque e caixa.
7. Financeiro, relatórios, impressões e testes automatizados.
8. Revisão de acessibilidade, responsividade, segurança e deploy.

## Atenção
O modo demonstrativo usa localStorage e não deve receber dados pessoais reais. Não há sincronização entre aparelhos nem garantia de recuperação dos registros. A interface de referência inspira fluxos; não copiar código ou ativos proprietários.
