# Home Advisor Agent — MVP (Product Inquiry + Order Status)

## Contexto

Mesmo capstone (caso de uso 1: Home Furnishing Retailer). Esta spec cobre o **lado Salesforce/Agentforce** da Nordlume Home, cuja primeira fatia de valor replica o "Short-term Build & Deployment Plan" do brief oficial: consultas de produto + status de pedido, integrado com uma API de catálogo externa, para a org sandbox `capstone`.

O repositório de referência do outro grupo (`home-retailer-demo-org`) implementa o mesmo caso de uso com uma arquitetura madura (verificação de identidade em 2 fatores com OTP por e-mail, lockout, timeline de rastreio por evento). Usamos a arquitetura geral como referência de padrão (Apex invocável, External Service, status derivado nunca armazenado), mas com lógica, nomes de campo e dados próprios, e escopo deliberadamente mais simples.

## Escopo

**Dentro do escopo (v1):**
- Agente com 2 topics: Product Inquiry, Order Status
- Ações: `GetProductDetails`, `SearchProducts` (External Service → mock-api), `VerifyIdentity`, `GetOrderStatus` (Apex)
- Verificação de identidade simples: nº do pedido + e-mail do Contact (sem segundo fator)
- Mock API Node própria (`mock-api/`), hospedada no Render free tier
- Dados seed: Contacts, Orders, OrderItems, Product2 na org `capstone`
- Deploy do `force-app` pra org `capstone`

**Fora do escopo (v1 — roadmap de longo prazo):**
- OTP por e-mail / lockout de tentativas
- Timeline de eventos de rastreio por envio
- Product Advice, Store Info, Escalation (topics futuros)
- `CompareProducts` / `SuggestComplementaryProducts`

## Modelo de dados Salesforce

- **Product2**: produtos do catálogo Nordlume espelhados aqui (nome, preço), com campo customizado `SKU__c` (texto, casa com `products.json`). Usado só para popular `OrderItem.Product2Id`; a verdade de preço/estoque/detalhe vive no mock-api.
- **Contact**: clientes fictícios Nordlume (Nome, Email).
- **Order** (padrão) + **OrderItem** (padrão): um Order por pedido, `OrderNumber` nativo (ex: `NH-1001`), `BillToContactId` apontando pro Contact, `EffectiveDate`, `TotalAmount`. OrderItems linkados a Product2 via SKU.
- Nenhum campo customizado espelhando o nativo (ex: sem `Order_Number__c` — usa `OrderNumber` padrão).

## Mock API (`mock-api/`)

Node/Express simples, dados próprios (reaproveita o catálogo de `storefront/data`, adiciona `shipments.json` fictício).

| Rota | Uso |
|---|---|
| `GET /products` | `SearchProducts` (filtro por `category`, `q`) |
| `GET /products/:sku` | `GetProductDetails` |
| `GET /orders/:orderNumber/shipments` | `GetOrderStatus` (status + previsão de entrega por item) |

Shipment: `{ orderNumber, status, estimatedDeliveryDate, skus[] }`. Status possíveis: `PROCESSING`, `SHIPPED`, `DELIVERED`, `BACKORDERED`. Sem lista de eventos.

Hospedagem: Render free tier (cold start aceitável pra demo). Autenticação simples via header `x-api-key`, igual ao padrão do External Credential/Named Credential do Salesforce.

## Apex

- **VerifyIdentity** (`@InvocableMethod`): recebe `orderNumber` + `email`; consulta `Order` com `BillToContact.Email` e `OrderNumber` iguais, `WITH USER_MODE`. Retorna `verifiedContactId` só em caso de match (mesma resposta neutra pra "não encontrado" e "pedido de outro cliente", pra não vazar existência).
- **GetOrderStatus** (`@InvocableMethod`): recebe `verifiedContactId` (nunca da conversa) + `orderNumber` opcional. Sem `orderNumber`, lista os pedidos recentes do contato. Com ele, retorna itens + chama o mock-api pra status/previsão de entrega. Status do pedido derivado da lista de status dos itens (mesma regra de prioridade da referência: cancelado só se todos cancelados, entregue só se todos entregues, etc.), nunca armazenado.

## Integração externa

External Credential (`Nordlume_Catalog_API`, custom auth, `apiKey`) → Named Credential → External Service Registration a partir de um `openapi.yaml` próprio em `mock-api/openapi.yaml`, apontando pra URL do Render.

## Permission Set

Um `Nordlume_Agent_Access` dando ao usuário do agente: Read em Product2/Contact/Order/OrderItem, Apex class access às duas classes, e acesso ao External Service.

## Deploy

1. `sf project deploy start --target-org capstone` (metadata)
2. Script de seed (Apex anônimo ou `sf data import`) pra Contacts/Orders/OrderItems/Product2
3. Mock API deployado no Render antes do passo 1, pra Named Credential já ter a URL certa

## Testes

Sem suíte automatizada de testes do agente nesta v1 (fica pro roadmap — Agentforce Studio). Verificação manual: `sf agent preview` com 2-3 perguntas por topic (produto existente, produto inexistente, pedido verificado, pedido de outro cliente).
