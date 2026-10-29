import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import ProductCard from "@/components/ProductCard";
import {
  getAvailabilityForProduct,
  getProduct,
  getRelatedProducts,
  products,
} from "@/lib/data";

export function generateStaticParams() {
  return products.map((p) => ({ sku: p.sku }));
}

const STATUS_LABEL: Record<string, string> = {
  IN_STOCK: "Em estoque",
  LOW_STOCK: "Estoque baixo",
  OUT_OF_STOCK: "Esgotado",
};

const STATUS_CLASS: Record<string, string> = {
  IN_STOCK: "text-green-700",
  LOW_STOCK: "text-amber-700",
  OUT_OF_STOCK: "text-stone-400",
};

export default async function ProductPage(props: PageProps<"/product/[sku]">) {
  const { sku } = await props.params;
  const product = getProduct(sku);

  if (!product) notFound();

  const availability = getAvailabilityForProduct(sku);
  const related = getRelatedProducts(product);

  return (
    <div className="mx-auto max-w-6xl px-6 py-12">
      <Link href="/catalog" className="text-sm text-stone-500 hover:underline">
        ← Voltar ao catálogo
      </Link>

      <div className="mt-6 grid gap-10 md:grid-cols-2">
        <div className="relative aspect-square overflow-hidden rounded-lg bg-stone-100">
          <Image
            src={product.image}
            alt={product.name}
            fill
            sizes="(min-width: 768px) 50vw, 100vw"
            className="object-cover"
          />
        </div>

        <div>
          <p className="text-xs uppercase tracking-wide text-stone-500">
            {product.category} · {product.style}
          </p>
          <h1 className="mt-2 text-3xl font-semibold">{product.name}</h1>
          <p className="mt-3 text-2xl">${product.price}</p>
          <p className="mt-5 text-stone-700">{product.description}</p>
          <p className="mt-4 text-sm text-stone-500">
            Dimensões: {product.dimensions}
          </p>

          <button
            type="button"
            disabled
            className="mt-8 w-full rounded-full bg-stone-900 px-6 py-3 text-sm font-medium text-white opacity-60"
          >
            Comprar (demo — sem checkout)
          </button>

          <div className="mt-10">
            <h2 className="text-sm font-medium">Disponibilidade por loja</h2>
            <ul className="mt-3 divide-y divide-black/10 text-sm">
              {availability.map(({ store, status }) => (
                <li
                  key={store.storeId}
                  className="flex items-center justify-between py-2"
                >
                  <span>{store.name}</span>
                  <span className={STATUS_CLASS[status]}>
                    {STATUS_LABEL[status]}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>

      {related.length > 0 && (
        <div className="mt-16">
          <h2 className="text-lg font-medium">Também pode gostar</h2>
          <div className="mt-5 grid grid-cols-2 gap-5 sm:grid-cols-4">
            {related.map((p) => (
              <ProductCard key={p.sku} product={p} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
