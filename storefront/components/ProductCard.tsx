import Image from "next/image";
import Link from "next/link";
import type { Product } from "@/lib/data";

export default function ProductCard({ product }: { product: Product }) {
  return (
    <Link
      href={`/product/${product.sku}`}
      className="group block overflow-hidden rounded-lg border border-black/10 bg-white transition hover:shadow-md"
    >
      <div className="relative aspect-square w-full overflow-hidden bg-stone-100">
        <Image
          src={product.image}
          alt={product.name}
          fill
          sizes="(min-width: 1024px) 25vw, 50vw"
          className="object-cover transition group-hover:scale-105"
        />
      </div>
      <div className="p-4">
        <p className="text-xs uppercase tracking-wide text-stone-500">
          {product.category}
        </p>
        <h3 className="mt-1 font-medium">{product.name}</h3>
        <p className="mt-1 text-sm text-stone-600">${product.price}</p>
      </div>
    </Link>
  );
}
