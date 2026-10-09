const products = [
  { sku: 'SKU-1001', name: 'Premium Coffee Beans', category: 'Beverages', stock: '128', unit: 'bags', status: 'In stock' },
  { sku: 'SKU-1002', name: 'Paper Cups 12oz', category: 'Packaging', stock: '42', unit: 'boxes', status: 'Low stock' },
  { sku: 'SKU-1003', name: 'Whole Milk 1L', category: 'Dairy', stock: '86', unit: 'cartons', status: 'In stock' },
  { sku: 'SKU-1004', name: 'Vanilla Syrup', category: 'Beverages', stock: '9', unit: 'bottles', status: 'Low stock' },
]

const navigation = [
  { icon: '▦', label: 'Dashboard', active: true },
  { icon: '▤', label: 'Inventory' },
  { icon: '⇄', label: 'Purchasing' },
  { icon: '♧', label: 'Sales' },
  { icon: '▧', label: 'Customers' },
  { icon: '▣', label: 'Reports' },
]

function App() {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-900">
      <aside className="fixed inset-y-0 left-0 z-20 hidden w-64 flex-col border-r border-slate-200 bg-white lg:flex">
        <a href="#" className="flex h-16 items-center gap-3 border-b border-slate-200 px-6">
          <span className="grid size-9 place-items-center rounded-lg bg-indigo-600 text-lg font-bold text-white">R</span>
          <span className="text-base font-semibold tracking-tight">Retail ERP</span>
        </a>
        <div className="px-4 pt-6">
          <p className="mb-3 px-3 text-xs font-semibold uppercase tracking-wider text-slate-400">Workspace</p>
          <nav aria-label="Main navigation" className="space-y-1">
            {navigation.map((item) => (
              <a
                key={item.label}
                href="#"
                aria-current={item.active ? 'page' : undefined}
                className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium ${
                  item.active ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                }`}
              >
                <span aria-hidden="true" className="w-5 text-center text-base">{item.icon}</span>
                {item.label}
              </a>
            ))}
          </nav>
        </div>
        <div className="mt-auto border-t border-slate-200 p-4">
          <div className="flex items-center gap-3 rounded-lg p-2">
            <div className="grid size-9 place-items-center rounded-full bg-slate-100 text-sm font-semibold text-slate-600">JD</div>
            <div className="min-w-0">
              <p className="truncate text-sm font-medium">Jamie Davis</p>
              <p className="truncate text-xs text-slate-500">Store manager</p>
            </div>
          </div>
        </div>
      </aside>

      <main className="lg:pl-64">
        <header className="sticky top-0 z-10 flex h-16 items-center justify-between border-b border-slate-200 bg-white/95 px-4 backdrop-blur sm:px-8">
          <div>
            <p className="text-xs text-slate-500">Workspace / Overview</p>
            <h1 className="text-sm font-semibold">Dashboard</h1>
          </div>
          <div className="flex items-center gap-3">
            <span className="hidden text-sm text-slate-500 sm:inline">Main Warehouse</span>
            <button type="button" aria-label="Notifications" className="grid size-9 place-items-center rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-50">♧</button>
          </div>
        </header>

        <div className="mx-auto max-w-7xl space-y-6 p-4 sm:p-8">
          <section className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
            <div>
              <h2 className="text-2xl font-semibold tracking-tight">Good morning, Jamie</h2>
              <p className="mt-1 text-sm text-slate-500">Here&apos;s what&apos;s happening with your store today.</p>
            </div>
            <button type="button" className="inline-flex items-center justify-center rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm hover:bg-indigo-700">
              + New transaction
            </button>
          </section>

          <section aria-label="Business summary" className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <SummaryCard label="Today's sales" value="₱24,580.00" note="+12.8% from yesterday" />
            <SummaryCard label="Open purchase orders" value="8" note="3 awaiting receipt" />
            <SummaryCard label="Inventory items" value="1,284" note="Across 2 warehouses" />
            <SummaryCard label="Low stock alerts" value="12" note="Requires attention" alert />
          </section>

          <section className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
            <div className="flex flex-col gap-3 border-b border-slate-200 p-5 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <h3 className="font-semibold">Inventory overview</h3>
                <p className="mt-1 text-sm text-slate-500">A quick look at your most recent stock levels.</p>
              </div>
              <label className="relative">
                <span className="sr-only">Search inventory</span>
                <input
                  type="search"
                  placeholder="Search products..."
                  className="w-full rounded-lg border border-slate-300 bg-white py-2 pl-3 pr-3 text-sm outline-none placeholder:text-slate-400 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 sm:w-64"
                />
              </label>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full min-w-[620px] text-left text-sm">
                <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
                  <tr>
                    <th scope="col" className="px-5 py-3 font-medium">Product</th>
                    <th scope="col" className="px-5 py-3 font-medium">Category</th>
                    <th scope="col" className="px-5 py-3 text-right font-medium">On hand</th>
                    <th scope="col" className="px-5 py-3 font-medium">Status</th>
                    <th scope="col" className="px-5 py-3"><span className="sr-only">Actions</span></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {products.map((product) => (
                    <tr key={product.sku} className="hover:bg-slate-50/70">
                      <td className="px-5 py-4">
                        <p className="font-medium text-slate-800">{product.name}</p>
                        <p className="mt-0.5 text-xs text-slate-500">{product.sku}</p>
                      </td>
                      <td className="px-5 py-4 text-slate-600">{product.category}</td>
                      <td className="px-5 py-4 text-right font-medium tabular-nums">
                        {product.stock} <span className="font-normal text-slate-500">{product.unit}</span>
                      </td>
                      <td className="px-5 py-4">
                        <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-medium ${
                          product.status === 'Low stock' ? 'bg-amber-50 text-amber-700' : 'bg-emerald-50 text-emerald-700'
                        }`}>
                          {product.status}
                        </span>
                      </td>
                      <td className="px-5 py-4 text-right text-slate-400">···</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="flex items-center justify-between border-t border-slate-200 px-5 py-3 text-sm">
              <p className="text-slate-500">Showing 4 of 1,284 products</p>
              <a href="#" className="font-medium text-indigo-600 hover:text-indigo-700">View inventory →</a>
            </div>
          </section>
        </div>
      </main>
    </div>
  )
}

function SummaryCard({ label, value, note, alert = false }) {
  return (
    <article className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
      <p className="text-sm font-medium text-slate-500">{label}</p>
      <p className={`mt-3 text-2xl font-semibold tracking-tight ${alert ? 'text-amber-600' : 'text-slate-900'}`}>{value}</p>
      <p className={`mt-2 text-xs ${alert ? 'text-amber-700' : 'text-slate-500'}`}>{note}</p>
    </article>
  )
}

export default App
