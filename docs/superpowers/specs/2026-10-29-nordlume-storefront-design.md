# Nordlume Home Storefront — Design

## Contexto

Capstone "Home Furnishing Retailer: Launching an AI-Powered Home Advisor" (caso de uso 1 do guia do programa). Outro grupo já implementou o mesmo caso de uso (repo `home-retailer-demo-org`, marca "Astro Furniture", site Experience Cloud/LWR em sandbox). Nosso grupo implementa o mesmo caso de uso com marca, dados, design e stack próprios — sem reaproveitar conteúdo do outro grupo.

Esta spec cobre **apenas o storefront web** (o lado Agentforce/Salesforce — agente, dados de pedidos, Apex — é outra frente de trabalho, fora deste documento).

## Marca

**Nordlume Home** — móveis modulares e multifuncionais estilo escandinavo, posicionado para "small-space living" (apartamentos pequenos). Diferencial frente ao Astro Furniture (ateliê): foco em modularidade e funcionalidade, não em peças sob encomenda.

## Escopo

**Dentro do escopo (v1):**
- Site Next.js standalone, local (sem deploy por ora)
- Páginas: Home, Catálogo, Produto, Lojas
- Dados mockados de produtos, lojas e inventário (fictícios, gerados para este projeto)
- Slot reservado no layout para o widget do agente (vazio — mecanismo de embed é decisão futura)

**Fora do escopo (v1):**
- Carrinho / checkout — botão "Comprar" é mockado (sem fluxo real)
- Deploy em produção (Vercel/Heroku etc.) — decidir depois
- Integração real com Agentforce/Salesforce — fica para outra spec
- Autenticação de usuário / conta de cliente

## Arquitetura

```
capstone/capstone/
├── force-app/          (Salesforce — já existente, fora do escopo)
└── storefront/         (novo)
    ├── app/
    │   ├── page.tsx                (Home)
    │   ├── catalog/page.tsx        (Catálogo)
    │   ├── product/[sku]/page.tsx  (Produto)
    │   └── stores/page.tsx         (Lojas)
    ├── components/
    │   ├── Header.tsx
    │   ├── Footer.tsx
    │   ├── ProductCard.tsx
    │   ├── StoreCard.tsx
    │   └── AgentSlot.tsx           (placeholder vazio)
    ├── data/
    │   ├── products.json
    │   ├── stores.json
    │   └── inventory.json
    └── public/images/              (placeholders)
```

Stack: Next.js (App Router) + React + Tailwind CSS. Dados lidos diretamente dos JSONs locais (sem backend/API nesta v1 — leitura em build/server component).

## Modelo de dados

- **products.json** (~24 itens, 5 categorias: sofás, mesas, cadeiras, iluminação, armazenamento): `sku`, `name`, `category`, `price`, `dimensions`, `description`, `style`, `image`.
- **stores.json** (4 lojas fictícias): `storeId`, `name`, `address`, `hours`, `phone`.
- **inventory.json**: `sku`, `storeId`, `quantity` — disponibilidade derivada (`IN_STOCK` / `LOW_STOCK` ≤3 / `OUT_OF_STOCK`), mesma lógica de derivação do padrão usado no caso de referência, sem copiar os dados em si.

Imagens: URLs de placeholder (Unsplash, mobiliário genérico), sem atribuição à marca real.

## Páginas / componentes

- **Header**: logo Nordlume + navegação (Home, Catálogo, Lojas).
- **Home**: hero com proposta de valor, categorias em destaque, grid de produtos destacados, CTA pro catálogo.
- **Catálogo**: grid de `ProductCard`, filtros por categoria/estilo/preço, busca por nome.
- **Produto**: imagem, preço, dimensões, descrição, disponibilidade por loja (lê `inventory.json`), produtos relacionados (mesma categoria).
- **Lojas**: lista de `StoreCard` (endereço, horário, contato).
- **AgentSlot**: componente vazio reservado no layout (ex: canto inferior direito), para no futuro receber o widget/chat do Agentforce.

## Testes

Dado o escopo de demo, sem testes automatizados nesta v1. Verificação manual: `npm run dev`, navegar pelas 4 páginas, confirmar que produto → disponibilidade por loja bate com `inventory.json`.
