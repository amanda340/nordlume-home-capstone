# Nordlume Mock API

API mock (Node puro, sem dependências) que serve catálogo e status de pedido pro
Home Advisor Agent (Agentforce) via External Service. Ver spec em
`docs/superpowers/specs/2026-10-29-home-advisor-agent-mvp-design.md`.

## Rotas

| Rota | Uso |
|---|---|
| `GET /products?category=&q=` | Busca de produtos (ação `SearchProducts`) |
| `GET /products/:sku` | Detalhe de um produto (ação `GetProductDetails`) |
| `GET /orders/:orderNumber/shipments` | Status/previsão de entrega do pedido (ação `GetOrderStatus`) |
| `GET /health` | Health check |

Autenticação: header `x-api-key`, obrigatório só se a env var `API_KEY` estiver
definida (fica desligado em dev local).

## Rodando local

```bash
npm start            # porta 3001 (ou $PORT)
npm test             # node --test
```

## Deploy (Render free tier)

1. Criar Web Service novo no Render apontando pra este diretório (`mock-api/`).
2. Build command: nenhum (sem dependências). Start command: `npm start`.
3. Definir env var `API_KEY` com um valor forte.
4. Copiar a URL pública e atualizar `servers.url` em `openapi.yaml` e o Named
   Credential da org `capstone`.
