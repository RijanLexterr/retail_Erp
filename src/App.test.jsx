import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it } from 'vitest'
import App from './App.jsx'

describe('dashboard', () => {
  it('renders the inventory overview and product rows', () => {
    const markup = renderToStaticMarkup(<App />)

    expect(markup).toContain('Inventory overview')
    expect(markup).toContain('SKU-1001')
    expect(markup).toContain('Premium Coffee Beans')
    expect(markup).toContain('Low stock')
  })
})
