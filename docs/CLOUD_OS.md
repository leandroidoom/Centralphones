# Atendimento conectado

`/ordens-servico` usa Supabase Auth, banco com isolamento por empresa e fotos privadas. Primeiro acesso: criar conta, confirmar e-mail, entrar e informar o nome da empresa. O cadastro de empresa cria apenas a associação do próprio usuário como proprietário. Não existe escolha de empresa de terceiros.

## Fluxo entregue
- Cadastro transacional de cliente, aparelho e OS; checklist e acessórios.
- Etapas validadas no banco, com histórico automático na abertura e nas mudanças.
- Diagnóstico interno, serviço executado, orçamento e técnico informado na entrada.
- Fotos JPG/PNG/WebP até 5 MB em bucket privado; links internos de 15 minutos.
- Mensagens editáveis por etapa; botão abre WhatsApp com destinatário e texto. Envio é confirmado pelo operador no WhatsApp, sem automação de mensagens.
- Acompanhamento `/acompanhar#TOKEN`: modelo, situação e datas. Sem nome/telefone, IMEI, orçamento, diagnóstico ou fotos. Token aleatório de 64 caracteres, prazo de 180 dias, desativação e renovação. O token fica no fragmento da URL, sem aparecer no pedido HTTP da página; enviado ao RPC via POST.
- Menu renomeável, quatro paletas, tema claro/escuro e botão flutuante de nova OS no módulo conectado.

## Continuidade e limites
OS antigas permanecem em `/ordens-servico/local`, com pagamentos parciais no caixa local. Não há migração automática de clientes/OS locais para a nuvem. PDV, caixa, estoque e cadastros anteriores continuam locais. Recebimentos das novas OS entram em `/caixa/nuvem`, com controle em centavos no banco, idempotência e quitação obrigatória para entrega. O botão Receber saldo e entregar realiza ambas as operações na mesma transação. Estorno ainda não está disponível; OS com recebimento não pode ser cancelada. A listagem inicial mostra as 500 ordens mais recentes. As fotos exibidas são as 100 mais recentes por OS. A sessão é por aba (sessionStorage) com renovação de token.

A consulta ao DistribuiPro foi bloqueada pela rede no ambiente de execução. Esta entrega implementa os requisitos explícitos e não declara paridade completa com todos os módulos do concorrente.

## Validação
`npm test` testa cálculos, recebimentos locais, telefone, mensagens e token de acompanhamento. `tests/cloud-orders.sql` executa fixtures transacionais e ROLLBACK, testando eventos, transições, isolamento entre empresas, consulta por token, desativação e privilégios anônimos. Não usar fixtures persistentes em produção. `docs/database/cloud-orders.sql` documenta o SQL aplicado pela migração remota `cloud_orders_tracking_photos`.

## Operação
Somente a chave publishable é incluída no cliente. Não adicionar service_role ao frontend. O serviço padrão de e-mail do Supabase pode limitar destinatários e volume; produção requer SMTP configurado. Nenhum provedor de WhatsApp automático foi configurado. O acesso inicial e upload via navegador precisam de validação com a conta do proprietário.

## Atendimento rápido
Abertura com quatro campos essenciais (cliente, WhatsApp, aparelho e defeito); demais detalhes recolhidos. Filtros Balcão, Bancada e Retirada reduzem navegação. A aba Pagamento permite receber parcialmente ou quitar e entregar em uma ação. O banco restringe recebimentos a owner/admin/attendant.
