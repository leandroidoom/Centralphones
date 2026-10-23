# Centralphones — lançamento piloto e licenciamento SaaS

## Ambiente e separação de projetos
O único projeto Vercel oficial é **centralphones**. O repositório é leandroidoom/Centralphones. O Supabase conectado atualmente contém apenas um projeto denominado ELO INGRESSOS; **não reutilizar** esse banco. Criar um projeto Supabase separado chamado Centralphones antes de aplicar qualquer migração.

## Critérios mínimos para uso real na assistência
- [ ] Deploy oficial passa build e smoke test
- [ ] Autenticação com recuperação de senha e permissões
- [ ] Dados persistidos no servidor; isolamento por empresa e unidade via RLS
- [ ] Cadastro real de clientes, aparelhos, produtos, fornecedores e técnicos
- [ ] OS: entrada, diagnóstico, orçamento, autorização, reparo, entrega, histórico e impressão
- [ ] PDV: fechamento transacional e estoque consistente, estorno e auditoria
- [ ] Caixa: abertura, sangria, suprimento, fechamento e reconciliação
- [ ] Relatórios de faturamento, estoque, OS e resultados
- [ ] Backups, exportação, LGPD, monitoramento e testes ponta a ponta
- [ ] Piloto com dados fictícios antes de migração para dados reais

## Modelo comercial posterior
- Empresas (tenants), unidades, usuários e papéis
- Plano, assinatura, limites e situação da cobrança por empresa
- Período de teste, cobrança mensal, inadimplência e reativação
- Admin da plataforma separado dos administradores das lojas
- Sem misturar dados de empresas ou conceder privilégios via metadata editável pelo usuário

## Limites atuais
As telas usam localStorage e servem apenas para demonstração. Não são adequadas para dados reais, uso multi-dispositivo ou venda de licenças.
