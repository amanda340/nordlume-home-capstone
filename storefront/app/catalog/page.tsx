import { Suspense } from "react";
import Link from "next/link";
import ProductCard from "@/components/ProductCard";
import { getCategories, products } from "@/lib/data";

function FilterBar({ activeCategory }: { activeCategory?: string }) {
  const categories = getCategories();
  return (
    <div className="flex flex-wrap gap-3">
      <Link
        href="/catalog"
        className={`rounded-full border px-4 py-2 text-sm transition ${
          !activeCategory
            ? "border-stone-900 bg-stone-900 text-white"
            : "border-black/10 text-stone-700 hover:border-black/30"
        }`}
      >
        Todas
      </Link>
      {categories.map((category) => (
        <Link
          key={category}
          href={`/catalog?category=${encodeURIComponent(category)}`}
          className={`rounded-full border px-4 py-2 text-sm transition ${
            activeCategory === category
              ? "border-stone-900 bg-stone-900 text-white"
              : "border-black/10 text-stone-700 hover:border-black/30"
          }`}
        >
          {category}
        </Link>
      ))}
    </div>
  );
}

async function CatalogResults({
  searchParams,
}: Pick<PageProps<"/catalog">, "searchParams">) {
  const params = await searchParams;
  const category =
    typeof params.category === "string" ? params.category : undefined;
  const q = typeof params.q === "string" ? params.q.toLowerCase() : undefined;

  const filtered = products.filter((p) => {
    if (category && p.category !== category) return false;
    if (q && !p.name.toLowerCase().includes(q)) return false;
    return true;
  });

  return (
    <>
      <FilterBar activeCategory={category} />
      {filtered.length === 0 ? (
        <p className="mt-10 text-stone-500">Nenhum produto encontrado.</p>
      ) : (
        <div className="mt-8 grid grid-cols-2 gap-5 sm:grid-cols-3 lg:grid-cols-4">
          {filtered.map((product) => (
            <ProductCard key={product.sku} product={product} />
          ))}
        </div>
      )}
    </>
  );
}

export default function CatalogPage(props: PageProps<"/catalog">) {
  return (
    <div className="mx-auto max-w-6xl px-6 py-12">
      <h1 className="text-2xl font-semibold">Catálogo</h1>
      <form action="/catalog" className="mt-5 max-w-sm">
        <input
          type="search"
          name="q"
          placeholder="Buscar por nome..."
          className="w-full rounded-full border border-black/10 px-4 py-2 text-sm outline-none focus:border-black/30"
        />
      </form>
      <div className="mt-8">
        <Suspense fallback={<FilterBar />}>
          <CatalogResults searchParams={props.searchParams} />
        </Suspense>
      </div>
    </div>
  );
}
