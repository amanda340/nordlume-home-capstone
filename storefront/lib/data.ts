import productsData from "@/data/products.json";
import storesData from "@/data/stores.json";
import inventoryData from "@/data/inventory.json";

export type Product = {
  sku: string;
  name: string;
  category: string;
  price: number;
  dimensions: string;
  description: string;
  style: string;
  image: string;
};

export type Store = {
  storeId: string;
  name: string;
  address: string;
  hours: string;
  phone: string;
};

export type InventoryRow = {
  sku: string;
  storeId: string;
  quantity: number;
};

export type StockStatus = "IN_STOCK" | "LOW_STOCK" | "OUT_OF_STOCK";

export const products = productsData as Product[];
export const stores = storesData as Store[];
export const inventory = inventoryData as InventoryRow[];

export function getProduct(sku: string): Product | undefined {
  return products.find((p) => p.sku === sku);
}

export function getCategories(): string[] {
  return Array.from(new Set(products.map((p) => p.category))).sort();
}

export function getRelatedProducts(product: Product, limit = 4): Product[] {
  return products
    .filter((p) => p.category === product.category && p.sku !== product.sku)
    .slice(0, limit);
}

export function stockStatus(quantity: number): StockStatus {
  if (quantity <= 0) return "OUT_OF_STOCK";
  if (quantity <= 3) return "LOW_STOCK";
  return "IN_STOCK";
}

export function getAvailabilityForProduct(
  sku: string
): { store: Store; quantity: number; status: StockStatus }[] {
  return inventory
    .filter((row) => row.sku === sku)
    .map((row) => {
      const store = stores.find((s) => s.storeId === row.storeId)!;
      return { store, quantity: row.quantity, status: stockStatus(row.quantity) };
    })
    .filter((row) => row.store);
}

export function getAvailabilityForStore(
  storeId: string
): { product: Product; quantity: number; status: StockStatus }[] {
  return inventory
    .filter((row) => row.storeId === storeId)
    .map((row) => {
      const product = products.find((p) => p.sku === row.sku)!;
      return { product, quantity: row.quantity, status: stockStatus(row.quantity) };
    })
    .filter((row) => row.product);
}
