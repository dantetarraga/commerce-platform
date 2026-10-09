import { expect, test } from '@playwright/test'
import { mockAdminApi } from './admin-fixture'

test('protege los módulos admin de visitantes y negocios', async ({ page }) => {
  await page.goto('/admin/catalog')
  await expect(page).toHaveURL(/\/login/)
  await mockAdminApi(page, { role: 'MERCHANT' })
  await page.goto('/admin/partners')
  await expect(page).toHaveURL(/\/partner$/)
  await expect(page.getByRole('heading', { name: 'Socios', exact: true })).toHaveCount(0)
})

test('busca por celular y suspende solo el rol elegido', async ({ page }) => {
  const api = await mockAdminApi(page)
  await page.goto('/admin/partners')
  await page.getByLabel('Buscar por celular').fill('987 654 321')
  await page.getByRole('button', { name: 'Buscar', exact: true }).click()
  await expect(page.getByRole('heading', { name: 'Ana Quispe' })).toBeVisible()
  await page.getByRole('button', { name: 'Suspender socio' }).click()
  await page.getByRole('checkbox', { name: 'Negocio', exact: true }).uncheck()
  await page.getByRole('button', { name: 'Confirmar suspensión' }).click()
  await expect(page.getByRole('dialog')).toHaveCount(0)
  await expect(page.getByRole('button', { name: 'Dar acceso de repartidor' })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Asignar negocios' })).toBeVisible()
  expect(api.writes[0].body).toEqual({ roles: ['COURIER'] })
  expect(api.unexpected).toEqual([])
})

test('conserva la confirmación si el repartidor tiene un pedido activo', async ({ page }) => {
  await mockAdminApi(page, { blockedSuspension: true })
  await page.goto('/admin/partners')
  await page.getByLabel('Buscar por celular').fill('987654321')
  await page.getByRole('button', { name: 'Buscar', exact: true }).click()
  await page.getByRole('button', { name: 'Suspender socio' }).click()
  await page.getByRole('button', { name: 'Confirmar suspensión' }).click()
  await expect(page.getByRole('dialog').getByRole('alert')).toContainText(
    'tiene un pedido en curso',
  )
  await expect(page.getByRole('button', { name: 'Confirmar suspensión' })).toBeEnabled()
})

test('crea un socio, valida los campos y permite asignar un único negocio', async ({ page }) => {
  const api = await mockAdminApi(page)
  await page.goto('/admin/partners')
  await page.getByRole('button', { name: 'Nuevo socio de negocio' }).click()
  await page.getByRole('button', { name: 'Guardar socio' }).click()
  await expect(page.getByText('Ingresa un celular de 9 dígitos que empiece con 9.')).toBeVisible()
  expect(api.writes).toHaveLength(0)
  const dialog = page.getByRole('dialog')
  await dialog.getByLabel('Celular', { exact: true }).fill('912345678')
  await dialog.getByLabel('Nombre', { exact: true }).fill('Rosa')
  await dialog.getByLabel('Apellido', { exact: true }).fill('Mamani')
  await dialog.getByRole('checkbox', { name: 'Sabores de Espinar' }).check()
  await expect(dialog.getByText(/Su dueño anterior perderá el acceso/)).toBeVisible()
  await dialog.getByRole('button', { name: 'Guardar socio' }).click()
  await expect(page.getByRole('heading', { name: 'Rosa Mamani' })).toBeVisible()
  expect(api.writes[0].body).toEqual({
    phone: '912345678',
    firstName: 'Rosa',
    lastName: 'Mamani',
    storeIds: ['store-1'],
  })
  expect(api.unexpected).toEqual([])
})

test('crea un negocio como borrador seleccionando el dueño por celular', async ({ page }) => {
  const api = await mockAdminApi(page)
  await page.goto('/admin/catalog')
  await page.getByRole('button', { name: 'Nuevo negocio', exact: true }).click()
  const dialog = page.getByRole('dialog')
  await dialog.getByLabel('Celular del dueño').fill('987654321')
  await dialog.getByRole('button', { name: 'Buscar dueño' }).click()
  await dialog.getByRole('button', { name: 'Seleccionar como dueño' }).click()
  await dialog.getByLabel('Nombre del negocio').fill('Café de la plaza')
  await dialog.getByLabel('Ciudad', { exact: true }).selectOption('espinar')
  await dialog.getByLabel('Dirección del local').fill('Plaza 456')
  await dialog.getByLabel('Latitud').fill('-14.8')
  await dialog.getByLabel('Longitud').fill('-71.4')
  await dialog.getByLabel('Pedido mínimo (S/)').fill('15,50')
  await dialog.getByRole('checkbox', { name: 'Comida' }).check()
  await dialog.getByRole('button', { name: 'Guardar negocio' }).click()
  await expect(page.getByRole('heading', { name: 'Café de la plaza' })).toBeVisible()
  expect(api.writes[0].body).toMatchObject({
    ownerId: 'owner-1',
    cityId: 'espinar',
    isActive: false,
    minOrderAmount: { amount: 1550, currency: 'PEN' },
    categoryIds: ['category-1'],
  })
  expect(api.unexpected).toEqual([])
})

test('edita un producto sin perder sus opciones y refresca la carta', async ({ page }) => {
  const api = await mockAdminApi(page)
  await page.goto('/admin/catalog/store-1')
  await expect(
    page
      .getByRole('navigation', { name: 'Administración' })
      .getByRole('link', { name: 'Catálogo' }),
  ).toHaveAttribute('aria-current', 'page')
  await page.getByRole('button', { name: 'Editar producto Sopa de quinua' }).click()
  const dialog = page.getByRole('dialog')
  await expect(dialog.getByText('Picante: Ají')).toBeVisible()
  await dialog.getByLabel('Precio base (S/)').fill('16.50')
  await dialog.getByLabel('Stock (opcional)').fill('0')
  await dialog.getByRole('button', { name: 'Guardar producto' }).click()
  await expect(page.getByRole('dialog')).toHaveCount(0)
  await expect(page.getByText('Agotado', { exact: true })).toBeVisible()
  expect(api.writes[0].body).toMatchObject({
    stock: 0,
    basePrice: { amount: 1650, currency: 'PEN' },
  })
  expect(api.writes[0].body).not.toHaveProperty('options')
  expect(api.writes[0].body).not.toHaveProperty('variants')
  await page.getByRole('button', { name: 'Editar producto Sopa de quinua' }).click()
  await expect(page.getByText('Picante: Ají')).toBeVisible()
  expect(api.unexpected).toEqual([])
})

test('guarda horarios nocturnos y publica con confirmación', async ({ page }) => {
  const api = await mockAdminApi(page)
  await page.goto('/admin/catalog/store-1')
  await page.getByRole('button', { name: 'Editar horarios' }).click()
  await expect(page.getByLabel('Cierre 1')).toHaveValue('24:00')
  await page.getByLabel('Apertura 1').fill('22:00')
  await page.getByLabel('Cierre 1').fill('02:30')
  await page.getByRole('button', { name: 'Guardar horarios' }).click()
  await expect(page.getByText('22:00 – 02:30 (+1 día)')).toBeVisible()
  expect(api.writes[0].body).toEqual({
    schedules: [{ dayOfWeek: 1, opensAt: 1320, closesAt: 150 }],
  })
  await page.getByRole('button', { name: 'Publicar negocio', exact: true }).click()
  expect(api.writes).toHaveLength(1)
  await page.getByRole('button', { name: 'Publicar', exact: true }).click()
  await expect(page.getByText('Publicado', { exact: true })).toBeVisible()
  expect(api.writes[1].body).toEqual({ isActive: true })
  expect(api.unexpected).toEqual([])
})

test('edita el negocio sin reenviar la ciudad ni borrar sus categorías', async ({ page }) => {
  const api = await mockAdminApi(page)
  await page.goto('/admin/catalog/store-1')
  await page.getByRole('button', { name: 'Editar negocio' }).click()
  await page.getByLabel('Nombre del negocio').fill('Sabores nuevos')
  await page.getByRole('button', { name: 'Guardar negocio' }).click()
  await expect(page.getByRole('heading', { name: 'Sabores nuevos' })).toBeVisible()
  expect(api.writes[0].body).not.toHaveProperty('cityId')
  expect(api.writes[0].body.categoryIds).toEqual(['category-1'])
  expect(api.unexpected).toEqual([])
})

test('muestra errores de red con reintento y distingue un celular no registrado', async ({
  page,
}) => {
  await mockAdminApi(page)
  await page.route('**/api/v1/admin/users?**', (route) =>
    route.fulfill({
      status: 503,
      json: { code: 'SERVICE_UNAVAILABLE', message: 'Servicio temporalmente no disponible.' },
    }),
  )
  await page.goto('/admin/partners')
  await page.getByLabel('Buscar por celular').fill('900000000')
  await page.getByRole('button', { name: 'Buscar', exact: true }).click()
  // Un 5xx no muestra el mensaje técnico del backend, solo el estado y el código de soporte.
  await expect(page.getByRole('alert')).toContainText('Tuvimos un problema de nuestro lado')
  await expect(page.getByRole('alert')).toContainText('Error 503')
  await page.unroute('**/api/v1/admin/users?**')
  await page.getByRole('button', { name: 'Reintentar' }).click()
  await expect(page.getByRole('heading', { name: 'No encontramos ese celular' })).toBeVisible()
})

test('los módulos y formularios caben en móvil y soportan modo oscuro', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockAdminApi(page)
  await page.goto('/admin/catalog')
  await expect(page.getByRole('heading', { name: 'Catálogo', exact: true })).toBeVisible()
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(
    true,
  )
  await page.getByRole('button', { name: 'Nuevo negocio', exact: true }).click()
  await expect(page.getByRole('dialog')).toBeVisible()
  const bounds = await page.getByRole('dialog').boundingBox()
  expect(bounds?.x).toBeGreaterThanOrEqual(0)
  expect((bounds?.x ?? 0) + (bounds?.width ?? 0)).toBeLessThanOrEqual(390)
  await page.screenshot({
    path: 'test-results/catalog-mobile.png',
    fullPage: true,
    animations: 'disabled',
  })
  await page.getByRole('button', { name: 'Cerrar', exact: true }).click()
  await page.getByRole('button', { name: 'Cambiar a modo oscuro' }).click()
  await expect(page.locator('html')).toHaveClass('dark')
  await expect(page.getByRole('link', { name: 'Gestionar Sabores de Espinar' })).toBeVisible()
  await page.screenshot({
    path: 'test-results/catalog-dark.png',
    fullPage: true,
    animations: 'disabled',
  })
})
