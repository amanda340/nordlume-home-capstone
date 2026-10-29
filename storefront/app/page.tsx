import Link from "next/link";
import ProductCard from "@/components/ProductCard";
import { getCategories, products } from "@/lib/data";

const FEATURED_SKUS = ["SOF-N001", "TBL-N010", "CHR-N020", "LGT-N030"];

export default function HomePage() {
  const categories = getCategories();
  const featured = FEATURED_SKUS.map((sku) =>
    products.find((p) => p.sku === sku)
  ).filter((p): p is NonNullable<typeof p> => Boolean(p));

  return (
    <div>
      <section className="border-b border-black/10 bg-stone-50">
        <div className="mx-auto max-w-6xl px-6 py-20">
          <p className="text-sm uppercase tracking-widest text-stone-500">
            Nordlume Home
          </p>
          <h1 className="mt-3 max-w-2xl text-4xl font-semibold tracking-tight sm:text-5xl">
            Móveis modulares para viver bem em pouco espaço.
          </h1>
          <p className="mt-4 max-w-xl text-stone-600">
            Peças escandinavas que se reconfiguram, se dobram e se empilham —
            pensadas para apartamentos pequenos, não para salas de showroom.
          </p>
          <Link
            href="/catalog"
            className="mt-8 inline-block rounded-full bg-stone-900 px-6 py-3 text-sm font-medium text-white transition hover:bg-stone-700"
          >
            Explorar catálogo
          </Link>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-6 py-14">
        <h2 className="text-lg font-medium">Categorias</h2>
        <div className="mt-5 flex flex-wrap gap-3">
          {categories.map((category) => (
            <Link
              key={category}
              href={`/catalog?category=${encodeURIComponent(category)}`}
              className="rounded-full border border-black/10 px-4 py-2 text-sm text-stone-700 transition hover:border-black/30"
            >
              {category}
            </Link>
          ))}
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-6 pb-20">
        <h2 className="text-lg font-medium">Destaques</h2>
        <div className="mt-5 grid grid-cols-2 gap-5 sm:grid-cols-4">
          {featured.map((product) => (
            <ProductCard key={product.sku} product={product} />
          ))}
        </div>
      </section>
    </div>
  );
}
