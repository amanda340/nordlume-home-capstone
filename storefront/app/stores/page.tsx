import StoreCard from "@/components/StoreCard";
import { stores } from "@/lib/data";

export default function StoresPage() {
  return (
    <div className="mx-auto max-w-6xl px-6 py-12">
      <h1 className="text-2xl font-semibold">Nossas lojas</h1>
      <p className="mt-2 text-stone-600">
        Encontre a unidade Nordlume Home mais próxima de você.
      </p>
      <div className="mt-8 grid gap-5 sm:grid-cols-2">
        {stores.map((store) => (
          <StoreCard key={store.storeId} store={store} />
        ))}
      </div>
    </div>
  );
}
