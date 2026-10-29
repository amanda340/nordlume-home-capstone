import type { Store } from "@/lib/data";

export default function StoreCard({ store }: { store: Store }) {
  return (
    <div className="rounded-lg border border-black/10 bg-white p-5">
      <h3 className="font-medium">{store.name}</h3>
      <p className="mt-2 text-sm text-stone-600">{store.address}</p>
      <p className="mt-1 text-sm text-stone-600">{store.hours}</p>
      <p className="mt-1 text-sm text-stone-600">{store.phone}</p>
    </div>
  );
}
