import type { Page } from '@playwright/test'

const initialAccount = {
  id: 'owner-1',
  phone: '987654321',
  firstName: 'Ana',
  lastName: 'Quispe',
  isActive: true,
  roles: ['CUSTOMER', 'MERCHANT', 'COURIER'],
  stores: [{ id: 'store-1', name: 'Sabores de Espinar', isAcceptingOrders: true }],
  courier: {
    cityId: 'espinar',
    vehicleType: 'MOTO',
    vehicleLabel: 'Moto roja',
    plate: 'ABC-123',
    status: 'OFFLINE',
  },
}
const initialStore = {
  id: 'store-1',
  cityId: 'espinar',
  ownerId: 'owner-1',
  name: 'Sabores de Espinar',
  addressLine: 'Plaza de Armas 123',
  latitude: -14.79,
  longitude: -71.41,
  description: null,
  phone: null,
  logoUrl: null,
  coverUrl: null,
  minOrderAmount: { amount: 1000, currency: 'PEN' },
  avgPrepMinutes: 20,
  categoryIds: ['category-1'],
  isActive: false,
  isAcceptingOrders: true,
  schedules: [{ dayOfWeek: 1, opensAt: 540, closesAt: 1440 }],
  sections: [{ id: 'section-1', name: 'Platos', sortOrder: 0 }],
  products: [
    {
      id: 'product-1',
      name: 'Sopa de quinua',
      description: null,
      imageUrl: null,
      basePrice: { amount: 1250, currency: 'PEN' },
      menuSectionId: 'section-1',
      stock: null,
      sortOrder: 0,
      isAvailable: true,
      isFeatured: false,
      isLocal: true,
      variants: [],
      options: [
        {
          id: 'option-1',
          name: 'Picante',
          minSelect: 0,
          maxSelect: 1,
          values: [
            {
              id: 'value-1',
              name: 'Ají',
              priceDelta: { amount: 0, currency: 'PEN' },
              isAvailable: true,
            },
          ],
        },
      ],
    },
  ],
}

export async function mockAdminApi(
  page: Page,
  options: { role?: 'ADMIN' | 'MERCHANT'; blockedSuspension?: boolean } = {},
) {
  let account = structuredClone(initialAccount)
  let store = structuredClone(initialStore)
  const writes: { path: string; method: string; body: Record<string, unknown> }[] = []
  const unexpected: string[] = []
  await page.addInitScript(() =>
    localStorage.setItem(
      'apamuy.panel.session',
      JSON.stringify({ state: { refreshToken: 'test-refresh' }, version: 1 }),
    ),
  )
  await page.route('**/api/v1/**', async (route) => {
    const request = route.request()
    const url = new URL(request.url())
    const path = url.pathname.replace(/^\/api\/v1/, '')
    const method = request.method()
    const body = (request.postDataJSON() ?? {}) as Record<string, unknown>
    const reply = (json: unknown, status = 200) => route.fulfill({ status, json })
    if (path === '/auth/refresh') {
      return reply({ accessToken: 'test-access', refreshToken: 'test-refresh' })
    }
    if (path === '/users/me') {
      return reply({
        id: 'admin-1',
        phone: '999999999',
        firstName: 'Equipo',
        lastName: 'Apamuy',
        email: null,
        avatarUrl: null,
        roles: [options.role ?? 'ADMIN'],
      })
    }
    if (method === 'GET') {
      if (path === '/cities') {
        return reply([
          { id: 'espinar', name: 'Espinar', currency: 'PEN', centerLat: -14.79, centerLng: -71.41 },
        ])
      }
      if (path === '/categories') {
        return reply([{ id: 'category-1', name: 'Comida', slug: 'comida', iconUrl: null }])
      }
      if (path === '/admin/users') {
        return url.searchParams.get('phone') === account.phone
          ? reply(account)
          : reply({ code: 'NOT_FOUND', message: 'No hay ninguna cuenta con ese celular.' }, 404)
      }
      if (path === '/admin/stores') {
        return reply([
          {
            id: store.id,
            cityId: store.cityId,
            ownerId: store.ownerId,
            name: store.name,
            isActive: store.isActive,
            isAcceptingOrders: store.isAcceptingOrders,
            productCount: store.products.length,
          },
        ])
      }
      if (path === `/admin/stores/${store.id}`) return reply(store)
    }
    if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(method)) {
      writes.push({ path, method, body })
      if (path === '/admin/merchants' || path === '/admin/couriers') {
        account = {
          ...account,
          phone: String(body.phone),
          firstName: String(body.firstName),
          lastName: String(body.lastName),
        }
        return reply({ created: true, user: account }, 201)
      }
      if (path === `/admin/users/${account.id}/suspend-partner`) {
        if (options.blockedSuspension) {
          return reply(
            {
              code: 'COURIER_HAS_ACTIVE_ORDER',
              message: 'El repartidor tiene un pedido en curso. Resuélvelo antes de suspenderlo.',
            },
            409,
          )
        }
        account = {
          ...account,
          roles: account.roles.filter((role) => !(body.roles as string[]).includes(role)),
        }
        return reply(account)
      }
      if (path === '/admin/stores' && method === 'POST') {
        store = {
          ...store,
          ...body,
          id: 'store-new',
          products: [],
          schedules: [],
          sections: [],
        } as typeof store
        return reply(store, 201)
      }
      if (path === `/admin/stores/${store.id}` && method === 'PATCH') {
        store = { ...store, ...body } as typeof store
        return reply(store)
      }
      if (path === `/admin/stores/${store.id}/schedules`) {
        store.schedules = body.schedules as typeof store.schedules
        return reply(store)
      }
      if (path === '/admin/products/product-1') {
        store.products[0] = { ...store.products[0], ...body } as (typeof store.products)[0]
        return reply(store.products[0])
      }
    }
    unexpected.push(`${method} ${path}`)
    return reply(
      { code: 'UNEXPECTED_TEST_REQUEST', message: `Petición no prevista: ${method} ${path}` },
      500,
    )
  })
  return { writes, unexpected }
}
