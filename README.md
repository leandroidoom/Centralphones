# Centralphones

Gestão de assistência técnica em Next.js, TypeScript e Tailwind.

- `/ordens-servico`: atendimento conectado ao Supabase, fotos privadas, etapas e mensagens de WhatsApp.
- `/acompanhar`: acompanhamento do cliente por link com token.
- `/ordens-servico/local`: registros e recebimentos demonstrativos antigos, preservados no navegador.
- PDV, caixa, estoque e cadastros anteriores ainda funcionam localmente.

Modo claro/Azul Royal inicial, quatro paletas e menu personalizável no módulo conectado.

Veja [o funcionamento e os limites da integração](docs/CLOUD_OS.md).

## Desenvolvimento

`npm install`, `npm test`, `npx tsc --noEmit`, `npm run build`, `npm run dev`.

O workflow do GitHub executa testes, verificação TypeScript e compilação. A conexão pública do Supabase está em `src/lib/cloud-config.ts`; autorização é aplicada no banco por RLS. Nunca coloque chaves secretas no frontend.
