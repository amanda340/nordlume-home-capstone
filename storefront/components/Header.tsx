import Link from "next/link";

const NAV_LINKS = [
  { href: "/", label: "Home" },
  { href: "/catalog", label: "Catálogo" },
  { href: "/stores", label: "Lojas" },
];

export default function Header() {
  return (
    <header className="border-b border-black/10 bg-[var(--background)]">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <Link href="/" className="text-lg font-semibold tracking-tight">
          Nordlume <span className="font-normal text-stone-500">Home</span>
        </Link>
        <nav className="flex gap-6 text-sm">
          {NAV_LINKS.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className="text-stone-700 transition hover:text-stone-950"
            >
              {link.label}
            </Link>
          ))}
        </nav>
      </div>
    </header>
  );
}
